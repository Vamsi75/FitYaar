import type { Metadata } from "next";
import { Poppins } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/components/auth/AuthContext";
import Navbar from "@/components/ui/Navbar";
import Footer from "@/components/ui/Footer";

const poppins = Poppins({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-poppins",
  display: "swap",
});

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://fityaar.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "FitYaar — Fitness, without the confusion",
    template: "%s | FitYaar",
  },
  description:
    "Train, track, eat and understand your body. Free fitness calculators, an exercise library and India-first nutrition — powered by the FitYaar app.",
  applicationName: "FitYaar",
  keywords: [
    "fitness",
    "workout tracker",
    "TDEE calculator",
    "protein calculator",
    "BMI calculator",
    "Indian nutrition",
    "gym",
  ],
  openGraph: {
    type: "website",
    siteName: "FitYaar",
    title: "FitYaar — Fitness, without the confusion",
    description:
      "Train. Track. Eat. Understand your body. Free calculators and tools, powered by the FitYaar app.",
    url: siteUrl,
    images: [{ url: "/brand/logo.png", width: 520, height: 465, alt: "FitYaar" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "FitYaar — Fitness, without the confusion",
    description: "Train. Track. Eat. Understand your body.",
    images: ["/brand/logo.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={poppins.variable}>
      <body className="flex min-h-screen flex-col">
        <AuthProvider>
          <Navbar />
          <main className="flex-1">{children}</main>
          <Footer />
        </AuthProvider>
      </body>
    </html>
  );
}
