import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Sign In to Tekka',
  description:
    'Sign in to Tekka to buy and sell second-hand clothes in Uganda. Access your listings, messages, and saved items.',
  robots: { index: false, follow: true },
};

export default function LoginLayout({ children }: { children: React.ReactNode }) {
  return children;
}
