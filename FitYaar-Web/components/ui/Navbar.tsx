"use client";

import Link from "next/link";
import { useState } from "react";
import { useAuth } from "@/components/auth/AuthContext";
import { API_BASE } from "@/lib/api";
import Wordmark from "./Wordmark";

const NAV = [
  { label: "Exercises", href: "/exercises" },
  { label: "Calculators", href: "/calculators" },
  { label: "Blog", href: "/blog" },
  { label: "For Gyms", href: "/fityaar-for-gyms" },
];

export default function Navbar() {
  const { user, loading, logout } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);

  // Same-origin in production → the /admin portal reads the shared fy_admin_*
  // localStorage keys and boots already authenticated.
  function openManagement() {
    setMenuOpen(false);
    window.location.href = `${API_BASE}/admin/`;
  }

  return (
    <header className="sticky top-0 z-40 border-b border-white/10 bg-bg-bottom/70 backdrop-blur-glass">
      <nav className="section flex h-14 items-center justify-between">
        <Wordmark priority />

        <div className="flex items-center gap-1 sm:gap-2">
          {NAV.map((n) => (
            <Link
              key={n.href}
              href={n.href}
              className="rounded-pill px-3 py-2 text-sm text-white/75 transition hover:bg-white/5 hover:text-white"
            >
              {n.label}
            </Link>
          ))}

          {loading ? null : user ? (
            <div className="relative">
              <button
                onClick={() => setMenuOpen((o) => !o)}
                className="glass ml-1 flex items-center gap-2 rounded-pill px-3 py-2 text-sm"
                aria-haspopup="menu"
                aria-expanded={menuOpen}
              >
                <span className="grid h-6 w-6 place-items-center rounded-full bg-brand-orange/25 text-xs font-bold text-brand-light">
                  {user.displayName?.[0]?.toUpperCase() ?? "U"}
                </span>
                <span className="hidden max-w-[120px] truncate sm:block">
                  {user.displayName}
                </span>
              </button>

              {menuOpen && (
                <>
                  <button
                    className="fixed inset-0 z-40 cursor-default"
                    aria-hidden
                    onClick={() => setMenuOpen(false)}
                  />
                  <div
                    role="menu"
                    className="glass absolute right-0 z-50 mt-2 w-56 overflow-hidden p-1.5"
                  >
                    <MenuLink href="/me" onClick={() => setMenuOpen(false)}>
                      My Fitness
                    </MenuLink>
                    <MenuLink href="/me#gym" onClick={() => setMenuOpen(false)}>
                      My Gym
                    </MenuLink>
                    {user.role === "ADMIN" && (
                      <button
                        role="menuitem"
                        onClick={openManagement}
                        className="flex w-full items-center justify-between rounded-pill px-3 py-2 text-left text-sm font-semibold text-brand-light transition hover:bg-white/5"
                      >
                        FitYaar Management
                        <span aria-hidden>↗</span>
                      </button>
                    )}
                    <div className="my-1 h-px bg-white/10" />
                    <button
                      role="menuitem"
                      onClick={() => {
                        logout();
                        setMenuOpen(false);
                      }}
                      className="w-full rounded-pill px-3 py-2 text-left text-sm text-white/70 transition hover:bg-white/5 hover:text-white"
                    >
                      Log out
                    </button>
                  </div>
                </>
              )}
            </div>
          ) : (
            <Link href="/login" className="glass-btn ml-1">
              Log in
            </Link>
          )}
        </div>
      </nav>
    </header>
  );
}

function MenuLink({
  href,
  children,
  onClick,
}: {
  href: string;
  children: React.ReactNode;
  onClick?: () => void;
}) {
  return (
    <Link
      role="menuitem"
      href={href}
      onClick={onClick}
      className="block rounded-pill px-3 py-2 text-sm text-white/85 transition hover:bg-white/5 hover:text-white"
    >
      {children}
    </Link>
  );
}
