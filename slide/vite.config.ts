import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { fileURLToPath } from 'node:url'

// https://vite.dev/config/
// Hai bộ slide: index.html (Lab 3) và final.html (Final Assignment).
export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      input: {
        main: fileURLToPath(new URL('./index.html', import.meta.url)),
        final: fileURLToPath(new URL('./final.html', import.meta.url)),
      },
    },
  },
})
