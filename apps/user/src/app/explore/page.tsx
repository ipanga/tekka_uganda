import type { Metadata } from 'next';
import ExploreClient from '@/components/home/ExploreClient';

export const metadata: Metadata = {
  title: 'Explore Second-Hand Clothes in Uganda',
  description:
    'Browse thousands of affordable second-hand and new clothes in Uganda. Filter by category, price, condition, and location. Find fashion deals in Kampala and beyond.',
  alternates: {
    canonical: 'https://tekka.ug/explore',
  },
};

export default function ExplorePage() {
  return <ExploreClient />;
}
