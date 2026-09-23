(() => {
  const nav = document.querySelector('[data-nav]');
  document.querySelector('[data-nav-toggle]')?.addEventListener('click', () => nav?.classList.toggle('open'));
  document.querySelectorAll('[data-alert] button').forEach(b => b.addEventListener('click', () => b.parentElement.remove()));
  setTimeout(() => document.querySelectorAll('[data-alert]').forEach(a => { a.classList.add('fade'); setTimeout(() => a.remove(), 250); }), 5500);
  document.querySelectorAll('[data-confirm]').forEach(el => el.addEventListener('click', e => { if (!confirm(el.dataset.confirm || 'Emin misiniz?')) e.preventDefault(); }));
  const form = document.querySelector('[data-listing-form]');
  if (form) {
    const update = () => {
      const minutes = Number(form.querySelector('[data-minutes]')?.value || 30);
      const bonus = Number(form.querySelector('[data-bonus]')?.value || 0);
      const credits = Math.max(.5, Math.ceil(Math.min(240, Math.max(1, minutes)) / 15) * .5) + Math.max(0, Math.min(1, bonus));
      const out = form.querySelector('[data-credit-preview]');
      if (out) out.textContent = credits.toLocaleString('tr-TR', { minimumFractionDigits: 1, maximumFractionDigits: 1 }) + ' kredi';
    };
    form.addEventListener('change', update); update();
  }
  document.querySelectorAll('[data-modal-open]').forEach(b => b.addEventListener('click', () => document.getElementById(b.dataset.modalOpen)?.showModal()));
  document.querySelectorAll('[data-modal-close]').forEach(b => b.addEventListener('click', () => b.closest('dialog')?.close()));
  document.querySelectorAll('[data-auto-submit]').forEach(s => s.addEventListener('change', () => { if (s.value && confirm('Bu grup işlemi uygulansın mı?')) s.form.submit(); else s.value = ''; }));
  document.querySelectorAll('[data-messages]').forEach(box => box.scrollTop = box.scrollHeight);
})();
