/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/**/*.elm", "./app/**/*.elm"],
  theme: {
    colors: {
      layout: {
        "90": "var(--color-layout-90)",
        "80": "var(--color-layout-80)",
        "70": "var(--color-layout-70)",
        "60": "var(--color-layout-60)",
        "50": "var(--color-layout-50)",
        "40": "var(--color-layout-40)",
        "30": "var(--color-layout-30)",
        "20": "var(--color-layout-20)",
        "10": "var(--color-layout-10)",
      },
      primary: {
        "90": "var(--color-primary-90)",
        "80": "var(--color-primary-80)",
        "70": "var(--color-primary-70)",
        "60": "var(--color-primary-60)",
        "50": "var(--color-primary-50)",
        "40": "var(--color-primary-40)",
        "30": "var(--color-primary-30)",
        "20": "var(--color-primary-20)",
        "10": "var(--color-primary-10)",
      },
      transparent: "transparent",
      inherit: "inherit",
    },
  },
  plugins: [],
};
