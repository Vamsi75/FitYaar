import type { Metadata } from "next";
import LoginForm from "@/components/auth/LoginForm";

export const metadata: Metadata = {
  title: "Log in",
  description: "Log in to your FitYaar account.",
  robots: { index: false, follow: false },
};

export default function Page() {
  return <LoginForm />;
}
