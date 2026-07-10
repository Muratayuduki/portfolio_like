document.documentElement.classList.add('js');

const header = document.querySelector('.site-header');
const menuButton = document.querySelector('.menu-button');
const nav = document.querySelector('.nav');
const menuLabel = menuButton?.querySelector('.visually-hidden');

const updateHeader = () => {
  header?.classList.toggle('is-scrolled', window.scrollY > 24);
};

const closeMenu = () => {
  document.body.classList.remove('menu-open');
  menuButton?.setAttribute('aria-expanded', 'false');
  if (menuLabel) menuLabel.textContent = 'メニューを開く';
};

menuButton?.addEventListener('click', () => {
  const willOpen = !document.body.classList.contains('menu-open');
  document.body.classList.toggle('menu-open', willOpen);
  menuButton.setAttribute('aria-expanded', String(willOpen));
  if (menuLabel) menuLabel.textContent = willOpen ? 'メニューを閉じる' : 'メニューを開く';
});

nav?.querySelectorAll('a').forEach((link) => link.addEventListener('click', closeMenu));

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') closeMenu();
});

window.addEventListener('resize', () => {
  if (window.innerWidth > 980) closeMenu();
});

window.addEventListener('scroll', updateHeader, { passive: true });
updateHeader();

const revealTargets = document.querySelectorAll('.section-reveal');

if ('IntersectionObserver' in window) {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -40px' });

  revealTargets.forEach((target) => observer.observe(target));
} else {
  revealTargets.forEach((target) => target.classList.add('is-visible'));
}
