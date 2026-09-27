import type { Config } from "tailwindcss";
import typography from "@tailwindcss/typography";

/**
 * Brand tokens mirrored from the Flutter app (lib/core/theme/app_colors.dart,
 * main.dart gradient, GlassCard/GlassButton) so the website reads as the same
 * product: dark warm gradient + frosted glass + deep-orange accent.
 */
const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Dark background gradient stops (top-left → bottom-right)
        bg: {
          top: "#241318",
          mid: "#150F12",
          bottom: "#0D0A0B",
        },
        brand: {
          orange: "#FF6F00", // primary accent (Flutter deepOrange)
          light: "#FFCC80",  // light button/text tint (orange.shade200)
          gold: "#FFB020",   // personal-record gold
          peach: "#FFB59D",  // loader peach
        },
        status: {
          live: "#37E29A",
          amber: "#F5A623",
          red: "#FF5A5F",
        },
      },
      fontFamily: {
        sans: ["var(--font-poppins)", "system-ui", "sans-serif"],
      },
      borderRadius: {
        glass: "18px",
        pill: "14px",
      },
      backdropBlur: {
        glass: "14px",
      },
      maxWidth: {
        content: "1120px",
      },
    },
  },
  plugins: [typography],
};

export default config;
