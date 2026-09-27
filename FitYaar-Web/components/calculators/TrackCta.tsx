import Link from "next/link";

/** Converts calculator traffic into FitYaar users — appears under every tool. */
export default function TrackCta({
  line = "A number is a starting point. Track what you actually eat and lift in FitYaar and watch it change.",
}: {
  line?: string;
}) {
  return (
    <div className="glass mt-8 flex flex-col items-start gap-4 p-6 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h3 className="text-lg font-bold text-white">Track it with FitYaar</h3>
        <p className="mt-1 max-w-lg text-sm text-white/65">{line}</p>
      </div>
      <div className="flex shrink-0 gap-2">
        <Link href="/register" className="accent-btn">
          Start free
        </Link>
        <Link href="/calculators" className="glass-btn">
          More tools
        </Link>
      </div>
    </div>
  );
}
