"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import type { AuthUser, RegisterInput } from "@/lib/types";
import {
  readUserCookie,
  sessionLogin,
  sessionLogout,
  sessionRegister,
} from "@/lib/session-client";

interface AuthState {
  user: AuthUser | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<AuthUser>;
  register: (input: RegisterInput) => Promise<AuthUser>;
  logout: () => void;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);

  // Hydrate identity from the readable fy_user cookie (tokens stay httpOnly).
  useEffect(() => {
    setUser(readUserCookie());
    setLoading(false);
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const u = await sessionLogin(email, password);
    setUser(u);
    return u;
  }, []);

  const register = useCallback(async (input: RegisterInput) => {
    const u = await sessionRegister(input);
    setUser(u);
    return u;
  }, []);

  const logout = useCallback(() => {
    void sessionLogout();
    setUser(null);
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within <AuthProvider>");
  return ctx;
}
