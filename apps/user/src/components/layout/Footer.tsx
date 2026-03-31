import Link from 'next/link';
import { Logo } from '@/components/ui/Logo';

export function Footer() {
  return (
    <footer className="bg-gray-900 text-gray-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="col-span-1">
            <Link href="/">
              <Logo variant="light" height={28} />
            </Link>
            <p className="mt-4 text-sm">
              Uganda&apos;s premier marketplace for pre-loved fashion. Buy and sell with confidence.
            </p>
          </div>

          {/* Tekka */}
          <div>
            <h3 className="text-white font-semibold mb-4">Tekka</h3>
            <ul className="space-y-2 text-sm">
              <li><Link href="/about" className="hover:text-primary-300">About Us</Link></li>
              <li><Link href="/how-to-sell" className="hover:text-primary-300">How to Sell</Link></li>
              <li><Link href="/buy-second-hand-clothes" className="hover:text-primary-300">How to Buy</Link></li>
              <li><Link href="/explore" className="hover:text-primary-300">Browse Clothes</Link></li>
              <li><Link href="/sell" className="hover:text-primary-300">Sell Your Clothes</Link></li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="text-white font-semibold mb-4">Support</h3>
            <ul className="space-y-2 text-sm">
              <li><Link href="/help" className="hover:text-primary-300">Help Centre</Link></li>
              <li><Link href="/safety" className="hover:text-primary-300">Safety Tips</Link></li>
              <li><Link href="/contact" className="hover:text-primary-300">Contact Us</Link></li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h3 className="text-white font-semibold mb-4">Legal</h3>
            <ul className="space-y-2 text-sm">
              <li><Link href="/terms" className="hover:text-primary-300">Terms of Service</Link></li>
              <li><Link href="/privacy" className="hover:text-primary-300">Privacy Policy</Link></li>
              <li><Link href="/cookies" className="hover:text-primary-300">Cookie Policy</Link></li>
            </ul>
          </div>
        </div>

        <div className="mt-12 pt-8 border-t border-gray-800 flex flex-col md:flex-row justify-between items-center">
          <p className="text-sm">&copy; {new Date().getFullYear()} Tekka.ug. All rights reserved.</p>
          <div className="flex space-x-6 mt-4 md:mt-0">
            <a href="#" className="hover:text-primary-300">Instagram</a>
            <a href="#" className="hover:text-primary-300">Twitter</a>
            <a href="#" className="hover:text-primary-300">Facebook</a>
          </div>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
