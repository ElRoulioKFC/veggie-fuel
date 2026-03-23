import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { copyFileSync, mkdirSync } from 'fs'
import { resolve } from 'path'

// Custom plugin to copy highs.wasm into the build output
function copyHighsWasm() {
  return {
    name: 'copy-highs-wasm',
    writeBundle(options: { dir?: string }) {
      const outDir = options.dir || 'dist'
      mkdirSync(outDir, { recursive: true })
      copyFileSync(
        resolve(__dirname, 'node_modules/highs/build/highs.wasm'),
        resolve(outDir, 'highs.wasm'),
      )
    },
  }
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), copyHighsWasm()],
  optimizeDeps: {
    exclude: ['highs'],
  },
})
