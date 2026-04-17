'use client';

import Image from 'next/image';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { getStoreUrl, type MobilePlatform } from '@/lib/app-links';

interface GetAppModalProps {
  isOpen: boolean;
  platform: MobilePlatform;
  title?: string;
  message?: string;
  continueLabel?: string;
  onClose: () => void;
  onContinueOnWeb: () => void;
}

export function GetAppModal({
  isOpen,
  platform,
  title = 'Chat in the Tekka app',
  message = 'Get a faster, more reliable messaging experience with push notifications in the Tekka Uganda app.',
  continueLabel = 'Continue on web',
  onClose,
  onContinueOnWeb,
}: GetAppModalProps) {
  const storeUrl = getStoreUrl(platform);
  const storeLabel =
    platform === 'ios' ? 'Download on the App Store' : 'Get it on Google Play';

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      size="sm"
      showCloseButton
    >
      <div className="flex flex-col items-center text-center gap-4 pb-2">
        <Image
          src="/icon-192.png"
          alt="Tekka Uganda app icon"
          width={64}
          height={64}
          className="rounded-xl"
          unoptimized
        />
        <div>
          <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
          <p className="mt-1 text-sm text-gray-600">{message}</p>
        </div>
        <div className="flex flex-col w-full gap-2 mt-2">
          {storeUrl && (
            <a
              href={storeUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center rounded-lg bg-primary-500 hover:bg-primary-600 text-white font-semibold text-sm px-4 py-2.5 transition-colors"
            >
              {storeLabel}
            </a>
          )}
          <Button variant="outline" onClick={onContinueOnWeb}>
            {continueLabel}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
