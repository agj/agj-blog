import { defineConfig } from "vite";

export default {
  vite: defineConfig({}),
  headTagsTemplate(context) {
    return `
      <link rel="stylesheet" href="/style.css" />
      <link rel="me" href="https://mstdn.social/@agj" />
      <meta name="generator" content="elm-pages v${context.cliVersion}" />
    `;
  },
  preloadTagForFile(file) {
    // add preload directives for JS assets and font assets, etc., skip for CSS
    // files this function will be called with each file that is procesed by
    // Vite, including any files in your headTagsTemplate in your config
    return !file.endsWith(".css");
  },
};
