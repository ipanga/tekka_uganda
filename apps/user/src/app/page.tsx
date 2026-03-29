import type { Metadata } from 'next';
import HomeClient from '@/components/home/HomeClient';

export const metadata: Metadata = {
  title: 'Tekka - Buy & Sell Second-Hand Clothes in Uganda',
  description:
    'Tekka is Uganda\'s leading marketplace for buying and selling second-hand and new clothes. Find affordable fashion, sell your pre-loved items, and shop locally in Kampala and across Uganda.',
  alternates: {
    canonical: 'https://tekka.ug',
  },
};

export default function HomePage() {
  return <HomeClient />;
}
