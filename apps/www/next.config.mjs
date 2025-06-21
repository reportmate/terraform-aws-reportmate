/** @type {import("next").NextConfig} */
export default {
  // Only use static export in production builds
  ...(process.env.NODE_ENV === 'production' && {
    output: 'export',
    trailingSlash: true,
    skipTrailingSlashRedirect: true,
    distDir: 'out',
  }),
  
  // Disable image optimization for static export
  images: {
    unoptimized: process.env.NODE_ENV === 'production'
  },
  
  // Environment variables
  env: {
    NEXT_PUBLIC_WPS_URL: process.env.NEXT_PUBLIC_WPS_URL,
    NEXT_PUBLIC_ENABLE_SIGNALR: process.env.NEXT_PUBLIC_ENABLE_SIGNALR,
    NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL
  }
}
