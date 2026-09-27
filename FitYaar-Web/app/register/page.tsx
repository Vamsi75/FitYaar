import type { Metadata } from "next";
import RegisterForm from "@/components/auth/RegisterForm";

export const metadata: Metadata = {
  title: "Create your account",
  description: "Create a free FitYaar account — one login for the app and web.",
  robots: { index: false, follow: false },
};

export default function Page() {
  return <RegisterForm />;
}
