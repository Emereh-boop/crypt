/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{svelte,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'primary': '#E5B910',
        'black': '#1D1D1D',
        'gray-400': '#6B6B6B',
        'gray-100': '#C4C4C4',
        'gray-900': '#393939',
        'peach-100': '#FFEFEF',
        'peach-400': '#FF9F9F',
      },
    },
  },
  plugins: [],
}