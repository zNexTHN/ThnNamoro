import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  base: "./", // <--- ADICIONE ESTA LINHA OBRIGATÓRIA PARA FIVEM
  server: {
    host: "::",
    port: 8080,
  },
  plugins: [react(), mode === "development" && componentTagger()].filter(Boolean),
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  // DICA EXTRA: Para jogar o build direto na pasta html (opcional)
  build: {
    outDir: 'dist', // ou '../html' se a pasta do react estiver dentro do resource
    emptyOutDir: true,
    
    // ADICIONE ESTA PARTE DO ROLLUPOPTIONS
    rollupOptions: {
      output: {
        // Garante que o arquivo JS principal tenha um nome fixo (ex: index.js)
        entryFileNames: `assets/[name].js`,
        // Garante que pedaços de código (chunks) tenham nomes fixos
        chunkFileNames: `assets/[name].js`,
        // Garante que arquivos de CSS, imagens, etc. tenham nomes fixos
        assetFileNames: `assets/[name].[ext]`,
      },
    },
  }
}));