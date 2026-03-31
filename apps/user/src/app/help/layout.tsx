import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Help Centre & FAQ',
  description:
    'Get answers to frequently asked questions about buying and selling clothes on Tekka. Learn how to list items, make purchases, and stay safe on Uganda\'s fashion marketplace.',
  alternates: { canonical: 'https://tekka.ug/help' },
};

export default function HelpLayout({ children }: { children: React.ReactNode }) {
  return children;
}
