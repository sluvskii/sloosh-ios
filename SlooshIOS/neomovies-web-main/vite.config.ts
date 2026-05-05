import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [['babel-plugin-react-compiler']],
      },
    }),
  ],
  build: {
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          if (id.includes('node_modules')) {
            if (id.includes('@mui')) {
              return 'mui'
            }
            if (id.includes('react')) {
              return 'vendor'
            }
          }
        },
      },
    },
  },
  server: {
    host: true,
    middlewareMode: false,
  },
})
