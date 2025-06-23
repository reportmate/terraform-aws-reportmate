/** @type {import("next").NextConfig} */
export default {
  // Use standalone output for Docker, static export for production builds
  ...(process.env.DOCKER_BUILD === 'true' ? {
    output: 'standalone',
    eslint: {
      // Disable ESLint during production builds in Docker
      ignoreDuringBuilds: true,
    },
    typescript: {
      // Disable TypeScript checking during production builds in Docker
      ignoreBuildErrors: true,
    },
  } : process.env.NODE_ENV === 'production' && {
    output: 'export',
    trailingSlash: true,
    skipTrailingSlashRedirect: true,
    distDir: 'out',
  }),
  
  // Disable image optimization for static export
  images: {
    unoptimized: process.env.NODE_ENV === 'production' && process.env.DOCKER_BUILD !== 'true'
  },
  
  // Environment variables
  env: {
    NEXT_PUBLIC_WPS_URL: process.env.NEXT_PUBLIC_WPS_URL,
    NEXT_PUBLIC_ENABLE_SIGNALR: process.env.NEXT_PUBLIC_ENABLE_SIGNALR,
    NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL
  }
}
