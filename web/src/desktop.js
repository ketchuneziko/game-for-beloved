// Desktop OS Window Manager & Apps for "Print I Love You: For My Beloved"
import { soundEngine } from './audio.js';
import { configManager } from './config.js';

export class DesktopManager {
  constructor() {
    window.desktop = this;
    this.windows = {};
    this.activeWindow = null;
    this.highestZ = 100;
    this.achievements = this.loadAchievements();
    this.notesRead = new Set();
    this.draftsRead = new Set();
    this.init();
  }

  loadAchievements() {
    try {
      const saved = localStorage.getItem('pilu_achievements');
      if (saved) return JSON.parse(saved);
    } catch (e) {}
    return {
      honesty: false,
      too_honest: false,
      hand_warmth: false,
      fashion_guru: false,
      heart_sync: false,
      rummager: false,
      polaroid_lover: false,
      return_true: false
    };
  }

  saveAchievements() {
    try {
      localStorage.setItem('pilu_achievements', JSON.stringify(this.achievements));
    } catch (e) {}
  }

  unlockAchievement(id, title, desc, icon = '🏆') {
    if (this.achievements[id]) return; // already unlocked
    this.achievements[id] = true;
    this.saveAchievements();
    soundEngine.playAchievement();
    this.showToast(`${icon} Достижение получено!`, `«${title}» — ${desc}`);
    this.updateAchievementsUI();
  }

  showToast(title, message) {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const toast = document.createElement('div');
    toast.className = 'retro-toast';
    toast.innerHTML = `
      <div class="toast-title">${title}</div>
      <div class="toast-body">${message}</div>
    `;
    container.appendChild(toast);
    setTimeout(() => {
      toast.classList.add('fade-out');
      setTimeout(() => toast.remove(), 400);
    }, 4500);
  }

  init() {
    this.setupIcons();
    this.setupWindows();
    this.setupTaskbar();
    this.setupClock();
    this.setupTheme();
  }

  setupIcons() {
    document.querySelectorAll('.desktop-icon').forEach(icon => {
      icon.addEventListener('click', (e) => {
        soundEngine.playClick();
        const winId = icon.getAttribute('data-window');
        if (winId) {
          this.openWindow(winId);
        }
      });
      // Double click support
      icon.addEventListener('dblclick', () => {
        const winId = icon.getAttribute('data-window');
        if (winId) this.openWindow(winId);
      });
    });
  }

  setupWindows() {
    document.querySelectorAll('.retro-window').forEach(win => {
      const winId = win.id;
      this.windows[winId] = {
        el: win,
        isMin: false,
        isMax: false,
        origX: win.offsetLeft,
        origY: win.offsetTop,
        origW: win.offsetWidth,
        origH: win.offsetHeight
      };

      // Dragging logic
      const header = win.querySelector('.window-header');
      if (header) {
        let isDragging = false;
        let startX, startY, initX, initY;

        header.addEventListener('mousedown', (e) => {
          if (e.target.closest('.window-btn')) return;
          this.bringToFront(winId);
          isDragging = true;
          startX = e.clientX;
          startY = e.clientY;
          initX = win.offsetLeft;
          initY = win.offsetTop;
          document.body.classList.add('dragging');
        });

        window.addEventListener('mousemove', (e) => {
          if (!isDragging) return;
          const dx = e.clientX - startX;
          const dy = e.clientY - startY;
          win.style.left = `${Math.max(10, initX + dx)}px`;
          win.style.top = `${Math.max(10, initY + dy)}px`;
        });

        window.addEventListener('mouseup', () => {
          isDragging = false;
          document.body.classList.remove('dragging');
        });
      }

      // Bring to front on click
      win.addEventListener('mousedown', () => {
        this.bringToFront(winId);
      });

      // Window controls
      const closeBtn = win.querySelector('.btn-close');
      if (closeBtn) {
        closeBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.closeWindow(winId);
        });
      }

      const minBtn = win.querySelector('.btn-min');
      if (minBtn) {
        minBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.minimizeWindow(winId);
        });
      }
    });
  }

  openWindow(winId) {
    soundEngine.unlock();
    const win = this.windows[winId];
    if (!win) return;
    win.el.style.display = 'flex';
    win.el.classList.remove('minimized');
    this.bringToFront(winId);
    this.updateTaskbar();

    // Specific window opens
    if (winId === 'win-trash') this.renderTrash();
    if (winId === 'win-notes') this.renderNotes();
    if (winId === 'win-photos') this.renderPhotos();
    if (winId === 'win-achievements') this.updateAchievementsUI();
    if (winId === 'win-settings') this.renderSettings();
  }

  closeWindow(winId) {
    soundEngine.playClick();
    const win = this.windows[winId];
    if (!win) return;
    win.el.style.display = 'none';
    this.updateTaskbar();
  }

  minimizeWindow(winId) {
    soundEngine.playClick();
    const win = this.windows[winId];
    if (!win) return;
    win.el.classList.add('minimized');
    this.updateTaskbar();
  }

  bringToFront(winId) {
    const win = this.windows[winId];
    if (!win) return;
    this.highestZ += 2;
    win.el.style.zIndex = this.highestZ;
    this.activeWindow = winId;
    this.updateTaskbar();
  }

  setupTaskbar() {
    const startBtn = document.getElementById('start-btn');
    const startMenu = document.getElementById('start-menu');
    if (startBtn && startMenu) {
      startBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        soundEngine.playClick();
        startMenu.classList.toggle('open');
      });
      document.addEventListener('click', (e) => {
        if (!e.target.closest('#start-menu') && !e.target.closest('#start-btn')) {
          startMenu.classList.remove('open');
        }
      });
    }

    // Sound toggle
    const soundToggle = document.getElementById('sound-toggle');
    if (soundToggle) {
      soundToggle.addEventListener('click', () => {
        const isMuted = soundEngine.toggleMute();
        soundToggle.textContent = isMuted ? '🔇' : '🔊';
        soundToggle.title = isMuted ? 'Включить звук' : 'Выключить звук';
      });
    }

    // CRT toggle
    const crtToggle = document.getElementById('crt-toggle');
    if (crtToggle) {
      crtToggle.addEventListener('click', () => {
        soundEngine.playClick();
        document.body.classList.toggle('no-crt');
        const hasCrt = !document.body.classList.contains('no-crt');
        crtToggle.textContent = hasCrt ? '📺 CRT: ON' : '📺 CRT: OFF';
      });
    }

    // Theme toggle
    const themeToggle = document.getElementById('theme-toggle');
    if (themeToggle) {
      themeToggle.addEventListener('click', () => {
        soundEngine.playClick();
        document.body.classList.toggle('dark-theme');
        const isDark = document.body.classList.contains('dark-theme');
        themeToggle.textContent = isDark ? '🌙 Midnight' : '🌸 Blush';
      });
    }
  }

  updateTaskbar() {
    const taskList = document.getElementById('task-list');
    if (!taskList) return;
    taskList.innerHTML = '';

    for (const [id, win] of Object.entries(this.windows)) {
      if (win.el.style.display !== 'none') {
        const btn = document.createElement('button');
        btn.className = `task-item ${this.activeWindow === id && !win.el.classList.contains('minimized') ? 'active' : ''}`;
        const title = win.el.querySelector('.window-title')?.textContent || id;
        btn.textContent = title;
        btn.addEventListener('click', () => {
          soundEngine.playClick();
          if (win.el.classList.contains('minimized')) {
            win.el.classList.remove('minimized');
            this.bringToFront(id);
          } else if (this.activeWindow === id) {
            this.minimizeWindow(id);
          } else {
            this.bringToFront(id);
          }
        });
        taskList.appendChild(btn);
      }
    }
  }

  setupClock() {
    const clockEl = document.getElementById('system-clock');
    if (!clockEl) return;
    const update = () => {
      const now = new Date();
      const h = String(now.getHours()).padStart(2, '0');
      const m = String(now.getMinutes()).padStart(2, '0');
      clockEl.textContent = `${h}:${m}`;
    };
    update();
    setInterval(update, 1000);
  }

  setupTheme() {
    // Default CRT on
  }

  // --- TRASH BIN (DRAFTS OF CONFESSIONS) ---
  renderTrash() {
    const body = document.getElementById('trash-content');
    if (!body) return;
    const herName = configManager.get('herName');
    const hisName = configManager.get('hisName');

    const drafts = [
      {
        id: 1,
        title: 'черновик_1_банальный.txt',
        size: '1.2 KB',
        date: 'Вчера 23:42',
        content: `Привет, ${herName}.\n\nЯ долго думал, как сказать тебе всё, что чувствую. Слова кажутся слишком маленькими. Наверное, я просто подойду и скажу вживую: "Я люблю тебя".\n\n[УДАЛЕНО: Слишком сухо, она заслуживает чего-то особенного!]`
      },
      {
        id: 2,
        title: 'черновик_2_стихи_нет_не_надо.txt',
        size: '0.8 KB',
        date: 'Вчера 00:15',
        content: `Розы красные, фиалки синие...\nУ ${herName} глаза самые красивые...\n\n[УДАЛЕНО: Какой же позор, ${hisName}, стихи точно не твоё. Срочно сотри, пока она не увидела!!]`
      },
      {
        id: 3,
        title: 'черновик_3_план_свидания.txt',
        size: '2.4 KB',
        date: 'Позавчера 18:20',
        content: `ПЛАН ИДЕАЛЬНОГО ДНЯ:\n1. Купить её любимый латте\n2. Не забыть взять тёплую куртку (она вечно мёрзнет)\n3. Держать за руку весь вечер\n4. Смотреть, как она смеётся\n5. Напомнить ей, что она моё главное сокровище.`
      },
      {
        id: 4,
        title: 'черновик_4_код_любви.py',
        size: '1.8 KB',
        date: '3 дня назад',
        content: `import heart\n\nwhile True:\n    my_love_for_${herName.toLowerCase()} += float('inf')\n    hold_hands()\n    care_every_day()\n    # Memory leak? No, infinite capacity.\n    return True`
      },
      {
        id: 5,
        title: 'черновик_5_признание.txt',
        size: '3.1 KB',
        date: 'Только что',
        content: `Если ты читаешь это в корзине... знай:\nЯ переписал эту игру десятки раз, чтобы она заставила тебя улыбнуться.\nТы делаешь меня самым счастливым парнем во Вселенной. ❤️`
      }
    ];

    body.innerHTML = `
      <div class="trash-grid">
        <div class="trash-list">
          ${drafts.map(d => `
            <div class="draft-row ${this.draftsRead.has(d.id) ? 'read' : ''}" data-id="${d.id}">
              <span class="file-icon">📄</span>
              <span class="file-name">${d.title}</span>
              <span class="file-date">${d.date}</span>
            </div>
          `).join('')}
        </div>
        <div class="draft-preview" id="draft-preview-box">
          <div class="preview-placeholder">Выберите файл из корзины для просмотра...</div>
        </div>
      </div>
    `;

    body.querySelectorAll('.draft-row').forEach(row => {
      row.addEventListener('click', () => {
        soundEngine.playClick();
        body.querySelectorAll('.draft-row').forEach(r => r.classList.remove('selected'));
        row.classList.add('selected');
        const id = parseInt(row.getAttribute('data-id'));
        this.draftsRead.add(id);
        row.classList.add('read');
        const draft = drafts.find(d => d.id === id);
        const pBox = document.getElementById('draft-preview-box');
        if (pBox && draft) {
          pBox.innerHTML = `
            <div class="preview-header">
              <strong>${draft.title}</strong> (${draft.size})
            </div>
            <pre class="preview-body">${draft.content}</pre>
          `;
        }

        // Achievement check: reading all drafts
        if (this.draftsRead.size >= drafts.length) {
          this.unlockAchievement('rummager', 'Любопытный архивариус', 'Прочитаны все черновики в корзине', '🗑️');
        }
      });
    });
  }

  // --- STICKY NOTES OF LOVE ---
  renderNotes() {
    const body = document.getElementById('notes-content');
    if (!body) return;
    const herName = configManager.get('herName');

    const reasons = [
      { id: 1, title: 'Причина №1', text: `За то, как ты улыбаешься, когда видишь что-то милое — в этот момент весь мир вокруг становится светлее.` },
      { id: 2, title: 'Причина №2', text: `За твои холодные ладошки, которые я готов греть в своих карманах каждую секунду.` },
      { id: 3, title: 'Причина №3', text: `За то, как уютно молчать вместе. Нам не нужны лишние слова, чтобы понимать друг друга.` },
      { id: 4, title: 'Причина №4', text: `За твой заразительный смех, над которым я сам не могу перестать улыбаться.` },
      { id: 5, title: 'Причина №5', text: `За то, что в твоих объятиях любой сложный день сразу кажется пустяком.` },
      { id: 6, title: 'Причина №6', text: `За то, как забавно ты воруешь мою толстовку и говоришь, что она тебе идёт больше (и это правда!).` },
      { id: 7, title: 'Причина №7', text: `За твою искренность и чуткость, с которой ты относишься ко всему на свете.` },
      { id: 8, title: 'Причина №8', text: `За то, как ты смотришь на меня. В твоих глазах я чувствую себя самым сильным и любимым.` },
      { id: 9, title: 'Причина №9', text: `За наши разговоры до глубокой ночи, когда не хочется спать, лишь бы ещё минуту побыть с тобой.` },
      { id: 10, title: 'Причина №10', text: `Просто за то, что ты — это ты, ${herName}. Моя единственная и самая любимая девочка.` }
    ];

    body.innerHTML = `
      <div class="sticky-notes-wall">
        ${reasons.map(r => `
          <div class="sticky-note ${this.notesRead.has(r.id) ? 'opened' : ''}" data-id="${r.id}">
            <div class="pin">📌</div>
            <div class="note-header">${r.title}</div>
            <div class="note-text">${r.text}</div>
          </div>
        `).join('')}
      </div>
    `;

    body.querySelectorAll('.sticky-note').forEach(note => {
      note.addEventListener('click', () => {
        soundEngine.playSparkle();
        note.classList.toggle('opened');
        const id = parseInt(note.getAttribute('data-id'));
        this.notesRead.add(id);
      });
    });
  }

  // --- POLAROID PHOTOS GALLERY ---
  renderPhotos() {
    const body = document.getElementById('photos-content');
    if (!body) return;
    const herName = configManager.get('herName');
    const hisName = configManager.get('hisName');

    const photos = [
      {
        id: 1,
        title: 'Мы вместе ❤️',
        caption: `Держимся за руки, как и обещали. Твоя ладошка самая тёплая на свете!`,
        src: 'assets/characters/couple_pixel.png'
      },
      {
        id: 2,
        title: 'Осенняя прогулка под фонарями',
        caption: `Листья падают, фонари горят, а я смотрю только на тебя. Самый волшебный вечер.`,
        src: 'assets/characters/couple_date_night.png'
      },
      {
        id: 3,
        title: `Любимая ${herName}`,
        caption: `Каждый раз, когда ты так улыбаешься, у меня замирает сердце. Ты невероятно красивая!`,
        src: 'assets/characters/girlfriend_portrait.png'
      },
      {
        id: 4,
        title: `Твой разработчик (${hisName})`,
        caption: `Тот самый парень, который готов писать для тебя игры и греть твои ручки каждый день.`,
        src: 'assets/characters/boyfriend_portrait.png'
      },
      {
        id: 5,
        title: 'Стильный образ любимой',
        caption: `Та самая белая кружевная кофточка и твой утончённый стиль, в который я влюбился.`,
        src: 'assets/characters/girlfriend_pixel.png'
      },
      {
        id: 6,
        title: 'Твой парень в любимой куртке',
        caption: `Готов бежать к тебе на встречу в любую погоду!`,
        src: 'assets/characters/boyfriend_pixel.png'
      }
    ];

    body.innerHTML = `
      <div class="polaroid-grid">
        ${photos.map(p => `
          <div class="polaroid-card">
            <div class="polaroid-image">
              <img src="${p.src}" alt="${p.title}">
            </div>
            <div class="polaroid-title">${p.title}</div>
            <div class="polaroid-caption">${p.caption}</div>
          </div>
        `).join('')}
      </div>
    `;

    this.unlockAchievement('polaroid_lover', 'Хранительница воспоминаний', 'Открыт фотоальбом свиданий', '📷');
  }

  // --- PERSONALIZATION SETTINGS ---
  renderSettings() {
    const body = document.getElementById('settings-content');
    if (!body) return;

    body.innerHTML = `
      <div class="settings-form">
        <p class="settings-intro">🌸 Вы можете настроить имена и детали, чтобы игра звучала идеально лично для вас двоих:</p>
        
        <div class="form-group">
          <label for="input-her-name">Имя твоей девушки (её имя в игре):</label>
          <input type="text" id="input-her-name" value="${configManager.get('herName')}" maxlength="24">
        </div>

        <div class="form-group">
          <label for="input-his-name">Твоё имя (имя парня / разработчика):</label>
          <input type="text" id="input-his-name" value="${configManager.get('hisName')}" maxlength="24">
        </div>

        <div class="form-group">
          <label for="input-nickname">Ласковое прозвище (Солнышко, Котёнок, Зайка...):</label>
          <input type="text" id="input-nickname" value="${configManager.get('herNickname')}" maxlength="24">
        </div>

        <div class="settings-actions">
          <button class="retro-button save-btn" id="btn-save-settings">💾 Сохранить изменения</button>
          <button class="retro-button reset-btn" id="btn-reset-settings">🔄 Сбросить по умолчанию</button>
        </div>
      </div>
    `;

    document.getElementById('btn-save-settings')?.addEventListener('click', () => {
      soundEngine.playSparkle();
      const herName = document.getElementById('input-her-name').value.trim() || 'Мария';
      const hisName = document.getElementById('input-his-name').value.trim() || 'Твой парень';
      const herNickname = document.getElementById('input-nickname').value.trim() || 'Солнышко';

      configManager.save({ herName, hisName, herNickname });
      this.showToast('✅ Настройки сохранены!', `Игра настроена для ${herName} от ${hisName}`);
      this.closeWindow('win-settings');
    });

    document.getElementById('btn-reset-settings')?.addEventListener('click', () => {
      soundEngine.playClick();
      configManager.reset();
      this.renderSettings();
      this.showToast('🔄 Сброшено', 'Установлены стандартные настройки');
    });
  }

  // --- ACHIEVEMENTS LIST ---
  updateAchievementsUI() {
    const list = document.getElementById('achievements-list');
    if (!list) return;

    const data = [
      { id: 'honesty', title: 'Честность', desc: 'Сказать "Нет" хотя бы один раз при проверке личности', icon: '😇' },
      { id: 'too_honest', title: 'Слишком честная', desc: 'Настаивать на "Нет" 3 раза подряд (пасхалка)', icon: '🤭' },
      { id: 'hand_warmth', title: 'Рука об руку', desc: 'Набрать 100% тепла в тесте на держание за руки', icon: '🤝' },
      { id: 'fashion_guru', title: 'Модный эксперт её сердца', desc: 'Подобрать идеальные наряды для всех свиданий', icon: '👗' },
      { id: 'heart_sync', title: 'В унисон', desc: 'Достичь 100% гармонии сердец в тесте ритма', icon: '💓' },
      { id: 'rummager', title: 'Любопытный архивариус', desc: 'Прочитать все черновики писем в корзине', icon: '🗑️' },
      { id: 'polaroid_lover', title: 'Хранительница воспоминаний', desc: 'Заглянуть в фотоальбом общих моментов', icon: '📷' },
      { id: 'return_true', title: 'RETURN TRUE', desc: 'Запустить вечный бесконечный цикл любви', icon: '💍' }
    ];

    const total = data.length;
    const unlockedCount = data.filter(d => this.achievements[d.id]).length;

    list.innerHTML = `
      <div class="achievements-summary">
        Разблокировано: <strong>${unlockedCount} / ${total}</strong> (${Math.round((unlockedCount / total) * 100)}%)
      </div>
      <div class="achievements-grid">
        ${data.map(a => {
          const isUnlocked = !!this.achievements[a.id];
          return `
            <div class="achievement-card ${isUnlocked ? 'unlocked' : 'locked'}">
              <div class="ach-icon">${isUnlocked ? a.icon : '🔒'}</div>
              <div class="ach-info">
                <div class="ach-title">${a.title}</div>
                <div class="ach-desc">${a.desc}</div>
              </div>
            </div>
          `;
        }).join('')}
      </div>
    `;
  }
}
