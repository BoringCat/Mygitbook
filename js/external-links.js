// 给外部链接加上 target="_blank",避免跳转离开书本
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('a[href^="http:"], a[href^="https:"]').forEach(a => {
    if (a.hostname !== location.hostname && !a.target) {
      a.target = '_blank';
      a.rel = 'noopener noreferrer';
    }
  });
});
