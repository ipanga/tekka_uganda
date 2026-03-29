import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Seller Profile',
  description:
    'View seller profile, reviews, and listings on Tekka - Uganda\'s fashion marketplace. Check ratings and browse items for sale.',
};

export default function ProfileLayout({ children }: { children: React.ReactNode }) {
  return children;
}
