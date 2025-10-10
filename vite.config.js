import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  build: {
    outDir: 'rokct/public/dist',
    rollupOptions: {
      input: 'ui/main.js',
      output: {
        entryFileNames: 'main.js',
        assetFileNames: 'style.css'
      }
    }
  }
})