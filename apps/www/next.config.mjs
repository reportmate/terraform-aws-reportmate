/** @type {import("next").NextConfig} */
export default {
  // Production configuration for static deployment
  output: 'export',
  trailingSlash: true,
  skipTrailingSlashRedirect: true,
  distDir: 'out',
  
  // Disable image optimization for static export
  images: {
    unoptimized: true
  },
  
  // Environment variables
  env: {
    NEXT_PUBLIC_WPS_URL: process.env.NEXT_PUBLIC_WPS_URL,
    NEXT_PUBLIC_ENABLE_SIGNALR: process.env.NEXT_PUBLIC_ENABLE_SIGNALR,
    NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL
  }
}
