import Link from 'next/link';
import { Logo } from '@/components/ui/Logo';

// Single-color brand glyphs from simple-icons (24×24 viewBox). currentColor
// inherits the footer text colour so monochrome hover stays consistent.
const SOCIALS = [
  {
    name: 'Facebook',
    href: 'https://www.facebook.com/tekkauganda',
    path: 'M9.101 23.691v-7.98H6.627v-3.667h2.474v-1.58c0-4.085 1.848-5.978 5.858-5.978.401 0 .955.042 1.468.103a8.68 8.68 0 0 1 1.141.195v3.325a8.623 8.623 0 0 0-.653-.036 26.805 26.805 0 0 0-.733-.009c-.707 0-1.259.096-1.675.309a1.686 1.686 0 0 0-.679.622c-.258.42-.374.995-.374 1.752v1.297h3.919l-.386 2.103-.287 1.564h-3.246v8.245C19.396 23.238 24 18.179 24 12.044c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.628 3.874 10.35 9.101 11.647Z',
  },
  {
    name: 'Instagram',
    href: 'https://www.instagram.com/tekkauganda',
    path: 'M12 0C8.74 0 8.333.015 7.053.072 5.775.132 4.905.333 4.14.63c-.789.306-1.459.717-2.126 1.384S.935 3.35.63 4.14C.333 4.905.131 5.775.072 7.053.012 8.333 0 8.74 0 12s.015 3.667.072 4.947c.06 1.277.261 2.148.558 2.913.306.788.717 1.459 1.384 2.126.667.666 1.336 1.079 2.126 1.384.766.296 1.636.499 2.913.558C8.333 23.988 8.74 24 12 24s3.667-.015 4.947-.072c1.277-.06 2.148-.262 2.913-.558.788-.306 1.459-.718 2.126-1.384.666-.667 1.079-1.335 1.384-2.126.296-.765.499-1.636.558-2.913.06-1.28.072-1.687.072-4.947s-.015-3.667-.072-4.947c-.06-1.277-.262-2.149-.558-2.913-.306-.789-.718-1.459-1.384-2.126C21.319 1.347 20.651.935 19.86.63c-.765-.297-1.636-.499-2.913-.558C15.667.012 15.26 0 12 0zm0 2.16c3.203 0 3.585.016 4.85.071 1.17.055 1.805.249 2.227.415.562.217.96.477 1.382.896.419.42.679.819.896 1.381.164.422.36 1.057.413 2.227.057 1.266.07 1.646.07 4.85s-.015 3.585-.074 4.85c-.061 1.17-.256 1.805-.421 2.227-.224.562-.479.96-.897 1.382-.419.419-.824.679-1.38.896-.42.164-1.065.36-2.235.413-1.274.057-1.649.07-4.859.07-3.211 0-3.586-.015-4.859-.074-1.171-.061-1.816-.256-2.236-.421-.569-.224-.96-.479-1.379-.897-.421-.419-.69-.824-.9-1.38-.165-.42-.359-1.065-.42-2.235-.045-1.26-.061-1.649-.061-4.844 0-3.196.016-3.586.061-4.861.061-1.17.255-1.814.42-2.234.21-.57.479-.96.9-1.381.419-.419.81-.689 1.379-.898.42-.166 1.051-.361 2.221-.421 1.275-.045 1.65-.06 4.859-.06zm0 3.678c-3.405 0-6.162 2.76-6.162 6.162 0 3.405 2.76 6.162 6.162 6.162 3.405 0 6.162-2.76 6.162-6.162 0-3.405-2.76-6.162-6.162-6.162zM12 16c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4zm7.846-10.405a1.44 1.44 0 1 1-2.88 0 1.44 1.44 0 0 1 2.88 0z',
  },
  {
    name: 'X',
    href: 'https://x.com/tekkauganda',
    // Note: aria-label says "X (Twitter)" so users searching for either find it
    path: 'M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z',
  },
  {
    name: 'Threads',
    href: 'https://www.threads.net/@tekkauganda',
    path: 'M12.186 24h-.007c-3.581-.024-6.334-1.205-8.184-3.509C2.35 18.44 1.5 15.586 1.472 12.01v-.017c.03-3.579.879-6.43 2.525-8.482C5.845 1.205 8.6.024 12.18 0h.014c2.746.02 5.043.725 6.826 2.098 1.677 1.29 2.858 3.13 3.509 5.467l-2.04.569c-1.104-3.96-3.898-5.984-8.304-6.015-2.91.022-5.11.936-6.54 2.717C4.307 6.504 3.616 8.914 3.589 12c.027 3.086.718 5.496 2.057 7.164 1.43 1.783 3.631 2.698 6.54 2.717 2.623-.02 4.358-.631 5.8-2.045 1.647-1.613 1.618-3.593 1.09-4.798-.31-.71-.873-1.3-1.634-1.75-.192 1.352-.622 2.446-1.284 3.272-.886 1.102-2.14 1.704-3.73 1.79-1.202.065-2.361-.218-3.259-.801-1.063-.689-1.685-1.74-1.752-2.964-.065-1.19.408-2.285 1.33-3.082.88-.76 2.119-1.207 3.583-1.291a13.853 13.853 0 0 1 3.02.142c-.126-.742-.375-1.332-.75-1.757-.513-.586-1.308-.883-2.359-.89h-.029c-.844 0-1.992.232-2.721 1.32L7.734 7.847c.98-1.454 2.568-2.256 4.478-2.256h.044c3.194.02 5.097 1.975 5.287 5.388.108.046.216.094.321.142 1.49.7 2.58 1.761 3.154 3.07.797 1.82.871 4.79-1.548 7.158-1.85 1.81-4.094 2.628-7.277 2.65Zm1.003-11.69c-.242 0-.487.007-.739.021-1.836.103-2.98.946-2.916 2.143.067 1.256 1.452 1.839 2.784 1.767 1.224-.065 2.818-.543 3.086-3.71a10.515 10.515 0 0 0-2.215-.221z',
  },
  {
    name: 'Snapchat',
    href: 'https://www.snapchat.com/add/tekkauganda',
    path: 'M12.166.001a6.484 6.484 0 0 0-5.5 2.965c-1.187 1.83-.748 4.81-.566 6.04-.135.075-.42.165-.78.075-.766-.21-1.561.255-1.876.945-.255.555-.066 1.245.45 1.78.51.555 1.275 1.005 2.16 1.305.124.39-.151 1.155-.451 1.785-.795 1.71-2.13 3.886-4.62 4.291-.39.06-.661.405-.616.795 0 .03.03.09.045.135.226.51.96.945 2.581 1.215.105.18.225.794.39 1.215.105.27.27.39.51.39.36 0 .886-.15 1.681-.27.435-.075 1.005-.135 1.516-.135.916 0 1.215.15 1.846.6 1.05.766 2.28 1.605 4.246 1.605.045 0 .12-.015.18-.015.06 0 .136.015.181.015 1.95 0 3.18-.84 4.245-1.605.63-.45.93-.6 1.846-.6.51 0 1.08.075 1.515.135.795.135 1.31.224 1.681.27.345 0 .525-.18.615-.435.165-.42.27-1.005.39-1.215 1.621-.27 2.355-.705 2.581-1.215.045-.075.06-.135.06-.21.045-.39-.225-.735-.615-.795-2.476-.405-3.826-2.58-4.62-4.291-.286-.63-.586-1.395-.451-1.785.9-.3 1.65-.75 2.16-1.305.526-.555.706-1.245.45-1.78a1.443 1.443 0 0 0-1.876-.945c-.345.09-.615 0-.78-.075.181-1.245.621-4.21-.555-6.025A6.434 6.434 0 0 0 12.166.001Z',
  },
];

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
          <ul
            className="flex items-center gap-5 mt-4 md:mt-0"
            aria-label="Tekka on social media"
          >
            {SOCIALS.map((s) => (
              <li key={s.name}>
                <a
                  href={s.href}
                  target="_blank"
                  rel="noopener noreferrer me"
                  aria-label={`Follow Tekka Uganda on ${s.name === 'X' ? 'X (Twitter)' : s.name}`}
                  title={s.name === 'X' ? 'X (Twitter)' : s.name}
                  className="inline-flex text-gray-300 hover:text-primary-500 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-900 rounded-sm"
                >
                  <svg
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    className="h-5 w-5"
                    aria-hidden="true"
                  >
                    <path d={s.path} />
                  </svg>
                </a>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </footer>
  );
}

export default Footer;
