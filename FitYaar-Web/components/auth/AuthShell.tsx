import Link from "next/link";
import Image from "next/image";
import type { ReactNode } from "react";

export default function AuthShell({
  title,
  subtitle,
  children,
  footer,
}: {
  title: string;
  subtitle: string;
  children: ReactNode;
  footer: ReactNode;
}) {
  return (
    <div className="section flex min-h-[calc(100vh-8rem)] items-center justify-center py-12">
      <div className="glass w-full max-w-md p-7">
        <div className="mb-6 text-center">
          <Link href="/" aria-label="FitYaar — home" className="inline-block">
            <Image
              src="/brand/logo.png"
              alt="FitYaar"
              width={520}
              height={465}
              priority
              className="mx-auto h-20 w-auto"
            />
          </Link>
          <h1 className="mt-4 text-2xl font-bold text-white">{title}</h1>
          <p className="mt-1 text-sm text-white/60">{subtitle}</p>
        </div>
        {children}
        <div className="mt-6 text-center text-sm text-white/60">{footer}</div>
      </div>
    </div>
  );
}
