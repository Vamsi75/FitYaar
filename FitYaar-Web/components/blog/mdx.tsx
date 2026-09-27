import Link from "next/link";
import type { AnchorHTMLAttributes } from "react";

/** MDX element overrides. Prose styling comes from Tailwind `prose prose-invert`;
 *  here we just route internal links through next/link and open external ones safely. */
export const mdxComponents = {
  a: ({ href = "", children, ...rest }: AnchorHTMLAttributes<HTMLAnchorElement>) => {
    if (href.startsWith("/")) {
      return (
        <Link href={href} {...rest}>
          {children}
        </Link>
      );
    }
    const external = href.startsWith("http");
    return (
      <a
        href={href}
        {...(external ? { target: "_blank", rel: "noopener noreferrer" } : {})}
        {...rest}
      >
        {children}
      </a>
    );
  },
};
