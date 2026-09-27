import type { ButtonHTMLAttributes } from "react";

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "glass" | "accent";
  loading?: boolean;
};

export default function GlassButton({
  variant = "glass",
  loading = false,
  disabled,
  children,
  className = "",
  ...rest
}: Props) {
  const base = variant === "accent" ? "accent-btn" : "glass-btn";
  return (
    <button
      className={`${base} ${className}`}
      disabled={disabled || loading}
      {...rest}
    >
      {loading ? "Please wait…" : children}
    </button>
  );
}
