import { SearchPlugin } from "vitepress-plugin-search";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [
    SearchPlugin({
      placeholder: "Search Documentation",
      buttonLabel: "Search",
      previewLength: 10,
    }),
  ],
});