// Main Game Logic for "Print I Love You: For My Beloved"
import { soundEngine } from './audio.js';
import { art, PALETTE } from './art.js';
import { configManager } from './config.js';

export class GameEngine {
  constructor(desktopManager) {
    this.desktop = desktopManager;
    this.state = 'boot'; // boot, intro_check, story_intro, test1, test2, test3, ending
    this.container = document.getElementById('game-viewport');
    this.canvas = document.getElementById('game-canvas');
    this.ctx = this.canvas ? this.canvas.getContext('2d') : null;

    this.noAttempts = 0;
    this.time = 0;
    this.animId = null;

    // Test 1 state (Hand Holding)
    this.test1 = {
      playerHand: { x: 200, y: 380 },
      girlHand: { x: 400, y: 220, targetX: 400, targetY: 220, vx: 0, vy: 0 },
      isHolding: false,
      warmth: 0,
      milestones: { 25: false, 50: false, 75: false, 100: false },
      obstacles: [],
      bonuses: [],
      lastSpawn: 0,
      holdingTime: 0
    };

    // Test 2 state (Outfit Dress-up)
    this.test2 = {
      round: 0, // 0: Home Cozy, 1: Romantic Walk, 2: Anniversary Date
      selections: { top: null, bottom: null, accessory: null },
      completedRounds: 0,
      feedback: ''
    };

    // Test 3 state (Heart Rhythm Sync)
    this.test3 = {
      beats: [],
      lastBeatTime: 0,
      syncScore: 0,
      stage: 1, // 1: First Days, 2: Deepening, 3: In Unison
      feedbackText: '',
      feedbackAlpha: 0,
      bpm: 72,
      hitsInRow: 0
    };

    this.init();
  }

  init() {
    this.resizeCanvas();
    window.addEventListener('resize', () => this.resizeCanvas());

    // Input listeners for Test 1 (Hand Holding)
    if (this.canvas) {
      const handleMove = (e) => {
        if (this.state !== 'test1') return;
        const rect = this.canvas.getBoundingClientRect();
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        const scaleX = this.canvas.width / rect.width;
        const scaleY = this.canvas.height / rect.height;

        this.test1.playerHand.x = (clientX - rect.left) * scaleX;
        this.test1.playerHand.y = (clientY - rect.top) * scaleY;
      };

      this.canvas.addEventListener('mousemove', handleMove);
      this.canvas.addEventListener('touchmove', handleMove, { passive: false });
    }

    // Input listeners for Test 3 (Heart Rhythm)
    window.addEventListener('keydown', (e) => {
      if (this.state === 'test3' && (e.code === 'Space' || e.code === 'Enter')) {
        e.preventDefault();
        this.triggerHeartHit();
      }
    });

    if (this.canvas) {
      this.canvas.addEventListener('mousedown', () => {
        if (this.state === 'test3') this.triggerHeartHit();
      });
      this.canvas.addEventListener('touchstart', (e) => {
        if (this.state === 'test3') {
          e.preventDefault();
          this.triggerHeartHit();
        }
      }, { passive: false });
    }

    // Start render loop
    this.startLoop();
    this.startBootSequence();
  }

  resizeCanvas() {
    if (!this.canvas) return;
    this.canvas.width = 640;
    this.canvas.height = 440;
  }

  startLoop() {
    let lastT = performance.now();
    const frame = (t) => {
      const dt = Math.min((t - lastT) / 1000, 0.1);
      lastT = t;
      this.time += dt;

      this.update(dt);
      this.render();

      this.animId = requestAnimationFrame(frame);
    };
    this.animId = requestAnimationFrame(frame);
  }

  // --- BOOT & IDENTITY CHECK SEQUENCE ---
  startBootSequence() {
    this.state = 'boot';
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="terminal-boot">
        <div class="boot-line" id="bline-1">> LOVE_KERNEL v4.2.0 initialized...</div>
        <div class="boot-line" id="bline-2">> Checking romantic memories: 100% OK</div>
        <div class="boot-line" id="bline-3">> Finding special person... TARGET_FOUND</div>
        <div class="boot-line" id="bline-4">> Launching Identity Verification Protocol...</div>
      </div>
    `;

    setTimeout(() => {
      document.getElementById('bline-1')?.classList.add('visible');
      soundEngine.playTypewriter();
    }, 400);
    setTimeout(() => {
      document.getElementById('bline-2')?.classList.add('visible');
      soundEngine.playTypewriter();
    }, 1000);
    setTimeout(() => {
      document.getElementById('bline-3')?.classList.add('visible');
      soundEngine.playTypewriter();
    }, 1600);
    setTimeout(() => {
      document.getElementById('bline-4')?.classList.add('visible');
      soundEngine.playTypewriter();
      setTimeout(() => this.showIdentityCheck(), 1000);
    }, 2200);
  }

  showIdentityCheck() {
    this.state = 'intro_check';
    soundEngine.playMusic('desktop');
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    const herName = configManager.get('herName');

    ui.innerHTML = `
      <div class="dialogue-box intro-check-box">
        <div class="dialogue-portrait">
          <img src="assets/characters/girlfriend_portrait.png" alt="${herName}">
        </div>
        <div class="dialogue-content">
          <div class="speaker-name">PRINT_I_LOVE_YOU.exe</div>
          <div class="dialogue-text" id="check-text">
            Привет! Прежде чем мы начнём...<br>
            Ты ведь <strong>${herName}</strong>?
          </div>
          <div class="dialogue-choices">
            <button class="choice-btn primary" id="btn-choice-yes">💖 Да, это я!</button>
            <button class="choice-btn secondary" id="btn-choice-no">🤔 Нет, я случайно...</button>
          </div>
        </div>
      </div>
    `;

    document.getElementById('btn-choice-yes')?.addEventListener('click', () => {
      soundEngine.playSparkle();
      this.handleIdentityYes();
    });

    document.getElementById('btn-choice-no')?.addEventListener('click', () => {
      this.handleIdentityNo();
    });
  }

  handleIdentityNo() {
    this.noAttempts++;
    soundEngine.playClick();
    const textEl = document.getElementById('check-text');
    const herName = configManager.get('herName');
    const hisName = configManager.get('hisName');

    if (this.noAttempts === 1) {
      this.desktop.unlockAchievement('honesty', 'Честность', 'Сказать "Нет" хотя бы один раз при проверке личности', '😇');
      if (textEl) {
        textEl.innerHTML = `Хм-м-м... Но этот секретный файл отправлен ровно одной девушке на всей планете.<br>Признавайся, <strong>${herName}</strong>, ты же меня разыгрываешь? :)`;
      }
    } else if (this.noAttempts === 2) {
      if (textEl) {
        textEl.innerHTML = `Так-так, самозванка! Если ты не моя любимая, немедленно закрой это окно!<br>Здесь вообще-то хранятся строго конфиденциальные признания в любви. Ну ладно, признайся уже!`;
      }
    } else {
      this.desktop.unlockAchievement('too_honest', 'Слишком честная', 'Настаивать на "Нет" 3 раза подряд (пасхалка)', '🤭');
      if (textEl) {
        textEl.innerHTML = `Я же вижу этот хитрый огонёк в твоих глазах и эту улыбку! Кого ты обманываешь?<br>Входи уже, глупышка, <strong>${hisName}</strong> весь вечер писал это для тебя ❤️`;
      }
      const noBtn = document.getElementById('btn-choice-no');
      if (noBtn) noBtn.style.display = 'none';
    }
  }

  handleIdentityYes() {
    const herName = configManager.get('herName');
    const hisName = configManager.get('hisName');
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="dialogue-box story-intro-box">
        <div class="dialogue-portrait">
          <img src="assets/characters/boyfriend_portrait.png" alt="${hisName}">
        </div>
        <div class="dialogue-content">
          <div class="speaker-name">${hisName}</div>
          <div class="dialogue-text typewriter-text" id="intro-narrative">
            Привет, любимая ${herName}...<br><br>
            В одной известной игре парень пытался через тесты доказать свои чувства, потому что боялся и сомневался...<br>
            Но нам ничего не нужно доказывать — <strong>мы уже вместе</strong>.<br><br>
            И всё же, я создал наши собственные Тесты Любви. Не для проверки, а чтобы напомнить, как сильно я ценю каждый наш миг.<br>
            Готова пройти их со мной?
          </div>
          <div class="dialogue-choices">
            <button class="choice-btn primary" id="btn-start-tests">🌸 Давай начнём свидание!</button>
          </div>
        </div>
      </div>
    `;

    soundEngine.playTypewriter();

    document.getElementById('btn-start-tests')?.addEventListener('click', () => {
      soundEngine.playSparkle();
      this.startTest1();
    });
  }

  // ==========================================
  // TEST 1: HAND-HOLDING MINIGAME
  // ==========================================
  startTest1() {
    this.state = 'test1';
    soundEngine.playMusic('hand');
    this.test1.warmth = 0;
    this.test1.isHolding = false;
    this.test1.milestones = { 25: false, 50: false, 75: false, 100: false };
    this.test1.obstacles = [];
    this.test1.bonuses = [];
    this.test1.lastSpawn = this.time;
    this.test1.playerHand = { x: 200, y: 350 };
    this.test1.girlHand = { x: 420, y: 220, targetX: 420, targetY: 220, vx: 0, vy: 0 };

    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-hud">
        <div class="test-header">
          <span class="test-badge">ТЕСТ 1 ИЗ 3</span>
          <span class="test-title">Держание за руки</span>
        </div>
        <div class="warmth-bar-container">
          <div class="warmth-label">Шкала тепла и нежности: <strong id="warmth-text">0%</strong></div>
          <div class="warmth-track">
            <div class="warmth-fill" id="warmth-fill" style="width: 0%"></div>
          </div>
        </div>
      </div>
      <div class="test-hint" id="test1-hint">
        🤝 Двигай мышкой / пальцем — протяни руку навстречу её ладошке и не отпускай!
      </div>
      <div class="milestone-bubble" id="milestone-bubble"></div>
    `;
  }

  updateTest1(dt) {
    const t1 = this.test1;
    const herName = configManager.get('herName');

    // Girl hand gentle wandering motion
    if (!t1.isHolding) {
      if (Math.random() < 0.02) {
        t1.girlHand.targetX = 180 + Math.random() * 320;
        t1.girlHand.targetY = 160 + Math.random() * 160;
      }
      t1.girlHand.x += (t1.girlHand.targetX - t1.girlHand.x) * (dt * 2.5);
      t1.girlHand.y += (t1.girlHand.targetY - t1.girlHand.y) * (dt * 2.5);
    } else {
      // Girl hand softly follows boyfriend hand with gentle lag
      t1.girlHand.x += (t1.playerHand.x + 12 - t1.girlHand.x) * (dt * 12);
      t1.girlHand.y += (t1.playerHand.y - 12 - t1.girlHand.y) * (dt * 12);
    }

    // Distance check for holding
    const dist = Math.hypot(t1.playerHand.x - t1.girlHand.x, t1.playerHand.y - t1.girlHand.y);
    const wasHolding = t1.isHolding;
    t1.isHolding = dist < 50;

    if (t1.isHolding && !wasHolding) {
      soundEngine.playHandConnect();
      const hint = document.getElementById('test1-hint');
      if (hint) hint.innerHTML = '❤️ Ладошки соединились! Держи крепко...';
    }

    // Warmth accumulation while holding
    if (t1.isHolding) {
      t1.warmth = Math.min(100, t1.warmth + dt * 14); // ~7 seconds to fill
      // Floating warmth updates
      const fill = document.getElementById('warmth-fill');
      const text = document.getElementById('warmth-text');
      if (fill) fill.style.width = `${t1.warmth}%`;
      if (text) text.textContent = `${Math.floor(t1.warmth)}%`;

      // Milestones check
      this.checkMilestones(t1.warmth);
    }

    // Spawn obstacles and bonuses
    if (this.time - t1.lastSpawn > 2.2) {
      t1.lastSpawn = this.time;
      if (Math.random() < 0.6) {
        // Spawn obstacle (cold wind, work call, alarm)
        const obsTypes = [
          { name: 'Холод', icon: '💨', radius: 24 },
          { name: 'Звонок', icon: '📱', radius: 24 },
          { name: 'Будильник', icon: '⏰', radius: 24 }
        ];
        const pick = obsTypes[Math.floor(Math.random() * obsTypes.length)];
        t1.obstacles.push({
          id: Math.random(),
          ...pick,
          x: Math.random() < 0.5 ? -30 : 670,
          y: 120 + Math.random() * 220,
          vx: (Math.random() < 0.5 ? 1 : -1) * (50 + Math.random() * 40)
        });
      } else {
        // Spawn bonus (hot latte, croissant, kitty)
        const bonusTypes = [
          { name: 'Латте +15%', icon: '☕', radius: 26, value: 15 },
          { name: 'Круассан +15%', icon: '🥐', radius: 26, value: 15 },
          { name: 'Котик +20%', icon: '🐱', radius: 28, value: 20 }
        ];
        const pick = bonusTypes[Math.floor(Math.random() * bonusTypes.length)];
        t1.bonuses.push({
          id: Math.random(),
          ...pick,
          x: Math.random() < 0.5 ? -30 : 670,
          y: 120 + Math.random() * 220,
          vx: (Math.random() < 0.5 ? 1 : -1) * (45 + Math.random() * 35)
        });
      }
    }

    // Update obstacles
    for (let i = t1.obstacles.length - 1; i >= 0; i--) {
      const obs = t1.obstacles[i];
      obs.x += obs.vx * dt;

      // Collision with hands
      const dBoy = Math.hypot(obs.x - t1.playerHand.x, obs.y - t1.playerHand.y);
      const dGirl = Math.hypot(obs.x - t1.girlHand.x, obs.y - t1.girlHand.y);

      if (dBoy < obs.radius + 20 || dGirl < obs.radius + 20) {
        soundEngine.playColdShiver();
        t1.warmth = Math.max(0, t1.warmth - 8);
        t1.isHolding = false;
        t1.obstacles.splice(i, 1);

        const bubble = document.getElementById('milestone-bubble');
        if (bubble) {
          bubble.innerHTML = `🥶 Брр! ${obs.name} помешал... Согрей её ладошки снова!`;
          bubble.classList.add('visible');
          setTimeout(() => bubble.classList.remove('visible'), 2000);
        }
        continue;
      }

      if (obs.x < -60 || obs.x > 700) {
        t1.obstacles.splice(i, 1);
      }
    }

    // Update bonuses
    for (let i = t1.bonuses.length - 1; i >= 0; i--) {
      const b = t1.bonuses[i];
      b.x += b.vx * dt;

      const dBoy = Math.hypot(b.x - t1.playerHand.x, b.y - t1.playerHand.y);
      const dGirl = Math.hypot(b.x - t1.girlHand.x, b.y - t1.girlHand.y);

      if (dBoy < b.radius + 25 || dGirl < b.radius + 25) {
        soundEngine.playSparkle();
        t1.warmth = Math.min(100, t1.warmth + b.value);
        t1.bonuses.splice(i, 1);

        const bubble = document.getElementById('milestone-bubble');
        if (bubble) {
          bubble.innerHTML = `✨ Вкусняшка на свидании! ${b.name} согревает вас обоих!`;
          bubble.classList.add('visible');
          setTimeout(() => bubble.classList.remove('visible'), 2200);
        }
        continue;
      }

      if (b.x < -60 || b.x > 700) {
        t1.bonuses.splice(i, 1);
      }
    }

    // Win condition for Test 1
    if (t1.warmth >= 100 && !t1.milestones[100]) {
      t1.milestones[100] = true;
      this.completeTest1();
    }
  }

  checkMilestones(warmth) {
    const t1 = this.test1;
    const herName = configManager.get('herName');
    const bubble = document.getElementById('milestone-bubble');

    const thoughts = {
      25: `Помнишь, как в самый первый раз я взял тебя за руку? Сердце колотилось как безумное...`,
      50: `Твоя ладошка так идеально помещается в моей. Словно они были созданы друг для друга.`,
      75: `Когда мы держимся за руки, любой мороз и любые тревоги отступают.`
    };

    for (const [lvl, text] of Object.entries(thoughts)) {
      const n = parseInt(lvl);
      if (warmth >= n && !t1.milestones[n]) {
        t1.milestones[n] = true;
        soundEngine.playSparkle();
        if (bubble) {
          bubble.innerHTML = `💭 <em>«${text}»</em>`;
          bubble.classList.add('visible');
          setTimeout(() => bubble.classList.remove('visible'), 4000);
        }
      }
    }
  }

  completeTest1() {
    this.desktop.unlockAchievement('hand_warmth', 'Рука об руку', 'Набрать 100% тепла в тесте на держание за руки', '🤝');
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-cleared-modal">
        <div class="cleared-header">✨ ТЕСТ 1 ПРОЙДЕН С ОТЛИЧИЕМ! ✨</div>
        <div class="cleared-score">ТЕПЛО ЛАДОНЕЙ: 100%</div>
        <div class="cleared-verdict">
          Вердикт: Ваши руки созданы друг для друга.<br>
          «Мне никогда не хочется отпускать твою руку...»
        </div>
        <button class="choice-btn primary" id="btn-next-test2">👗 Переходим к Тесту 2: Гардероб свидания</button>
      </div>
    `;

    document.getElementById('btn-next-test2')?.addEventListener('click', () => {
      soundEngine.playSparkle();
      this.startTest2();
    });
  }

  // ==========================================
  // TEST 2: OUTFIT / DRESS-UP MINIGAME
  // ==========================================
  startTest2() {
    this.state = 'test2';
    soundEngine.playMusic('dress');
    this.test2.round = 0;
    this.test2.completedRounds = 0;
    this.test2.selections = { top: null, bottom: null, accessory: null };
    this.renderTest2Round();
  }

  renderTest2Round() {
    const herName = configManager.get('herName');
    const round = this.test2.round;
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    const roundData = [
      {
        theme: 'Уютный вечер дома с фильмом и пиццей',
        prompt: `Сегодня мы остаёмся дома! Хочу быть максимально уютной, мягкой и тискательной. Что мне надеть?`,
        outfitKey: 'hoodie',
        sec1: '1. Верхняя одежда:',
        sec2: '2. Уют для ножек:',
        sec3: '3. Вкусности и комфорт:',
        tops: [
          { id: 'hoodie', name: 'Оверсайз худи с кошачьими ушками', correct: true, icon: '🐱' },
          { id: 'suit', name: 'Строгий офисный пиджак', correct: false, icon: '💼', comment: 'В пиджаке на диване? Ты хочешь обсудить квартальный отчёт? 😂' },
          { id: 'scuba', name: 'Водолазный костюм', correct: false, icon: '🤿', comment: 'В этом будет жарковато есть пиццу, любимый! 🤣' }
        ],
        bottoms: [
          { id: 'socks', name: 'Пушистые носочки с лапками', correct: true, icon: '🧦' },
          { id: 'heels', name: 'Туфли на 12-см шпильках', correct: false, icon: '👠', comment: 'Шпильки в постель? Ноги же отвалятся! 😅' },
          { id: 'flippers', name: 'Пляжные ласты', correct: false, icon: '🏊', comment: 'Я в них даже до кухни не дойду! 😆' }
        ],
        accessories: [
          { id: 'cocoa', name: 'Мягкая повязка и кружка какао', correct: true, icon: '☕' },
          { id: 'briefcase', name: 'Кожаный дипломат', correct: false, icon: '📂', comment: 'С дипломатом под плед? Смешно!' },
          { id: 'helmet', name: 'Мотоциклетный шлем', correct: false, icon: '🪖', comment: 'Как я буду целовать тебя через шлем?' }
        ]
      },
      {
        theme: 'Романтическая вечерняя прогулка под фонарями',
        prompt: `На улице горят фонари и прохладный ветерок. Хочу нежный, романтичный образ и тёплый шарф!`,
        outfitKey: 'coat',
        sec1: '1. Пальто / Верх:',
        sec2: '2. Шарф и тепло:',
        sec3: '3. Головной убор:',
        tops: [
          { id: 'coat', name: 'Нежное пальто пыльной розы', correct: true, icon: '🧥' },
          { id: 'tracksuit', name: 'Спортивный костюм с лампасами', correct: false, icon: '🏃', comment: 'На свидание как на пробежку? Ну уж нет!' },
          { id: 'sundress', name: 'Лёгкий летний сарафан', correct: false, icon: '👗', comment: 'Я же замёрзну за две минуты! Согревать устанешь!' }
        ],
        bottoms: [
          { id: 'scarf', name: 'Мягкий вязаный шарф', correct: true, icon: '🧣' },
          { id: 'fan_scarf', name: 'Футбольный шарф «Спартак»', correct: false, icon: '⚽', comment: 'Оле-оле? Мы вроде не на стадион идём 😜' },
          { id: 'garland', name: 'Новогодняя гирлянда', correct: false, icon: '💡', comment: 'Светиться красиво, но провода мешают!' }
        ],
        accessories: [
          { id: 'beret', name: 'Французский берет', correct: true, icon: '👒' },
          { id: 'panama', name: 'Панамка с пальмами', correct: false, icon: '🏖️', comment: 'Осенью в панамке? Ты шутник!' },
          { id: 'tiara', name: 'Тяжёлая корона', correct: false, icon: '👑', comment: 'Корона это мило, но шея устанет гулять!' }
        ]
      },
      {
        theme: 'Наш особенный праздничный вечер',
        prompt: `Сегодня наш особенный вечер... Хочу надеть что-то невероятно красивое, чтобы ты смотрел только на меня!`,
        outfitKey: 'dress',
        sec1: '1. Праздничный наряд:',
        sec2: '2. Нежные украшения:',
        sec3: '3. Обувь для свидания:',
        tops: [
          { id: 'dress', name: 'Вечернее платье со звёздным отливом', correct: true, icon: '✨' },
          { id: 'pajamas', name: 'Пижама в горошек', correct: false, icon: '💤', comment: 'Пижама любимая, но в ресторан в ней не пустят!' },
          { id: 'raincoat', name: 'Брезентовый дождевик', correct: false, icon: '☔', comment: 'Я что, иду на рыбалку? 😂' }
        ],
        bottoms: [
          { id: 'necklace', name: 'Тонкая подвеска с сердечком', correct: true, icon: '💎' },
          { id: 'chain', name: 'Массивная рэперская цепь', correct: false, icon: '⛓️', comment: 'Йоу! Но под платье не очень подходит 😅' },
          { id: 'calculator', name: 'Часы с калькулятором', correct: false, icon: '⌚', comment: 'Считать сумму счёта будем? Романтика!' }
        ],
        accessories: [
          { id: 'heels', name: 'Изящные туфельки', correct: true, icon: '👠' },
          { id: 'slippers', name: 'Домашние тапочки-зайчики', correct: false, icon: '🐰', comment: 'Зайчики милые, но к платью не очень!' },
          { id: 'boots', name: 'Тяжёлые берцы', correct: false, icon: '🥾', comment: 'Берцы крутые, но платье порвут!' }
        ]
      }
    ];

    const current = roundData[round];
    this.test2.currentRoundData = current;
    this.test2.selections = { top: null, bottom: null, accessory: null };

    ui.innerHTML = `
      <div class="test-hud">
        <div class="test-header">
          <span class="test-badge">ТЕСТ 2 ИЗ 3 • РАУНД ${round + 1}/3</span>
          <span class="test-title">${current.theme}</span>
        </div>
      </div>
      <div class="dressing-room-layout">
        <div class="girl-mirror-view" id="girl-mirror-view">
          <div class="mirror-portrait-card">
            <img src="assets/characters/girlfriend_pixel.png" class="mirror-sprite-img" alt="Примерочная">
          </div>
        </div>
        <div class="wardrobe-panel">
          <div class="girl-speech-bubble">
            💬 «${current.prompt}»
          </div>

          <div class="wardrobe-section">
            <div class="section-title">${current.sec1 || '1. Верхняя одежда:'}</div>
            <div class="item-grid" id="grid-tops">
              ${current.tops.map(t => `
                <button class="wardrobe-btn" data-type="top" data-id="${t.id}">
                  <span class="item-icon">${t.icon}</span>
                  <span class="item-name">${t.name}</span>
                </button>
              `).join('')}
            </div>
          </div>

          <div class="wardrobe-section">
            <div class="section-title">${current.sec2 || '2. Детали / Тепло:'}</div>
            <div class="item-grid" id="grid-bottoms">
              ${current.bottoms.map(b => `
                <button class="wardrobe-btn" data-type="bottom" data-id="${b.id}">
                  <span class="item-icon">${b.icon}</span>
                  <span class="item-name">${b.name}</span>
                </button>
              `).join('')}
            </div>
          </div>

          <div class="wardrobe-section">
            <div class="section-title">${current.sec3 || '3. Обувь и аксессуары:'}</div>
            <div class="item-grid" id="grid-acc">
              ${current.accessories.map(a => `
                <button class="wardrobe-btn" data-type="accessory" data-id="${a.id}">
                  <span class="item-icon">${a.icon}</span>
                  <span class="item-name">${a.name}</span>
                </button>
              `).join('')}
            </div>
          </div>

          <div class="tryout-feedback" id="tryout-feedback"></div>
          <button class="choice-btn primary" id="btn-confirm-outfit" style="display:none">💖 Готово! Мне очень нравится!</button>
        </div>
      </div>
    `;

    // Hook wardrobe buttons
    ui.querySelectorAll('.wardrobe-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        soundEngine.playSparkle();
        const type = btn.getAttribute('data-type');
        const id = btn.getAttribute('data-id');

        // Toggle selected state in group
        const group = btn.parentElement;
        group.querySelectorAll('.wardrobe-btn').forEach(b => b.classList.remove('selected'));
        btn.classList.add('selected');

        this.test2.selections[type] = id;
        this.checkOutfitMatch(current);
      });
    });

    document.getElementById('btn-confirm-outfit')?.addEventListener('click', () => {
      soundEngine.playAchievement();
      this.test2.round++;
      if (this.test2.round < 3) {
        this.renderTest2Round();
      } else {
        this.completeTest2();
      }
    });
  }

  checkOutfitMatch(current) {
    const sel = this.test2.selections;
    const feedback = document.getElementById('tryout-feedback');
    const confirmBtn = document.getElementById('btn-confirm-outfit');
    if (!sel.top || !sel.bottom || !sel.accessory) return;

    // Check correctness
    const topItem = current.tops.find(t => t.id === sel.top);
    const bottomItem = current.bottoms.find(b => b.id === sel.bottom);
    const accItem = current.accessories.find(a => a.id === sel.accessory);

    const isAllCorrect = topItem?.correct && bottomItem?.correct && accItem?.correct;

    if (isAllCorrect) {
      soundEngine.playSparkle();
      if (feedback) {
        feedback.className = 'tryout-feedback success';
        feedback.innerHTML = `🌸 <strong>В точку!</strong> Ты знаешь мой вкус лучше, чем я сама! Выглядит потрясающе!`;
      }
      if (confirmBtn) confirmBtn.style.display = 'block';
    } else {
      // Find what's funny
      const wrong = [topItem, bottomItem, accItem].find(x => x && !x.correct);
      if (feedback) {
        feedback.className = 'tryout-feedback warning';
        feedback.innerHTML = `😄 «${wrong?.comment || 'Что-то тут не сходится, давай попробуем другое!'}»`;
      }
      if (confirmBtn) confirmBtn.style.display = 'none';
    }
  }

  completeTest2() {
    this.desktop.unlockAchievement('fashion_guru', 'Модный эксперт её сердца', 'Подобрать идеальные наряды для всех свиданий', '👗');
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-cleared-modal">
        <div class="cleared-header">✨ ТЕСТ 2 ПРОЙДЕН С ОТЛИЧИЕМ! ✨</div>
        <div class="cleared-score">ЗНАНИЕ ЕЁ СТИЛЯ: 100%</div>
        <div class="cleared-verdict">
          Вердикт: Парень года!<br>
          «Ты заставляешь меня чувствовать себя самой красивой девушкой на свете...»
        </div>
        <button class="choice-btn primary" id="btn-next-test3">💓 Переходим к финальному Тесту 3: Синхронизация сердец</button>
      </div>
    `;

    document.getElementById('btn-next-test3')?.addEventListener('click', () => {
      soundEngine.playSparkle();
      this.startTest3();
    });
  }

  // ==========================================
  // TEST 3: HEART RHYTHM / SYNC MINIGAME
  // ==========================================
  startTest3() {
    this.state = 'test3';
    soundEngine.playMusic('heart');
    this.test3.syncScore = 0;
    this.test3.stage = 1;
    this.test3.beats = [];
    this.test3.lastBeatTime = this.time;
    this.test3.hitsInRow = 0;
    this.test3.bpm = 72;

    const herName = configManager.get('herName');
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-hud">
        <div class="test-header">
          <span class="test-badge">ТЕСТ 3 ИЗ 3 • ФИНАЛ</span>
          <span class="test-title">Синхронизация сердец</span>
        </div>
        <div class="warmth-bar-container">
          <div class="warmth-label">Уровень гармонии пульса: <strong id="sync-text">0%</strong></div>
          <div class="warmth-track">
            <div class="warmth-fill heart-fill" id="sync-fill" style="width: 0%"></div>
          </div>
        </div>
      </div>
      <div class="test-hint" id="test3-hint">
        💓 Нажимай <strong>ПРОБЕЛ</strong> или <strong>КЛИКАЙ</strong>, когда сердечки сходятся в центре круга!
      </div>
      <div class="rhythm-feedback" id="rhythm-feedback"></div>
      <div class="narrative-stage-box" id="stage-box">
        «В тот день, когда мы только встретились... моё сердце забилось совсем иначе.»
      </div>
    `;
  }

  updateTest3(dt) {
    const t3 = this.test3;
    const beatInterval = 60 / t3.bpm;

    // Spawn beats travelling inwards
    if (this.time - t3.lastBeatTime > beatInterval) {
      t3.lastBeatTime = this.time;
      t3.beats.push({
        id: Math.random(),
        leftX: 40,
        rightX: 600,
        speed: (320 - 40) / (beatInterval * 1.5)
      });
    }

    // Move beats
    for (let i = t3.beats.length - 1; i >= 0; i--) {
      const b = t3.beats[i];
      b.leftX += b.speed * dt;
      b.rightX -= b.speed * dt;

      // Auto miss if passed center without hit
      if (b.leftX > 370) {
        t3.beats.splice(i, 1);
        t3.hitsInRow = 0;
      }
    }

    // Narrative stage progression
    const stageBox = document.getElementById('stage-box');
    if (t3.syncScore >= 35 && t3.stage === 1) {
      t3.stage = 2;
      t3.bpm = 85;
      soundEngine.playSparkle();
      if (stageBox) {
        stageBox.innerHTML = `«Каждый вечер с тобой... каждая твоя шутка... моё сердце привыкало к твоему теплу.»`;
      }
    } else if (t3.syncScore >= 70 && t3.stage === 2) {
      t3.stage = 3;
      t3.bpm = 98;
      soundEngine.playSparkle();
      if (stageBox) {
        stageBox.innerHTML = `«И теперь... два сердца бьются в одном ритме. Навсегда.»`;
      }
    }
  }

  triggerHeartHit() {
    if (this.state !== 'test3') return;
    const t3 = this.test3;
    const centerX = 320;

    // Find closest beat to center
    let closest = null;
    let minDiff = 999;
    let closestIdx = -1;

    t3.beats.forEach((b, idx) => {
      const diff = Math.abs(b.leftX - centerX);
      if (diff < minDiff) {
        minDiff = diff;
        closest = b;
        closestIdx = idx;
      }
    });

    const feedback = document.getElementById('rhythm-feedback');

    if (closest && minDiff < 45) {
      // Hit!
      const isPerfect = minDiff < 18;
      soundEngine.playHit(isPerfect);
      t3.hitsInRow++;
      const gain = isPerfect ? 9 : 5;
      t3.syncScore = Math.min(100, t3.syncScore + gain);

      if (feedback) {
        feedback.textContent = isPerfect ? '💖 ИДЕАЛЬНО! В УНИСОН!' : '✨ ОТЛИЧНО!';
        feedback.className = `rhythm-feedback ${isPerfect ? 'perfect' : 'good'}`;
        feedback.style.opacity = '1';
        setTimeout(() => { if (feedback) feedback.style.opacity = '0'; }, 500);
      }

      t3.beats.splice(closestIdx, 1);

      // Update UI
      const fill = document.getElementById('sync-fill');
      const text = document.getElementById('sync-text');
      if (fill) fill.style.width = `${t3.syncScore}%`;
      if (text) text.textContent = `${Math.floor(t3.syncScore)}%`;

      if (t3.syncScore >= 100) {
        this.completeTest3();
      }
    } else {
      // Miss click
      soundEngine.playColdShiver();
      t3.hitsInRow = 0;
      if (feedback) {
        feedback.textContent = '💔 МИМО';
        feedback.className = 'rhythm-feedback miss';
        feedback.style.opacity = '1';
        setTimeout(() => { if (feedback) feedback.style.opacity = '0'; }, 400);
      }
    }
  }

  completeTest3() {
    this.desktop.unlockAchievement('heart_sync', 'В унисон', 'Достичь 100% гармонии сердец в тесте ритма', '💓');
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-cleared-modal">
        <div class="cleared-header">✨ СИНХРОНИЗАЦИЯ 100%: ПОЛНАЯ ГАРМОНИЯ! ✨</div>
        <div class="cleared-score">ДВА СЕРДЦА = ОДИН РИТМ</div>
        <div class="cleared-verdict">
          Все 3 теста успешно пройдены.<br>
          Запуск протокола финального признания...
        </div>
        <button class="choice-btn primary" id="btn-go-finale">💌 Открыть главное сообщение</button>
      </div>
    `;

    document.getElementById('btn-go-finale')?.addEventListener('click', () => {
      soundEngine.playSparkle();
      this.startFinale();
    });
  }

  // ==========================================
  // CLIMAX & FINALE: "RETURN TRUE;"
  // ==========================================
  startFinale() {
    this.state = 'ending';
    soundEngine.playMusic('finale');
    const herName = configManager.get('herName');
    const hisName = configManager.get('hisName');
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="finale-container">
        <div class="finale-terminal-header">
          <div class="term-title">LOVE_TERMINAL // RESULT_SUMMARY</div>
          <div class="term-stats">
            <div>> Тест 1 (Держание за руки): [ 100% PASS ]</div>
            <div>> Тест 2 (Понимание вкуса):  [ 100% PASS ]</div>
            <div>> Тест 3 (Синхрон пульса):   [ 100% PASS ]</div>
            <div>> СОВМЕСТИМОСТЬ: ∞% (БЕСКОНЕЧНОСТЬ)</div>
          </div>
        </div>

        <div class="letter-scroll-area">
          <div class="love-letter-paper">
            <div class="finale-couple-banner">
              <img src="assets/characters/couple_pixel.png" class="finale-couple-img" alt="Мы вместе">
            </div>
            <div class="letter-to">Моей любимой ${herName},</div>
            <div class="letter-body">
              Когда я садился делать эту игру, я вдохновлялся историей о тестах любви.<br><br>
              Но знаешь, в чём главное отличие той игры от нашей жизни?<br>
              В той игре парень сомневался и искал ответ.<br>
              А нам этот ответ уже известен. <strong>Мы встречаемся, и я люблю тебя.</strong><br><br>
              Каждый день рядом с тобой — это моё самое любимое приключение.<br>
              Спасибо за твой звонкий смех, за твои тёплые руки в моих карманах, за то, как ты морщишь носик, и за то, как ты обнимаешь меня во сне.<br><br>
              Я написал эту игру не просто ради кода.<br>
              Я написал её, чтобы ещё раз сказать тебе самые важные слова:
            </div>

            <div class="code-confession-block">
              <pre><code><span class="kw">function</span> <span class="fn">ourLoveStory</span>() {
    <span class="kw">while</span> (<span class="bool">true</span>) {
        <span class="call">cherish</span>(<span class="str">"${herName}"</span>);
        <span class="call">hold_hands</span>();
        <span class="call">make_happy</span>();
    }
    <span class="kw">return true</span>; <span class="cm">// Бесконечная любовь</span>
}

<span class="call">print</span>(<span class="str">"Я ЛЮБЛЮ ТЕБЯ, ${herName.toUpperCase()}! ❤️"</span>);</code></pre>
            </div>

            <div class="interactive-responses">
              <div class="resp-title">Выбери свой ответ ${hisName}:</div>
              <div class="resp-buttons">
                <button class="choice-btn primary finale-btn" data-reply="hug">🫂 Крепко обнять любимого разработчика</button>
                <button class="choice-btn primary finale-btn" data-reply="love">💖 Я тоже люблю тебя больше всего на свете!</button>
                <button class="choice-btn primary finale-btn" data-reply="kiss">💋 Поцеловать прямо сейчас</button>
                <button class="choice-btn primary finale-btn" data-reply="forever">✨ Быть с тобой навсегда</button>
              </div>
            </div>

            <div class="post-reply-box" id="post-reply-box" style="display:none">
              <div class="infinity-seal">
                <div class="seal-icon">💍</div>
                <div class="seal-text">ВЕЧНЫЙ ЦИКЛ СЧАСТЬЯ ЗАПУЩЕН</div>
              </div>
              <div class="post-reply-note">
                🌸 Теперь на твоём компьютере навсегда останется эта игра. Ты можешь в любой момент открыть Корзину с черновиками, почитать записки с причинами любви или пересмотреть наш фотоальбом!
              </div>
            </div>
          </div>
        </div>
      </div>
    `;

    ui.querySelectorAll('.finale-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        soundEngine.playAchievement();
        this.desktop.unlockAchievement('return_true', 'RETURN TRUE', 'Запустить вечный бесконечный цикл любви', '💍');
        const postBox = document.getElementById('post-reply-box');
        if (postBox) {
          postBox.style.display = 'block';
          postBox.scrollIntoView({ behavior: 'smooth' });
        }
        // Confetti effect
        this.triggerConfetti();
      });
    });
  }

  triggerConfetti() {
    // Burst of colorful heart particles
    const container = document.getElementById('game-viewport');
    if (!container) return;

    for (let i = 0; i < 40; i++) {
      const p = document.createElement('div');
      p.className = 'confetti-particle';
      p.textContent = ['❤️', '💖', '✨', '🌸', '💕', '🥰'][Math.floor(Math.random() * 6)];
      p.style.left = `${Math.random() * 90 + 5}%`;
      p.style.top = `${Math.random() * 80 + 10}%`;
      p.style.fontSize = `${16 + Math.random() * 24}px`;
      p.style.animation = `floatUpAndFade ${2 + Math.random() * 2}s forwards`;
      container.appendChild(p);
      setTimeout(() => p.remove(), 4000);
    }
  }

  // --- GENERAL UPDATE & RENDER ---
  update(dt) {
    if (this.state === 'test1') this.updateTest1(dt);
    if (this.state === 'test3') this.updateTest3(dt);
  }

  render() {
    if (!this.ctx || !this.canvas) return;
    const w = this.canvas.width;
    const h = this.canvas.height;

    if (this.state === 'test1') {
      const t1 = this.test1;
      art.drawHandHoldingScene(
        this.ctx, w, h,
        t1.playerHand, t1.girlHand,
        t1.isHolding, t1.warmth,
        t1.obstacles, t1.bonuses,
        this.time
      );
    } else if (this.state === 'test2') {
      this.ctx.clearRect(0, 0, w, h);
      this.ctx.fillStyle = PALETTE.bgLight;
      this.ctx.fillRect(0, 0, w, h);

      // Draw cozy fitting room mirror scene
      const outfitKey = this.test2.currentRoundData?.outfitKey || 'hoodie';
      art.drawGirlfriend(this.ctx, 160, 240, 190, 'happy', outfitKey, this.time);
      art.drawBoyfriend(this.ctx, 480, 260, 180, this.time);
    } else if (this.state === 'test3') {
      const t3 = this.test3;
      art.drawHeartbeatMonitor(this.ctx, w, h, t3.beats, t3.syncScore, t3.stage, this.time);
    } else if (this.state === 'intro_check' || this.state === 'boot') {
      this.ctx.clearRect(0, 0, w, h);
      this.ctx.fillStyle = PALETTE.bgLight;
      this.ctx.fillRect(0, 0, w, h);
      // Gentle idle girlfriend & boyfriend
      art.drawGirlfriend(this.ctx, 220, 230, 180, 'idle', 'hoodie', this.time);
      art.drawBoyfriend(this.ctx, 420, 240, 180, this.time);
    } else {
      this.ctx.clearRect(0, 0, w, h);
      this.ctx.fillStyle = PALETTE.bgLight;
      this.ctx.fillRect(0, 0, w, h);
      art.drawGirlfriend(this.ctx, 320, 240, 190, 'holding_hands', 'dress', this.time);
    }
  }
}
