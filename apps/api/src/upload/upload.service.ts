import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { v2 as cloudinary, UploadApiResponse } from 'cloudinary';

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);

  constructor() {
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
    });
  }

  async uploadImage(
    file: Express.Multer.File,
    folder: string = 'listings',
  ): Promise<string> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Validate file type
    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('File must be an image');
    }

    // Validate file size (max 5MB before compression)
    if (file.size > 5 * 1024 * 1024) {
      throw new BadRequestException('Image must be less than 5MB');
    }

    // Determine quality level based on file size
    // If > 1MB, use more aggressive compression to ensure final size < 1MB
    const qualityLevel = file.size > 1024 * 1024 ? 'auto:low' : 'auto:good';

    return new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder,
          resource_type: 'image',
          transformation: [
            { width: 1200, height: 1200, crop: 'limit' },
            { quality: qualityLevel },
            { fetch_format: 'auto' },
          ],
          // Ensure final file is under 1MB
          eager: [
            {
              width: 1200,
              height: 1200,
              crop: 'limit',
              quality: qualityLevel,
              fetch_format: 'auto',
            },
          ],
        },
        (error, result: UploadApiResponse | undefined) => {
          if (error) {
            this.logger.error(`Cloudinary upload failed: ${error.message}`);
            reject(new BadRequestException('Failed to upload image'));
          } else if (result) {
            this.logger.log(
              `Image uploaded: ${result.public_id} (${result.bytes} bytes)`,
            );
            resolve(result.secure_url);
          } else {
            reject(new BadRequestException('Upload failed'));
          }
        },
      );

      uploadStream.end(file.buffer);
    });
  }

  async uploadMultipleImages(
    files: Express.Multer.File[],
    folder: string = 'listings',
  ): Promise<string[]> {
    if (!files || files.length === 0) {
      throw new BadRequestException('No files provided');
    }

    if (files.length > 10) {
      throw new BadRequestException('Maximum 10 images allowed');
    }

    const uploadPromises = files.map((file) => this.uploadImage(file, folder));
    return Promise.all(uploadPromises);
  }

  /**
   * Delete a single image from Cloudinary by public ID
   */
  async deleteImage(publicId: string): Promise<boolean> {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      const success = result.result === 'ok';
      this.logger.log(
        `Cloudinary delete ${publicId}: ${success ? 'success' : 'not found'}`,
      );
      return success;
    } catch (error) {
      this.logger.error(`Failed to delete image ${publicId}: ${error.message}`);
      return false;
    }
  }

  /**
   * Delete multiple images from Cloudinary by their URLs
   * Extracts public IDs from Cloudinary URLs and deletes them
   */
  async deleteImagesByUrls(imageUrls: string[]): Promise<{
    deleted: number;
    failed: number;
    errors: string[];
  }> {
    const results = { deleted: 0, failed: 0, errors: [] as string[] };

    if (!imageUrls || imageUrls.length === 0) {
      return results;
    }

    const deletePromises = imageUrls.map(async (url) => {
      const publicId = this.extractPublicIdFromUrl(url);
      if (!publicId) {
        results.failed++;
        results.errors.push(`Could not extract public ID from: ${url}`);
        return;
      }

      const success = await this.deleteImage(publicId);
      if (success) {
        results.deleted++;
      } else {
        results.failed++;
        results.errors.push(`Failed to delete: ${publicId}`);
      }
    });

    await Promise.all(deletePromises);

    this.logger.log(
      `Cloudinary bulk delete: ${results.deleted} deleted, ${results.failed} failed`,
    );
    return results;
  }

  /**
   * Extract Cloudinary public ID from a secure URL
   * URL format: https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{folder}/{public_id}.{format}
   */
  extractPublicIdFromUrl(url: string): string | null {
    if (!url || !url.includes('cloudinary.com')) {
      return null;
    }

    try {
      // Remove query params if any
      const cleanUrl = url.split('?')[0];

      // Match pattern: /upload/v{version}/{path}
      const match = cleanUrl.match(/\/upload\/v\d+\/(.+)\.\w+$/);
      if (match && match[1]) {
        return match[1]; // Returns folder/filename without extension
      }

      // Alternative pattern without version: /upload/{path}
      const altMatch = cleanUrl.match(/\/upload\/(.+)\.\w+$/);
      if (altMatch && altMatch[1]) {
        return altMatch[1];
      }

      return null;
    } catch {
      return null;
    }
  }
}
