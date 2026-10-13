/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        pageBg: '#F8FAFC',
        cardBg: '#FFFFFF',
        sidebarBg: '#FFFFFF',
        borderLight: '#E2E8F0',
        textDark: '#0F172A',
        textMuted: '#64748B',
        adminCyan: '#0EA5E9',
        adminGreen: '#10B981',
        adminYellow: '#F59E0B',
        adminRed: '#EF4444',
        adminPurple: '#8B5CF6',
        accentEmerald: '#10B981',
        accentGreen: '#00E676',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
