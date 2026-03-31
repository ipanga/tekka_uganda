import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Contact Us',
  description:
    'Need help with Tekka? Contact our support team for buyer issues, seller issues, or general inquiries about Uganda\'s fashion marketplace.',
  alternates: { canonical: 'https://tekka.ug/contact' },
};

export default function ContactLayout({ children }: { children: React.ReactNode }) {
  return children;
}
