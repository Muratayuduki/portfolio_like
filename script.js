const revealTargets = document.querySelectorAll('.section-reveal');
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add('is-visible');
    }
  });
}, { threshold: 0.16 });

revealTargets.forEach((target) => observer.observe(target));

const menuButton = document.querySelector('.menu-button');
const nav = document.querySelector('.nav');

menuButton?.addEventListener('click', () => {
  nav.style.display = nav.style.display === 'flex' ? 'none' : 'flex';
  nav.style.position = 'absolute';
  nav.style.top = '70px';
  nav.style.right = '5vw';
  nav.style.flexDirection = 'column';
  nav.style.padding = '18px';
  nav.style.background = 'rgba(255,255,255,.96)';
  nav.style.border = '1px solid #d5dedc';
});
