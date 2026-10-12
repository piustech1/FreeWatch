/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        darkBg: '#0A0D14',
        cardBg: '#131722',
        cardBorder: 'rgba(255, 255, 255, 0.08)',
        accentGreen: '#00E676',
        accentEmerald: '#10B981',
      }
    },
  },
  plugins: [],
}
