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
        adminGreen: '#00E676',
        adminYellow: '#F59E0B',
        adminRed: '#EF4444',
        adminPurple: '#8B5CF6',
        accentEmerald: '#00E676',
        accentGreen: '#00E676',
        accentDark: '#00B050',
        accentLight: '#69F0AE',
        fwGreen: '#00E676',
        fwGreenDark: '#00B050',
        fwGreenLight: '#69F0AE',
        fwRed: '#E50914',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
