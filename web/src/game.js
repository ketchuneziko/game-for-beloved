// Main Game Engine for "Print I Love You: For My Beloved"
// 100% Pixel Art Aesthetic with Hand-Holding, Stargazing Star Catcher, and Heart Rhythm Sync

import { soundEngine } from './audio.js';
import { art, PALETTE } from './art.js';
import { configManager } from './config.js';

export class GameEngine {
  constructor(desktopManager) {
    this.desktop = desktopManager;
    window.game = this;
    this.state = 'boot'; // boot, intro_check, story_intro, test1, test2, test3, ending
    this.canvas = document.getElementById('game-canvas');
    this.ctx = this.canvas ? this.canvas.getContext('2d') : null;

    this.noAttempts = 0;
    this.time = 0;
    this.animId = null;

    // Test 1: Hand Holding
    this.test1 = {
      playerHand: { x: 200, y: 350 },
      girlHand: { x: 420, y: 220, targetX: 420, targetY: 220 },
      isHolding: false,
      warmth: 0,
      milestones: { 25: false, 50: false, 75: false, 100: false },
      obstacles: [],
      bonuses: [],
      lastSpawn: 0
    };

    // Test 2: Stargazing Star Catcher (NEW romantic game!)
    this.test2 = {
      catcher: { x: 320, y: 360, width: 64, height: 26 },
      stars: [],
      constellation: [],
      starEnergy: 0,
      lastSpawn: 0,
      caughtWishes: []
    };

    // Test 3: Heart Rhythm Sync
    this.test3 = {
      beats: [],
      lastBeatTime: 0,
      syncScore: 0,
      stage: 1,
      bpm: 72,
      hitsInRow: 0
    };

    this.init();
  }

  init() {
    this.resizeCanvas();
    window.addEventListener('resize', () => this.resizeCanvas());

    // Mouse & Touch tracking for Test 1 (Hand Holding) and Test 2 (Star Catcher)
    if (this.canvas) {
      const handleMove = (e) => {
        const rect = this.canvas.getBoundingClientRect();
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        const scaleX = this.canvas.width / rect.width;
        const scaleY = this.canvas.height / rect.height;

        const mx = (clientX - rect.left) * scaleX;
        const my = (clientY - rect.top) * scaleY;

        if (this.state === 'test1') {
          this.test1.playerHand.x = mx;
          this.test1.playerHand.y = my;
        } else if (this.state === 'test2') {
          this.test2.catcher.x = Math.max(40, Math.min(600, mx));
        }
      };

      this.canvas.addEventListener('mousemove', handleMove);
      this.canvas.addEventListener('touchmove', handleMove, { passive: false });
    }

    // Keyboard controls for Star Catcher (Left/Right) & Rhythm (Space)
    window.addEventListener('keydown', (e) => {
      if (this.state === 'test2') {
        if (e.code === 'ArrowLeft' || e.code === 'KeyA') {
          this.test2.catcher.x = Math.max(40, this.test2.catcher.x - 24);
        } else if (e.code === 'ArrowRight' || e.code === 'KeyD') {
          this.test2.catcher.x = Math.min(600, this.test2.catcher.x + 24);
        }
      } else if (this.state === 'test3' && (e.code === 'Space' || e.code === 'Enter')) {
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

    // Start loop & boot
    this.startLoop();
    this.startBootSequence();
  }

  resizeCanvas() {
    if (!this.canvas) return;
    this.canvas.width = 640;
    this.canvas.height = 440;
    if (this.ctx) {
      this.ctx.imageSmoothingEnabled = false; // Pure crisp pixels!
    }
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

  // --- BOOT SEQUENCE ---
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
    }, 300);
    setTimeout(() => {
      document.getElementById('bline-2')?.classList.add('visible');
      soundEngine.playTypewriter();
    }, 800);
    setTimeout(() => {
      document.getElementById('bline-3')?.classList.add('visible');
      soundEngine.playTypewriter();
    }, 1300);
    setTimeout(() => {
      document.getElementById('bline-4')?.classList.add('visible');
      soundEngine.playTypewriter();
      setTimeout(() => this.showIdentityCheck(), 800);
    }, 1800);
  }

  // --- IDENTITY CHECK ---
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
            И всё же, я создал наши собственные романтические задания — чтобы напомнить, как сильно я ценю каждый наш миг.<br>
            Готова пройти их со мной?
          </div>
          <div class="dialogue-choices">
            <button class="choice-btn primary" id="btn-start-tests">🌸 Начать наше приключение!</button>
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
  // TEST 1: HAND-HOLDING
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
    this.test1.girlHand = { x: 420, y: 220, targetX: 420, targetY: 220 };

    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-hud">
        <div class="test-header">
          <span class="test-badge">ЗАДАНИЕ 1 ИЗ 3</span>
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
        🤝 Двигай мышкой / пальцем — протяни руку навстречу её ладошке и согрей!
      </div>
      <div class="milestone-bubble" id="milestone-bubble"></div>
    `;
  }

  updateTest1(dt) {
    const t1 = this.test1;

    if (!t1.isHolding) {
      if (Math.random() < 0.02) {
        t1.girlHand.targetX = 180 + Math.random() * 320;
        t1.girlHand.targetY = 160 + Math.random() * 160;
      }
      t1.girlHand.x += (t1.girlHand.targetX - t1.girlHand.x) * (dt * 2.5);
      t1.girlHand.y += (t1.girlHand.targetY - t1.girlHand.y) * (dt * 2.5);
    } else {
      t1.girlHand.x += (t1.playerHand.x + 12 - t1.girlHand.x) * (dt * 12);
      t1.girlHand.y += (t1.playerHand.y - 12 - t1.girlHand.y) * (dt * 12);
    }

    const dist = Math.hypot(t1.playerHand.x - t1.girlHand.x, t1.playerHand.y - t1.girlHand.y);
    const wasHolding = t1.isHolding;
    t1.isHolding = dist < 50;

    if (t1.isHolding && !wasHolding) {
      soundEngine.playHandConnect();
      const hint = document.getElementById('test1-hint');
      if (hint) hint.innerHTML = '❤️ Ладошки соединились! Держи крепко...';
    }

    if (t1.isHolding) {
      t1.warmth = Math.min(100, t1.warmth + dt * 14);
      const fill = document.getElementById('warmth-fill');
      const text = document.getElementById('warmth-text');
      if (fill) fill.style.width = `${t1.warmth}%`;
      if (text) text.textContent = `${Math.floor(t1.warmth)}%`;
      this.checkMilestones(t1.warmth);
    }

    // Spawn obstacles & treats
    if (this.time - t1.lastSpawn > 2.2) {
      t1.lastSpawn = this.time;
      if (Math.random() < 0.6) {
        const obsTypes = [
          { name: 'Холод', icon: '💨', radius: 22 },
          { name: 'Звонок', icon: '📱', radius: 22 },
          { name: 'Будильник', icon: '⏰', radius: 22 }
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
        const bonusTypes = [
          { name: 'Латте +15%', icon: '☕', radius: 24, value: 15 },
          { name: 'Круассан +15%', icon: '🥐', radius: 24, value: 15 },
          { name: 'Котик +20%', icon: '🐱', radius: 24, value: 20 }
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

    // Move obstacles
    for (let i = t1.obstacles.length - 1; i >= 0; i--) {
      const obs = t1.obstacles[i];
      obs.x += obs.vx * dt;
      const dBoy = Math.hypot(obs.x - t1.playerHand.x, obs.y - t1.playerHand.y);
      const dGirl = Math.hypot(obs.x - t1.girlHand.x, obs.y - t1.girlHand.y);

      if (dBoy < obs.radius + 20 || dGirl < obs.radius + 20) {
        soundEngine.playColdShiver();
        t1.warmth = Math.max(0, t1.warmth - 8);
        t1.isHolding = false;
        t1.obstacles.splice(i, 1);

        const bubble = document.getElementById('milestone-bubble');
        if (bubble) {
          bubble.innerHTML = `🥶 Брр! ${obs.name} помешал... Согрей её ручки снова!`;
          bubble.classList.add('visible');
          setTimeout(() => bubble.classList.remove('visible'), 2000);
        }
        continue;
      }
      if (obs.x < -60 || obs.x > 700) t1.obstacles.splice(i, 1);
    }

    // Move bonuses
    for (let i = t1.bonuses.length - 1; i >= 0; i--) {
      const b = t1.bonuses[i];
      b.x += b.vx * dt;
      const dBoy = Math.hypot(b.x - t1.playerHand.x, b.y - t1.playerHand.y);
      const dGirl = Math.hypot(b.x - t1.girlHand.x, b.y - t1.girlHand.y);

      if (dBoy < b.radius + 22 || dGirl < b.radius + 22) {
        soundEngine.playSparkle();
        t1.warmth = Math.min(100, t1.warmth + b.value);
        t1.bonuses.splice(i, 1);

        const bubble = document.getElementById('milestone-bubble');
        if (bubble) {
          bubble.innerHTML = `✨ ${b.name} согревает вас обоих!`;
          bubble.classList.add('visible');
          setTimeout(() => bubble.classList.remove('visible'), 2200);
        }
        continue;
      }
      if (b.x < -60 || b.x > 700) t1.bonuses.splice(i, 1);
    }

    if (t1.warmth >= 100 && !t1.milestones[100]) {
      t1.milestones[100] = true;
      this.completeTest1();
    }
  }

  checkMilestones(warmth) {
    const t1 = this.test1;
    const bubble = document.getElementById('milestone-bubble');
    const thoughts = {
      25: `Помнишь, как в самый первый раз я взял тебя за руку? Сердце колотилось как бешеное...`,
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
          setTimeout(() => bubble.classList.remove('visible'), 3500);
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
        <div class="cleared-header">✨ ЗАДАНИЕ 1 ВЫПОЛНЕНО! ✨</div>
        <div class="cleared-score">ТЕПЛО ЛАДОНЕЙ: 100%</div>
        <div class="cleared-verdict">
          Вердикт: Идеальное сцепление пальчиков.<br>
          «Мне никогда не хочется отпускать твою ладонь...»
        </div>
        <button class="choice-btn primary" id="btn-next-test2">🌟 Задание 2: Звёздное свидание на крыше</button>
      </div>
    `;

    document.getElementById('btn-next-test2')?.addEventListener('click', () => {
      soundEngine.playSparkle();
      this.startTest2();
    });
  }

  // ==========================================
  // NEW TEST 2: STARGAZING - CATCHING FALLING STARS
  // ==========================================
  startTest2() {
    this.state = 'test2';
    soundEngine.playMusic('dress'); // Cozy upbeat theme
    this.test2 = {
      catcher: { x: 320, y: 360, width: 64, height: 26 },
      stars: [],
      constellation: [],
      starEnergy: 0,
      lastSpawn: this.time,
      caughtWishes: []
    };

    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-hud">
        <div class="test-header">
          <span class="test-badge">ЗАДАНИЕ 2 ИЗ 3</span>
          <span class="test-title">Ловец падающих звёзд</span>
        </div>
        <div class="warmth-bar-container">
          <div class="warmth-label">Энергия созвездия любви: <strong id="star-text">0%</strong></div>
          <div class="warmth-track">
            <div class="warmth-fill" id="star-fill" style="width: 0%; background: linear-gradient(90deg, #ffd166, #ff6b8b)"></div>
          </div>
        </div>
      </div>
      <div class="test-hint" id="test2-hint">
        🌟 Двигай корзинку мышкой или стрелками [← / →] — лови падающие звёзды для любимой!
      </div>
      <div class="wish-banner" id="wish-banner"></div>
    `;
  }

  updateTest2(dt) {
    const t2 = this.test2;

    // Spawn falling stars
    if (this.time - t2.lastSpawn > 1.2 && t2.starEnergy < 100) {
      t2.lastSpawn = this.time;

      const wishes = [
        'Утренний кофе вместе',
        'Твои тёплые объятия',
        'Наши долгие разговоры',
        'Смеяться до слёз',
        'Путешествовать вдвоём',
        'Ты моё солнышко',
        'Люблю твою улыбку',
        'Всегда быть рядом',
        'Самая красивая'
      ];

      const starTypes = [
        { color: PALETTE.goldLight, size: 14, value: 10, type: 'gold' },
        { color: PALETTE.pinkMain, size: 16, value: 14, type: 'love' },
        { color: PALETTE.mint, size: 15, value: 12, type: 'sweet' },
        { color: '#FFD700', size: 18, value: 18, type: 'special' }
      ];

      const pick = starTypes[Math.floor(Math.random() * starTypes.length)];
      const wishText = wishes[Math.floor(Math.random() * wishes.length)];

      t2.stars.push({
        id: Math.random(),
        x: 40 + Math.random() * 560,
        y: -20,
        vy: 110 + Math.random() * 60,
        vx: (Math.random() - 0.5) * 30,
        wishText: wishText,
        ...pick
      });
    }

    // Move stars & check catch
    for (let i = t2.stars.length - 1; i >= 0; i--) {
      const s = t2.stars[i];
      s.y += s.vy * dt;
      s.x += s.vx * dt;

      // Catcher collision
      const inX = Math.abs(s.x - t2.catcher.x) < (t2.catcher.width / 2 + 10);
      const inY = Math.abs(s.y - t2.catcher.y) < (t2.catcher.height / 2 + 10);

      if (inX && inY) {
        soundEngine.playSparkle();
        t2.starEnergy = Math.min(100, t2.starEnergy + s.value);
        t2.caughtWishes.push(s.wishText);

        // Add to constellation vertices
        t2.constellation.push({
          x: s.x,
          y: Math.max(50, Math.min(220, s.y - 120))
        });

        // Show floating wish banner
        const banner = document.getElementById('wish-banner');
        if (banner) {
          banner.innerHTML = `🌟 <em>«${s.wishText}»</em>`;
          banner.className = 'wish-banner visible';
          setTimeout(() => { if (banner) banner.className = 'wish-banner'; }, 2200);
        }

        t2.stars.splice(i, 1);

        // Update HUD
        const fill = document.getElementById('star-fill');
        const text = document.getElementById('star-text');
        if (fill) fill.style.width = `${t2.starEnergy}%`;
        if (text) text.textContent = `${Math.floor(t2.starEnergy)}%`;

        if (t2.starEnergy >= 100) {
          this.completeTest2();
        }
        continue;
      }

      if (s.y > 450) {
        t2.stars.splice(i, 1);
      }
    }
  }

  completeTest2() {
    this.desktop.unlockAchievement('fashion_guru', 'Хранитель звёзд для неё', 'Поймать все звёзды и зажечь созвездие любви', '🌟');
    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-cleared-modal">
        <div class="cleared-header">✨ СОЗВЕЗДИЕ НАШЕЙ ЛЮБВИ ЗАЖЖЕНО! ✨</div>
        <div class="cleared-score">ЗВЁЗДНАЯ ЭНЕРГИЯ: 100%</div>
        <div class="cleared-verdict">
          Твоя девушка улыбается, глядя на звёздное небо:<br>
          «Ты поймал для меня целое небо... Но моё главное желание уже сбылось — я рядом с тобой ❤️»
        </div>
        <button class="choice-btn primary" id="btn-next-test3">💓 Задание 3: Синхронизация сердец</button>
      </div>
    `;

    document.getElementById('btn-next-test3')?.addEventListener('click', () => {
      soundEngine.playSparkle();
      this.startTest3();
    });
  }

  // ==========================================
  // TEST 3: HEART RHYTHM SYNC
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

    const ui = document.getElementById('game-ui-overlay');
    if (!ui) return;

    ui.innerHTML = `
      <div class="test-hud">
        <div class="test-header">
          <span class="test-badge">ЗАДАНИЕ 3 ИЗ 3 • ФИНАЛ</span>
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
        💓 Нажимай <strong>ПРОБЕЛ</strong> или <strong>КЛИКАЙ</strong>, когда сердечки сходятся в центре!
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

    if (this.time - t3.lastBeatTime > beatInterval) {
      t3.lastBeatTime = this.time;
      t3.beats.push({
        id: Math.random(),
        leftX: 40,
        rightX: 600,
        speed: (320 - 40) / (beatInterval * 1.5)
      });
    }

    for (let i = t3.beats.length - 1; i >= 0; i--) {
      const b = t3.beats[i];
      b.leftX += b.speed * dt;
      b.rightX -= b.speed * dt;

      if (b.leftX > 370) {
        t3.beats.splice(i, 1);
        t3.hitsInRow = 0;
      }
    }

    const stageBox = document.getElementById('stage-box');
    if (t3.syncScore >= 35 && t3.stage === 1) {
      t3.stage = 2;
      t3.bpm = 85;
      soundEngine.playSparkle();
      if (stageBox) stageBox.innerHTML = `«Каждый вечер с тобой... каждая твоя шутка... моё сердце согревалось твоим теплом.»`;
    } else if (t3.syncScore >= 70 && t3.stage === 2) {
      t3.stage = 3;
      t3.bpm = 98;
      soundEngine.playSparkle();
      if (stageBox) stageBox.innerHTML = `«И теперь... два сердца бьются в одном ритме. Навсегда.»`;
    }
  }

  triggerHeartHit() {
    if (this.state !== 'test3') return;
    const t3 = this.test3;
    const centerX = 320;

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
      const isPerfect = minDiff < 18;
      soundEngine.playHit(isPerfect);
      t3.hitsInRow++;
      const gain = isPerfect ? 9 : 5;
      t3.syncScore = Math.min(100, t3.syncScore + gain);

      if (feedback) {
        feedback.textContent = isPerfect ? '💖 В УНИСОН!' : '✨ ОТЛИЧНО!';
        feedback.className = `rhythm-feedback ${isPerfect ? 'perfect' : 'good'}`;
        feedback.style.opacity = '1';
        setTimeout(() => { if (feedback) feedback.style.opacity = '0'; }, 500);
      }

      t3.beats.splice(closestIdx, 1);

      const fill = document.getElementById('sync-fill');
      const text = document.getElementById('sync-text');
      if (fill) fill.style.width = `${t3.syncScore}%`;
      if (text) text.textContent = `${Math.floor(t3.syncScore)}%`;

      if (t3.syncScore >= 100) {
        this.completeTest3();
      }
    } else {
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
          Все 3 задания успешно пройдены.<br>
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
            <div>> Задание 1 (Держание за руки): [ 100% PASS ]</div>
            <div>> Задание 2 (Ловец звёзд):     [ 100% PASS ]</div>
            <div>> Задание 3 (Синхрон сердец):  [ 100% PASS ]</div>
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
        this.triggerConfetti();
      });
    });
  }

  triggerConfetti() {
    const container = document.getElementById('game-viewport');
    if (!container) return;

    for (let i = 0; i < 40; i++) {
      const p = document.createElement('div');
      p.className = 'confetti-particle';
      p.textContent = ['❤️', '💖', '✨', '🌸', '💕', '🥰'][Math.floor(Math.random() * 6)];
      p.style.left = `${Math.random() * 90 + 5}%`;
      p.style.top = `${Math.random() * 80 + 10}%`;
      p.style.fontSize = `${16 + Math.random() * 20}px`;
      p.style.animation = `floatUpAndFade ${2 + Math.random() * 2}s forwards`;
      container.appendChild(p);
      setTimeout(() => p.remove(), 4000);
    }
  }

  update(dt) {
    if (this.state === 'test1') this.updateTest1(dt);
    if (this.state === 'test2') this.updateTest2(dt);
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
      const t2 = this.test2;
      art.drawStarCatcherScene(
        this.ctx, w, h,
        t2.stars, t2.catcher,
        t2.constellation, t2.starEnergy,
        this.time
      );
    } else if (this.state === 'test3') {
      const t3 = this.test3;
      art.drawHeartbeatMonitor(this.ctx, w, h, t3.beats, t3.syncScore, t3.stage, this.time);
    } else {
      this.ctx.clearRect(0, 0, w, h);
      this.ctx.fillStyle = PALETTE.bgDark;
      this.ctx.fillRect(0, 0, w, h);
    }
  }
}
