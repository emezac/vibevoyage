module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'deep-space': '#1a1d2e',
        'darker': '#0f1117',
        'terracotta': '#e07a5f',
        'sage': '#a3b899',
        'sand': '#f3e5d8',
        'gold': '#f4d03f',
      },
      fontFamily: {
        'display': ['Playfair Display', 'serif'],
        'sans': ['Manrope', 'sans-serif'],
      },
      borderColor: {
        'glass': 'rgba(243, 229, 216, 0.2)',
        'glow': 'rgba(224, 122, 95, 0.3)',
      },
      boxShadow: {
        'glow': '0 25px 50px rgba(224, 122, 95, 0.15)',
      },
      backgroundImage: {
        'hero-pattern': 'radial-gradient(circle at 15% 20%, rgba(224, 122, 95, 0.1) 0%, transparent 40%), radial-gradient(circle at 85% 80%, rgba(163, 184, 153, 0.1) 0%, transparent 40%)',
      },
    },
  },
  plugins: [],
}
