// app/assets/javascripts/vibevoyage.js

document.addEventListener('DOMContentLoaded', function() {
  // Intersection Observer para animaciones al hacer scroll
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };

  const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  }, observerOptions);

  // Observar todos los elementos con animación
  const animatedElements = document.querySelectorAll('.fade-in-up');
  animatedElements.forEach(el => {
    observer.observe(el);
  });

  // Smooth scroll para links internos
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });
      }
    });
  });

  // Efecto parallax sutil en el hero
  window.addEventListener('scroll', function() {
    const scrolled = window.pageYOffset;
    const heroSection = document.querySelector('.hero-section');
    if (heroSection) {
      const rate = scrolled * -0.5;
      heroSection.style.transform = `translateY(${rate}px)`;
    }
  });

  // Navbar background al hacer scroll
  window.addEventListener('scroll', function() {
    const header = document.querySelector('header');
    if (header) {
      if (window.scrollY > 100) {
        header.classList.add('scrolled');
      } else {
        header.classList.remove('scrolled');
      }
    }
  });
});

// Agregar estos estilos CSS adicionales para el efecto de navbar
const additionalStyles = `
  header.scrolled .glass-card {
    background: rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(20px);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  }
  
  .fade-in-up {
    opacity: 0;
    transform: translateY(30px);
    transition: opacity 0.6s ease-out, transform 0.6s ease-out;
  }
  
  .fade-in-up.visible {
    opacity: 1;
    transform: translateY(0);
  }
  
  .fade-in-up:nth-child(1) { transition-delay: 0s; }
  .fade-in-up:nth-child(2) { transition-delay: 0.1s; }
  .fade-in-up:nth-child(3) { transition-delay: 0.2s; }
  .fade-in-up:nth-child(4) { transition-delay: 0.3s; }
`;

// Agregar los estilos al documento
const styleSheet = document.createElement('style');
styleSheet.textContent = additionalStyles;
document.head.appendChild(styleSheet);