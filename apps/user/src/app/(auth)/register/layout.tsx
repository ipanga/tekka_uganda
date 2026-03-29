import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Create Your Tekka Account',
  description:
    'Join Tekka, Uganda\'s fashion marketplace. Create an account to start buying and selling second-hand clothes in Kampala and across Uganda.',
  robots: { index: false, follow: true },
};

export default function RegisterLayout({ children }: { children: React.ReactNode }) {
  return children;
}
