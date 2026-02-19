'use client';

import { useState } from 'react';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';

const supportCategories = [
  { value: 'general', label: 'General Inquiry' },
  { value: 'buyer', label: 'Buyer Issue' },
  { value: 'seller', label: 'Seller Issue' },
  { value: 'report', label: 'Report Abuse' },
];

export default function ContactPage() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    category: 'general',
    message: '',
  });
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Client-side only — show success message
    setSubmitted(true);
  };

  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      <main className="flex-1 bg-[var(--background)]">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {/* Page Header */}
          <div className="mb-10">
            <h1 className="text-3xl font-bold text-gray-900">Contact Us</h1>
            <p className="mt-2 text-gray-600">
              Have a question or need help? We&apos;d love to hear from you.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* Contact Info */}
            <div className="md:col-span-1 space-y-6">
              {/* Email */}
              <div className="bg-white rounded-xl border border-gray-200 p-5">
                <div className="flex items-center gap-3 mb-2">
                  <div className="w-10 h-10 rounded-lg bg-primary-50 flex items-center justify-center">
                    <svg className="w-5 h-5 text-primary-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
                    </svg>
                  </div>
                  <h3 className="font-medium text-gray-900">Email</h3>
                </div>
                <a
                  href="mailto:contact@tekka.ug"
                  className="text-primary-500 hover:text-primary-600 text-sm"
                >
                  contact@tekka.ug
                </a>
              </div>

              {/* Address */}
              <div className="bg-white rounded-xl border border-gray-200 p-5">
                <div className="flex items-center gap-3 mb-2">
                  <div className="w-10 h-10 rounded-lg bg-primary-50 flex items-center justify-center">
                    <svg className="w-5 h-5 text-primary-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 0115 0z" />
                    </svg>
                  </div>
                  <h3 className="font-medium text-gray-900">Address</h3>
                </div>
                <p className="text-sm text-gray-600">
                  14c, Ggaba Road<br />
                  Bunga, Kampala<br />
                  Uganda
                </p>
              </div>

              {/* Hours */}
              <div className="bg-white rounded-xl border border-gray-200 p-5">
                <div className="flex items-center gap-3 mb-2">
                  <div className="w-10 h-10 rounded-lg bg-primary-50 flex items-center justify-center">
                    <svg className="w-5 h-5 text-primary-500" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <h3 className="font-medium text-gray-900">Support Hours</h3>
                </div>
                <p className="text-sm text-gray-600">
                  Monday &ndash; Friday<br />
                  9:00 AM &ndash; 6:00 PM (EAT)<br />
                  <span className="text-gray-400">We respond within 24 hours</span>
                </p>
              </div>
            </div>

            {/* Contact Form */}
            <div className="md:col-span-2">
              {submitted ? (
                <div className="bg-white rounded-xl border border-gray-200 p-8 text-center">
                  <div className="w-16 h-16 bg-green-50 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg className="w-8 h-8 text-green-500" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                  <h2 className="text-xl font-semibold text-gray-900 mb-2">Message Sent</h2>
                  <p className="text-gray-600 mb-6">
                    Thank you for reaching out! We&apos;ll get back to you within 24 hours at the email address
                    you provided.
                  </p>
                  <button
                    onClick={() => {
                      setSubmitted(false);
                      setFormData({ name: '', email: '', category: 'general', message: '' });
                    }}
                    className="text-primary-500 hover:text-primary-600 text-sm font-medium"
                  >
                    Send another message
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="bg-white rounded-xl border border-gray-200 p-6 space-y-5">
                  <h2 className="text-lg font-semibold text-gray-900">Send us a message</h2>

                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
                      Your Name
                    </label>
                    <input
                      id="name"
                      type="text"
                      required
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent placeholder-gray-400"
                      placeholder="Enter your name"
                    />
                  </div>

                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                      Email Address
                    </label>
                    <input
                      id="email"
                      type="email"
                      required
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent placeholder-gray-400"
                      placeholder="you@example.com"
                    />
                  </div>

                  <div>
                    <label htmlFor="category" className="block text-sm font-medium text-gray-700 mb-1">
                      Category
                    </label>
                    <select
                      id="category"
                      value={formData.category}
                      onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                      className="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent bg-white"
                    >
                      {supportCategories.map((cat) => (
                        <option key={cat.value} value={cat.value}>
                          {cat.label}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-1">
                      Message
                    </label>
                    <textarea
                      id="message"
                      required
                      rows={5}
                      value={formData.message}
                      onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                      className="w-full px-3 py-2.5 border border-gray-300 rounded-lg text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent placeholder-gray-400 resize-none"
                      placeholder="Tell us how we can help..."
                    />
                  </div>

                  <button
                    type="submit"
                    className="w-full bg-primary-500 text-white py-2.5 rounded-lg text-sm font-medium hover:bg-primary-600 transition-colors"
                  >
                    Send Message
                  </button>
                </form>
              )}
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  );
}
