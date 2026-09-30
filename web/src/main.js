// Main Application Entry Point
import { soundEngine } from './audio.js';
import { DesktopManager } from './desktop.js';
import { GameEngine } from './game.js';
import { configManager } from './config.js';

window.addEventListener('DOMContentLoaded', () => {
  // Initialize Desktop OS
  const desktop = new DesktopManager();
  window.desktop = desktop;

  // Initialize Game
  const game = new GameEngine(desktop);
  window.game = game;

  // Handle first user interaction to unlock audio
  const unlockAudio = () => {
    soundEngine.unlock();
    const banner = document.getElementById('audio-banner');
    if (banner) {
      banner.style.opacity = '0';
      setTimeout(() => banner.remove(), 400);
    }
    window.removeEventListener('click', unlockAudio);
    window.removeEventListener('keydown', unlockAudio);
    window.removeEventListener('touchstart', unlockAudio);
  };

  window.addEventListener('click', unlockAudio);
  window.addEventListener('keydown', unlockAudio);
  window.addEventListener('touchstart', unlockAudio);

  // Hook Music Player Buttons
  document.getElementById('play-theme-desktop')?.addEventListener('click', () => {
    soundEngine.playMusic('desktop');
  });
  document.getElementById('play-theme-hand')?.addEventListener('click', () => {
    soundEngine.playMusic('hand');
  });
  document.getElementById('play-theme-dress')?.addEventListener('click', () => {
    soundEngine.playMusic('dress');
  });
  document.getElementById('play-theme-heart')?.addEventListener('click', () => {
    soundEngine.playMusic('heart');
  });
  document.getElementById('play-theme-finale')?.addEventListener('click', () => {
    soundEngine.playMusic('finale');
  });
  document.getElementById('btn-stop-music')?.addEventListener('click', () => {
    soundEngine.stopMusic();
  });

  // Hook Download Standalone Button
  document.getElementById('btn-download-standalone')?.addEventListener('click', async () => {
    soundEngine.playSparkle();
    desktop.showToast('📦 Сборка офлайн-игры...', 'Создаём один файл HTML со всеми спрайтами и звуками!');

    try {
      const res = await fetch('/export-single-file');
      if (res.ok) {
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `PRINT_I_LOVE_YOU_${configManager.get('herName')}.html`;
        a.click();
        URL.revokeObjectURL(url);
        desktop.showToast('✅ Скачивание началось!', 'Файл готов к отправке любимой девушке!');
      } else {
        window.location.href = '/export-single-file';
      }
    } catch (e) {
      console.warn('Export fetch failed, opening direct link', e);
      window.open('/export-single-file', '_blank');
    }
  });
});
