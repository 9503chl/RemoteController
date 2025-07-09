/** @type {import('next').NextConfig} */
const nextConfig = {
    async rewrites() {
        // This is for development environment proxy
        if (process.env.NODE_ENV === 'development') {
            return [
                {
                    source: '/api/:path*',
                    destination: 'http://localhost:8080/:path*', // Proxy to backend
                },
            ];
        }
        return [];
    },
};

export default nextConfig; 