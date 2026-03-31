import type { Metadata } from 'next';
import ExploreClient from '@/components/home/ExploreClient';

export const metadata: Metadata = {
  title: 'Browse Clothes',
  description:
    'Browse thousands of affordable second-hand and new clothes in Uganda. Filter by category, price, condition, and location. Find fashion deals in Kampala and beyond on Tekka.',
  alternates: {
    canonical: 'https://tekka.ug/explore',
  },
};

export default function ExplorePage() {
  return <ExploreClient />;
}
