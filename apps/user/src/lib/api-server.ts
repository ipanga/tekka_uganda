/**
 * Server-side API client for fetching public data (used in generateMetadata, sitemap, etc.)
 * This runs on the server only — no auth tokens.
 */

import type { Listing, PaginatedResponse, Category } from '@/types';

// Server-side: prefer internal Docker hostname, fall back to public URL, then localhost
const API_URL =
  process.env.API_URL_INTERNAL ||
  process.env.NEXT_PUBLIC_API_URL ||
  'http://localhost:4000/api/v1';

async function serverFetch<T>(endpoint: string): Promise<T | null> {
  try {
    const res = await fetch(`${API_URL}${endpoint}`, {
      next: { revalidate: 300 }, // Cache for 5 minutes
    });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export async function getListingById(id: string): Promise<Listing | null> {
  return serverFetch<Listing>(`/listings/${id}`);
}

export async function getListingBySlug(slug: string): Promise<Listing | null> {
  return serverFetch<Listing>(`/listings/${slug}`);
}

export async function getActiveListings(
  page = 1,
  limit = 100,
): Promise<PaginatedResponse<Listing> | null> {
  // API returns { listings, pagination } — map to PaginatedResponse
  const raw = await serverFetch<{ listings: Listing[]; pagination: { page: number; limit: number; total: number; totalPages: number } }>(
    `/listings?status=ACTIVE&page=${page}&limit=${limit}&sortBy=createdAt&sortOrder=desc`,
  );
  if (!raw) return null;
  return {
    data: raw.listings,
    page: raw.pagination.page,
    limit: raw.pagination.limit,
    total: raw.pagination.total,
    totalPages: raw.pagination.totalPages,
  };
}

export async function getCategories(): Promise<Category[] | null> {
  return serverFetch<Category[]>('/categories');
}
