import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { getFirebaseAuth } from '../firebase-admin';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(private prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException(
        'Missing or invalid authorization header',
      );
    }

    const token = authHeader.split('Bearer ')[1];

    try {
      const decodedToken = await getFirebaseAuth().verifyIdToken(token);

      // Find user by firebaseUid first, then by email
      let user = await this.prisma.user.findUnique({
        where: { firebaseUid: decodedToken.uid },
      });

      // If not found by firebaseUid, try to find by email (for admin users)
      if (!user && decodedToken.email) {
        user = await this.prisma.user.findUnique({
          where: { email: decodedToken.email },
        });
        // If found by email, update firebaseUid
        if (user) {
          user = await this.prisma.user.update({
            where: { id: user.id },
            data: { firebaseUid: decodedToken.uid },
          });
        }
      }

      if (!user) {
        // Create user if first time - generate a placeholder phone if not provided
        const placeholderPhone =
          decodedToken.phone_number ||
          `admin_${decodedToken.uid.substring(0, 10)}`;
        user = await this.prisma.user.create({
          data: {
            firebaseUid: decodedToken.uid,
            phoneNumber: placeholderPhone,
            email: decodedToken.email,
            displayName: decodedToken.name || decodedToken.email?.split('@')[0],
            photoUrl: decodedToken.picture,
          },
        });
      }

      // Update last active
      await this.prisma.user.update({
        where: { id: user.id },
        data: { lastActiveAt: new Date() },
      });

      // Attach user to request
      request.user = user;
      request.firebaseUser = decodedToken;

      return true;
    } catch (_error) {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}
