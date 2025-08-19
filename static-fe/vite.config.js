import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  
  // Build configuration for production
  build: {
    // Output directory (default is 'dist')
    outDir: 'dist',
    
    // Generate source maps for debugging (optional)
    sourcemap: false,
    
    // Optimize for production
    minify: 'esbuild',
    
    // Enable/disable CSS code splitting
    cssCodeSplit: true,
    
    // Rollup options for chunking strategy
    rollupOptions: {
      output: {
        // Manual chunking for better caching
        manualChunks: {
          vendor: ['react', 'react-dom'],
        },
        // Asset file naming
        assetFileNames: 'assets/[name]-[hash][extname]',
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
      },
    },
    
    // Target modern browsers for optimal performance
    target: 'esnext',
    
    // Chunk size warning limit
    chunkSizeWarningLimit: 1000,
  },
  
  // Base path for assets (important for CDN deployment)
  base: '/',
  
  // Preview server configuration
  preview: {
    port: 3000,
    open: true,
  },
})
