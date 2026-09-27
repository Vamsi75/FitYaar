/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // The public site and the existing super-admin portal (/admin, served by the
  // Spring backend) are one product on one origin in production. In dev, calls
  // go to NEXT_PUBLIC_API_BASE_URL (default http://localhost:2098).
};

export default nextConfig;
