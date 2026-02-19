'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

interface FaqItem {
  question: string;
  answer: string;
}

interface FaqSection {
  title: string;
  items: FaqItem[];
}

const faqSections: FaqSection[] = [
  {
    title: 'For Buyers',
    items: [
      {
        question: 'How do I buy an item?',
        answer:
          'Browse listings on the Explore page or search for specific items. When you find something you like, tap "Message Seller" to discuss the item, negotiate the price, and arrange a meetup for the exchange.',
      },
      {
        question: 'How do I contact a seller?',
        answer:
          'Go to the item you\'re interested in and tap "Message Seller". You can ask questions about the item, discuss the price, and arrange a meetup directly through the chat.',
      },
      {
        question: 'How do I leave a review?',
        answer:
          'After a successful transaction, you can leave a review on the seller\'s profile. Go to their profile page and tap "Write a Review". Rate your experience and add a comment to help other buyers.',
      },
      {
        question: 'What if an item is not as described?',
        answer:
          'Always inspect items carefully before completing payment at the meetup. If you have issues with a seller, you can report them through their profile. We take reports seriously and may suspend accounts that violate our policies.',
      },
    ],
  },
  {
    title: 'For Sellers',
    items: [
      {
        question: 'How do I list an item for sale?',
        answer:
          'Click "Sell Now" in the navigation bar. Add photos of your item (up to 10), fill in details like title, description, price, and category, then publish your listing to make it live.',
      },
      {
        question: 'How do drafts work?',
        answer:
          'When creating a listing, you can save it as a draft instead of publishing immediately. Drafts are saved in your "My Listings" page and can be edited and published at any time. This is useful if you want to prepare a listing in advance.',
      },
      {
        question: 'Can I edit or delete my listing?',
        answer:
          'Yes! Go to "My Listings" from your profile menu, find the listing you want to modify, and use the edit or delete options. You can update details, change the price, or remove the listing entirely.',
      },
      {
        question: 'How do reviews work?',
        answer:
          'After a successful transaction, both buyers and sellers can leave reviews for each other. Reviews help build trust in the community. Be honest and fair in your reviews — they help everyone make better decisions.',
      },
    ],
  },
  {
    title: 'General',
    items: [
      {
        question: 'How does payment work?',
        answer:
          'Tekka is a peer-to-peer marketplace. Payment is handled directly between buyers and sellers when you meet up. We recommend using mobile money for secure transactions as it provides a digital record.',
      },
      {
        question: 'How do I arrange a meetup?',
        answer:
          'Once you\'ve agreed on a price, use the chat to suggest a safe meetup location. We recommend public places like shopping malls and cafes. Always meet in public, well-lit locations during daylight hours.',
      },
      {
        question: 'How do I report a suspicious user?',
        answer:
          'Visit the user\'s profile and select "Report User". Choose the reason for reporting and provide any relevant details. Our team reviews all reports within 24 hours and takes appropriate action.',
      },
      {
        question: 'How do I delete my account?',
        answer:
          'Go to Settings in your profile and select "Delete Account". This will permanently remove your account and all associated data. Please note that this action cannot be undone.',
      },
    ],
  },
];

function FaqAccordion({ item, isOpen, onToggle }: { item: FaqItem; isOpen: boolean; onToggle: () => void }) {
  return (
    <div className="border-b border-gray-100 last:border-0">
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between py-4 px-5 text-left hover:bg-gray-50 transition-colors"
      >
        <span className="font-medium text-gray-900 pr-4">{item.question}</span>
        <svg
          className={`w-5 h-5 text-gray-400 flex-shrink-0 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          viewBox="0 0 24 24"
          strokeWidth={2}
          stroke="currentColor"
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5" />
        </svg>
      </button>
      {isOpen && (
        <div className="px-5 pb-4">
          <p className="text-gray-600 text-sm leading-relaxed">{item.answer}</p>
        </div>
      )}
    </div>
  );
}

export default function HelpPage() {
  const [openItems, setOpenItems] = useState<Set<string>>(new Set());

  const toggleItem = (key: string) => {
    setOpenItems((prev) => {
      const next = new Set(prev);
      if (next.has(key)) {
        next.delete(key);
      } else {
        next.add(key);
      }
      return next;
    });
  };

  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      <main className="flex-1 bg-[var(--background)]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Page Header */}
          <div className="mb-10">
            <h1 className="text-3xl font-bold text-gray-900">Help Center</h1>
            <p className="mt-2 text-gray-600">
              Find answers to common questions or get in touch with our support team.
            </p>
          </div>

          {/* Contact Banner */}
          <div className="bg-primary-50 border border-primary-200 rounded-xl p-6 mb-10">
            <h2 className="text-lg font-semibold text-gray-900 mb-2">Need help?</h2>
            <p className="text-gray-600 text-sm mb-4">
              Our support team is here to assist you. Reach out and we&apos;ll get back to you as soon as possible.
            </p>
            <div className="flex flex-wrap gap-3">
              <a
                href="mailto:contact@tekka.ug"
                className="inline-flex items-center gap-2 bg-white border border-primary-200 text-primary-600 rounded-lg px-4 py-2.5 text-sm font-medium hover:bg-primary-50 transition-colors"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
                </svg>
                contact@tekka.ug
              </a>
              <Link
                href="/contact"
                className="inline-flex items-center gap-2 bg-primary-500 text-white rounded-lg px-4 py-2.5 text-sm font-medium hover:bg-primary-600 transition-colors"
              >
                Contact Us
              </Link>
            </div>
          </div>

          {/* FAQ Sections */}
          <div className="space-y-6">
            <h2 className="text-xl font-semibold text-gray-900">Frequently Asked Questions</h2>

            {faqSections.map((section) => (
              <div key={section.title}>
                <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
                  {section.title}
                </h3>
                <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
                  {section.items.map((item) => {
                    const key = `${section.title}-${item.question}`;
                    return (
                      <FaqAccordion
                        key={key}
                        item={item}
                        isOpen={openItems.has(key)}
                        onToggle={() => toggleItem(key)}
                      />
                    );
                  })}
                </div>
              </div>
            ))}
          </div>

          {/* Additional Resources */}
          <div className="mt-10">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Additional Resources</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Link
                href="/safety"
                className="bg-white rounded-xl border border-gray-200 p-5 hover:border-primary-300 transition-colors group"
              >
                <div className="text-2xl mb-2">🛡️</div>
                <h3 className="font-medium text-gray-900 group-hover:text-primary-600">Safety Tips</h3>
                <p className="text-sm text-gray-500 mt-1">Learn how to stay safe while buying and selling</p>
              </Link>
              <Link
                href="/terms"
                className="bg-white rounded-xl border border-gray-200 p-5 hover:border-primary-300 transition-colors group"
              >
                <div className="text-2xl mb-2">📄</div>
                <h3 className="font-medium text-gray-900 group-hover:text-primary-600">Terms of Service</h3>
                <p className="text-sm text-gray-500 mt-1">Read our terms and conditions</p>
              </Link>
              <Link
                href="/privacy"
                className="bg-white rounded-xl border border-gray-200 p-5 hover:border-primary-300 transition-colors group"
              >
                <div className="text-2xl mb-2">🔒</div>
                <h3 className="font-medium text-gray-900 group-hover:text-primary-600">Privacy Policy</h3>
                <p className="text-sm text-gray-500 mt-1">Understand how we handle your data</p>
              </Link>
              <Link
                href="/contact"
                className="bg-white rounded-xl border border-gray-200 p-5 hover:border-primary-300 transition-colors group"
              >
                <div className="text-2xl mb-2">💬</div>
                <h3 className="font-medium text-gray-900 group-hover:text-primary-600">Contact Us</h3>
                <p className="text-sm text-gray-500 mt-1">Get in touch with our support team</p>
              </Link>
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
