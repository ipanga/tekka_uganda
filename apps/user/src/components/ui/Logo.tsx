import Image from 'next/image';

interface LogoProps {
  variant?: 'dark' | 'light';
  height?: number;
  className?: string;
}

export function Logo({ variant = 'dark', height = 28, className = '' }: LogoProps) {
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
