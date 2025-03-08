import tailwindcss from "tailwindcss";
import autoprefixer from "autoprefixer";
import { elmReviewTailwindCssPlugin } from "elm-review-tailwindcss-postcss-plugin";

export default {
  plugins: [tailwindcss(), autoprefixer(), elmReviewTailwindCssPlugin()],
};
