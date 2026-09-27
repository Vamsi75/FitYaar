import Link from "next/link";
import Image from "next/image";

/** Brand wordmark lockup (icon + "FitYaar"), sourced from the app brand assets. */
export default function Wordmark({
  className = "",
  priority = false,
}: {
  className?: string;
  priority?: boolean;
}) {
  return (
    <Link
      href="/"
      aria-label="FitYaar — home"
      className={`inline-flex items-center ${className}`}
    >
      <Image
        src="/brand/wordmark.png"
        alt="FitYaar"
        width={410}
        height={145}
        priority={priority}
        className="h-8 w-auto"
      />
    </Link>
  );
}
