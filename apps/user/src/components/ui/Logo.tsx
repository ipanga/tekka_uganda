import Image from 'next/image';

interface LogoProps {
  variant?: 'dark' | 'light' | 'auto';
  height?: number;
  className?: string;
}

export function Logo({ variant = 'auto', height = 28, className = '' }: LogoProps) {
  const width = Math.round(height * 3);

  if (variant === 'light') {
    return (
      <Image
        src="/images/tekka_logo_white.svg"
        alt="Tekka"
        height={height}
        width={width}
        className={className}
        priority
      />
    );
  }

  if (variant === 'dark') {
    return (
      <Image
        src="/images/tekka_logo.svg"
        alt="Tekka"
        height={height}
        width={width}
        className={className}
        priority
      />
    );
  }

  // auto: theme-aware
  return (
    <span className={className}>
      <Image
        src="/images/tekka_logo.svg"
        alt="Tekka"
        height={height}
        width={width}
        className="dark:hidden"
        priority
      />
      <Image
        src="/images/tekka_logo_white.svg"
        alt="Tekka"
        height={height}
        width={width}
        className="hidden dark:block"
        priority
      />
    </span>
  );
}
