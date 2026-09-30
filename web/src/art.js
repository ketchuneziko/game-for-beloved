// Procedural Vector / Pixel Doodle Art Renderer for "Print I Love You: For My Beloved"
// Hand-crafted chibi art and minigame visual elements matching Print I Love You's doodle aesthetic

export const PALETTE = {
  bgLight: '#FCF1F4',
  bgDark: '#1E1726',
  ink: '#2B1B33',
  inkLight: '#4D3658',
  pinkSoft: '#FFB8C6',
  pinkMain: '#FF6B8B',
  pinkDeep: '#E83E6E',
  cream: '#FFF9FA',
  gold: '#FFD166',
  purpleSoft: '#DDD2F2',
  mint: '#C7EFCF',
  iceBlue: '#A0D2EB',
  white: '#FFFFFF'
};

export class ArtRenderer {
  constructor() {}

  // --- CHIBI GIRLFRIEND SPRITE ---
  drawGirlfriend(ctx, x, y, size = 180, emotion = 'idle', outfit = 'hoodie', time = 0) {
    ctx.save();
    ctx.translate(x, y);

    const breathe = Math.sin(time * 3) * 2;
    const blushIntensity = (emotion === 'shy' || emotion === 'holding_hands') ? 1.0 : 0.6;

    // Body / Outfit
    ctx.fillStyle = outfit === 'dress' ? PALETTE.purpleSoft :
                    outfit === 'coat' ? PALETTE.pinkSoft :
                    PALETTE.cream;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    // Dress / Sweater shape
    ctx.beginPath();
    ctx.moveTo(-size * 0.22, size * 0.15 + breathe);
    ctx.lineTo(-size * 0.3, size * 0.6 + breathe);
    ctx.quadraticCurveTo(0, size * 0.68 + breathe, size * 0.3, size * 0.6 + breathe);
    ctx.lineTo(size * 0.22, size * 0.15 + breathe);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // Cute details on clothes
    if (outfit === 'hoodie') {
      // Little kitty face on hoodie
      ctx.fillStyle = PALETTE.pinkMain;
      ctx.beginPath();
      ctx.arc(0, size * 0.38 + breathe, 8, 0, Math.PI * 2);
      ctx.fill();
      // Whiskers
      ctx.strokeStyle = PALETTE.ink;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(-14, size * 0.38 + breathe); ctx.lineTo(-7, size * 0.38 + breathe);
      ctx.moveTo(7, size * 0.38 + breathe); ctx.lineTo(14, size * 0.38 + breathe);
      ctx.stroke();
    } else if (outfit === 'coat') {
      // Scarf
      ctx.fillStyle = PALETTE.pinkMain;
      ctx.strokeStyle = PALETTE.ink;
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.roundRect(-size * 0.2, size * 0.12 + breathe, size * 0.4, 22, 10);
      ctx.fill();
      ctx.stroke();
      // Scarf tails
      ctx.beginPath();
      ctx.rect(size * 0.05, size * 0.22 + breathe, 16, 32);
      ctx.fill();
      ctx.stroke();
    } else if (outfit === 'dress') {
      // Romantic ribbon / star
      ctx.fillStyle = PALETTE.gold;
      ctx.beginPath();
      ctx.arc(0, size * 0.25 + breathe, 6, 0, Math.PI * 2);
      ctx.fill();
    }

    // Hands / Sleeves
    ctx.fillStyle = outfit === 'coat' ? PALETTE.pinkSoft : PALETTE.cream;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2.5;

    if (emotion === 'shy') {
      // Hands held up to cheeks
      ctx.beginPath();
      ctx.arc(-size * 0.14, size * 0.1 + breathe, 12, 0, Math.PI * 2);
      ctx.arc(size * 0.14, size * 0.1 + breathe, 12, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    } else if (emotion === 'holding_hands') {
      // Arms reaching outward with warmth
      ctx.beginPath();
      ctx.ellipse(-size * 0.26, size * 0.3 + breathe, 16, 22, -0.4, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    } else {
      // Cute cozy sleeves
      ctx.beginPath();
      ctx.ellipse(-size * 0.24, size * 0.35 + breathe, 14, 24, -0.3, 0, Math.PI * 2);
      ctx.ellipse(size * 0.24, size * 0.35 + breathe, 14, 24, 0.3, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    }

    // Legs / cute socks
    ctx.fillStyle = PALETTE.cream;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.roundRect(-size * 0.15, size * 0.6 + breathe, 14, 30, 7);
    ctx.roundRect(size * 0.05, size * 0.6 + breathe, 14, 30, 7);
    ctx.fill();
    ctx.stroke();

    // Head
    ctx.fillStyle = PALETTE.cream;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.ellipse(0, -size * 0.12 + breathe * 0.5, size * 0.28, size * 0.25, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    // Cute ears on hoodie if hoodie outfit
    if (outfit === 'hoodie') {
      ctx.fillStyle = PALETTE.cream;
      ctx.strokeStyle = PALETTE.ink;
      ctx.lineWidth = 2.5;
      // Left ear
      ctx.beginPath();
      ctx.moveTo(-size * 0.24, -size * 0.28 + breathe * 0.5);
      ctx.lineTo(-size * 0.32, -size * 0.44 + breathe * 0.5);
      ctx.lineTo(-size * 0.14, -size * 0.34 + breathe * 0.5);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Right ear
      ctx.beginPath();
      ctx.moveTo(size * 0.24, -size * 0.28 + breathe * 0.5);
      ctx.lineTo(size * 0.32, -size * 0.44 + breathe * 0.5);
      ctx.lineTo(size * 0.14, -size * 0.34 + breathe * 0.5);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
    } else if (outfit === 'coat') {
      // French Beret
      ctx.fillStyle = PALETTE.ink;
      ctx.beginPath();
      ctx.ellipse(size * 0.05, -size * 0.32 + breathe * 0.5, size * 0.24, 14, -0.2, 0, Math.PI * 2);
      ctx.fill();
      ctx.beginPath();
      ctx.arc(size * 0.05, -size * 0.4 + breathe * 0.5, 4, 0, Math.PI * 2);
      ctx.fill();
    }

    // Hair
    ctx.fillStyle = PALETTE.inkLight;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2.5;
    // Hair bangs
    ctx.beginPath();
    ctx.arc(0, -size * 0.18 + breathe * 0.5, size * 0.26, Math.PI * 1.05, Math.PI * 1.95);
    ctx.quadraticCurveTo(-size * 0.15, -size * 0.08 + breathe * 0.5, -size * 0.26, -size * 0.02 + breathe * 0.5);
    ctx.quadraticCurveTo(-size * 0.1, -size * 0.12 + breathe * 0.5, 0, -size * 0.12 + breathe * 0.5);
    ctx.quadraticCurveTo(size * 0.1, -size * 0.12 + breathe * 0.5, size * 0.26, -size * 0.02 + breathe * 0.5);
    ctx.quadraticCurveTo(size * 0.15, -size * 0.08 + breathe * 0.5, 0, -size * 0.18 + breathe * 0.5);
    ctx.fill();
    ctx.stroke();

    // Twin side strands
    ctx.beginPath();
    ctx.ellipse(-size * 0.27, -size * 0.02 + breathe * 0.5, 8, 28, 0.2, 0, Math.PI * 2);
    ctx.ellipse(size * 0.27, -size * 0.02 + breathe * 0.5, 8, 28, -0.2, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    // Rosy Blush
    ctx.fillStyle = PALETTE.pinkMain;
    ctx.globalAlpha = blushIntensity;
    ctx.beginPath();
    ctx.ellipse(-size * 0.15, -size * 0.08 + breathe * 0.5, 9, 6, 0, 0, Math.PI * 2);
    ctx.ellipse(size * 0.15, -size * 0.08 + breathe * 0.5, 9, 6, 0, 0, Math.PI * 2);
    ctx.fill();
    // Diagonal blush strokes ///
    ctx.strokeStyle = PALETTE.pinkDeep;
    ctx.lineWidth = 1.5;
    for (let i = -1; i <= 1; i++) {
      ctx.beginPath();
      ctx.moveTo(-size * 0.15 + i * 3 - 3, -size * 0.08 + breathe * 0.5 - 3);
      ctx.lineTo(-size * 0.15 + i * 3 + 3, -size * 0.08 + breathe * 0.5 + 3);
      ctx.moveTo(size * 0.15 + i * 3 - 3, -size * 0.08 + breathe * 0.5 - 3);
      ctx.lineTo(size * 0.15 + i * 3 + 3, -size * 0.08 + breathe * 0.5 + 3);
      ctx.stroke();
    }
    ctx.globalAlpha = 1.0;

    // Eyes
    const isBlink = Math.sin(time * 1.5) > 0.96;
    ctx.fillStyle = PALETTE.ink;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2.5;

    if (isBlink || emotion === 'happy') {
      // Happy curved closed eyes ^‿^
      ctx.beginPath();
      ctx.arc(-size * 0.12, -size * 0.14 + breathe * 0.5, 8, Math.PI * 1.1, Math.PI * 1.9);
      ctx.arc(size * 0.12, -size * 0.14 + breathe * 0.5, 8, Math.PI * 1.1, Math.PI * 1.9);
      ctx.stroke();
    } else if (emotion === 'playful') {
      // One wink, one open
      ctx.beginPath();
      ctx.arc(-size * 0.12, -size * 0.14 + breathe * 0.5, 8, Math.PI * 1.1, Math.PI * 1.9);
      ctx.stroke();
      // Right eye open
      ctx.beginPath();
      ctx.arc(size * 0.12, -size * 0.14 + breathe * 0.5, 6, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = PALETTE.white;
      ctx.beginPath();
      ctx.arc(size * 0.12 - 2, -size * 0.14 + breathe * 0.5 - 2, 2.5, 0, Math.PI * 2);
      ctx.fill();
    } else {
      // Big cute shiny eyes
      ctx.beginPath();
      ctx.arc(-size * 0.12, -size * 0.14 + breathe * 0.5, 7, 0, Math.PI * 2);
      ctx.arc(size * 0.12, -size * 0.14 + breathe * 0.5, 7, 0, Math.PI * 2);
      ctx.fill();
      // Highlights
      ctx.fillStyle = PALETTE.white;
      ctx.beginPath();
      ctx.arc(-size * 0.12 - 2, -size * 0.14 + breathe * 0.5 - 2, 2.5, 0, Math.PI * 2);
      ctx.arc(size * 0.12 - 2, -size * 0.14 + breathe * 0.5 - 2, 2.5, 0, Math.PI * 2);
      ctx.arc(-size * 0.12 + 2, -size * 0.14 + breathe * 0.5 + 2, 1.2, 0, Math.PI * 2);
      ctx.arc(size * 0.12 + 2, -size * 0.14 + breathe * 0.5 + 2, 1.2, 0, Math.PI * 2);
      ctx.fill();
    }

    // Mouth
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2;
    ctx.beginPath();
    if (emotion === 'happy') {
      // Cute open smile :D
      ctx.fillStyle = PALETTE.pinkDeep;
      ctx.arc(0, -size * 0.07 + breathe * 0.5, 5, 0, Math.PI);
      ctx.fill();
      ctx.stroke();
    } else {
      // Subtle gentle smile
      ctx.arc(0, -size * 0.08 + breathe * 0.5, 4, 0.2, Math.PI - 0.2);
      ctx.stroke();
    }

    // Floating little hearts around her if happy or holding hands
    if (emotion === 'happy' || emotion === 'holding_hands') {
      const heartCount = 3;
      for (let i = 0; i < heartCount; i++) {
        const hx = Math.sin(time * 2 + i * 2) * 45;
        const hy = -size * 0.35 - (time * 25 + i * 35) % 40;
        this.drawHeart(ctx, hx, hy, 10, PALETTE.pinkMain);
      }
    }

    ctx.restore();
  }

  // --- CHIBI BOYFRIEND SPRITE ---
  drawBoyfriend(ctx, x, y, size = 180, time = 0) {
    ctx.save();
    ctx.translate(x, y);

    const breathe = Math.sin(time * 2.8 + 0.5) * 2;

    // Body: Dark cozy hoodie
    ctx.fillStyle = PALETTE.inkLight;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(-size * 0.24, size * 0.18 + breathe);
    ctx.lineTo(-size * 0.3, size * 0.65 + breathe);
    ctx.quadraticCurveTo(0, size * 0.72 + breathe, size * 0.3, size * 0.65 + breathe);
    ctx.lineTo(size * 0.24, size * 0.18 + breathe);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();

    // Hoodie pocket
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(-size * 0.16, size * 0.42 + breathe, size * 0.32, 22, 6);
    ctx.stroke();

    // Head
    ctx.fillStyle = PALETTE.cream;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.ellipse(0, -size * 0.12 + breathe * 0.5, size * 0.27, size * 0.24, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    // Wavy hair
    ctx.fillStyle = PALETTE.ink;
    ctx.beginPath();
    ctx.arc(0, -size * 0.18 + breathe * 0.5, size * 0.27, Math.PI, Math.PI * 2);
    ctx.quadraticCurveTo(-size * 0.2, -size * 0.15 + breathe * 0.5, -size * 0.28, -size * 0.05 + breathe * 0.5);
    ctx.quadraticCurveTo(-size * 0.1, -size * 0.14 + breathe * 0.5, 0, -size * 0.14 + breathe * 0.5);
    ctx.quadraticCurveTo(size * 0.15, -size * 0.14 + breathe * 0.5, size * 0.28, -size * 0.05 + breathe * 0.5);
    ctx.quadraticCurveTo(size * 0.2, -size * 0.15 + breathe * 0.5, 0, -size * 0.18 + breathe * 0.5);
    ctx.fill();

    // Glasses
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(-size * 0.18, -size * 0.16 + breathe * 0.5, 15, 12, 3);
    ctx.roundRect(size * 0.04, -size * 0.16 + breathe * 0.5, 15, 12, 3);
    ctx.moveTo(-size * 0.03, -size * 0.12 + breathe * 0.5);
    ctx.lineTo(size * 0.04, -size * 0.12 + breathe * 0.5);
    ctx.stroke();

    // Eyes behind glasses
    ctx.fillStyle = PALETTE.ink;
    ctx.beginPath();
    ctx.arc(-size * 0.11, -size * 0.11 + breathe * 0.5, 3, 0, Math.PI * 2);
    ctx.arc(size * 0.11, -size * 0.11 + breathe * 0.5, 3, 0, Math.PI * 2);
    ctx.fill();

    // Blush
    ctx.fillStyle = PALETTE.pinkSoft;
    ctx.globalAlpha = 0.6;
    ctx.beginPath();
    ctx.ellipse(-size * 0.14, -size * 0.05 + breathe * 0.5, 8, 5, 0, 0, Math.PI * 2);
    ctx.ellipse(size * 0.14, -size * 0.05 + breathe * 0.5, 8, 5, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1.0;

    // Smile
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(0, -size * 0.05 + breathe * 0.5, 5, 0.2, Math.PI - 0.2);
    ctx.stroke();

    ctx.restore();
  }

  // --- HAND-HOLDING MINIGAME GRAPHICS ---
  // Renders the interactive hand holding scene
  drawHandHoldingScene(ctx, width, height, playerHand, girlHand, isHolding, warmth, obstacles, bonuses, time) {
    ctx.clearRect(0, 0, width, height);

    // Warm date background grid / aura
    const gradient = ctx.createRadialGradient(width / 2, height / 2, 50, width / 2, height / 2, width);
    if (isHolding) {
      gradient.addColorStop(0, 'rgba(255, 184, 198, 0.35)');
      gradient.addColorStop(0.5, 'rgba(255, 235, 240, 0.25)');
      gradient.addColorStop(1, 'rgba(252, 241, 244, 0.1)');
    } else {
      gradient.addColorStop(0, 'rgba(240, 240, 250, 0.2)');
      gradient.addColorStop(1, 'rgba(252, 241, 244, 0.05)');
    }
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);

    // Draw little floating hearts when hands connected
    if (isHolding) {
      const midX = (playerHand.x + girlHand.x) / 2;
      const midY = (playerHand.y + girlHand.y) / 2;

      // Warm glow aura
      ctx.save();
      const glow = ctx.createRadialGradient(midX, midY, 10, midX, midY, 70);
      glow.addColorStop(0, 'rgba(255, 107, 139, 0.6)');
      glow.addColorStop(0.5, 'rgba(255, 209, 102, 0.3)');
      glow.addColorStop(1, 'rgba(255, 107, 139, 0)');
      ctx.fillStyle = glow;
      ctx.beginPath();
      ctx.arc(midX, midY, 70, 0, Math.PI * 2);
      ctx.fill();

      // Floating hearts
      for (let i = 0; i < 6; i++) {
        const offsetAngle = (time * 3 + i * 1.05) % (Math.PI * 2);
        const dist = 30 + (i * 12);
        const hx = midX + Math.cos(offsetAngle) * dist;
        const hy = midY - 20 - ((time * 40 + i * 20) % 60);
        this.drawHeart(ctx, hx, hy, 9, PALETTE.pinkMain);
      }
      ctx.restore();
    }

    // Draw girlfriend's hand & arm
    ctx.save();
    this._drawHand(ctx, girlHand.x, girlHand.y, isHolding, 'girl', time);
    ctx.restore();

    // Draw boyfriend's hand & arm
    ctx.save();
    this._drawHand(ctx, playerHand.x, playerHand.y, isHolding, 'boy', time);
    ctx.restore();

    // Draw obstacles (cold wind, urgent phone call, alarm clock)
    for (const obs of obstacles) {
      this._drawObstacle(ctx, obs, time);
    }

    // Draw date bonuses (hot latte, warm croissant, cute street cat)
    for (const b of bonuses) {
      this._drawBonus(ctx, b, time);
    }
  }

  _drawHand(ctx, x, y, isHolding, side = 'boy', time = 0) {
    ctx.translate(x, y);
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    const isBoy = side === 'boy';
    const sleeveColor = isBoy ? PALETTE.inkLight : PALETTE.cream;
    const skinColor = PALETTE.cream;

    // Sleeve
    ctx.fillStyle = sleeveColor;
    const sleeveWidth = 38;
    const sleeveLength = 90;
    const dir = isBoy ? 1 : -1;

    ctx.beginPath();
    ctx.roundRect(-sleeveWidth / 2, dir > 0 ? 25 : -25 - sleeveLength, sleeveWidth, sleeveLength, 10);
    ctx.fill();
    ctx.stroke();

    // Sleeve ribbing lines
    ctx.lineWidth = 1.5;
    ctx.strokeStyle = isBoy ? PALETTE.ink : PALETTE.pinkSoft;
    for (let i = 0; i < 3; i++) {
      const ly = dir > 0 ? 30 + i * 5 : -20 - i * 5;
      ctx.beginPath();
      ctx.moveTo(-sleeveWidth / 2 + 4, ly);
      ctx.lineTo(sleeveWidth / 2 - 4, ly);
      ctx.stroke();
    }

    // Hand palm & fingers
    ctx.fillStyle = skinColor;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2.5;

    if (isHolding) {
      // Clasping fingers with love
      ctx.beginPath();
      ctx.ellipse(0, 5 * dir, 17, 19, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      // Interlocking finger curves
      for (let f = -2; f <= 2; f++) {
        ctx.beginPath();
        ctx.moveTo(f * 5, -2 * dir);
        ctx.quadraticCurveTo(f * 6, 12 * dir, f * 4, 18 * dir);
        ctx.stroke();
      }
    } else {
      // Open hand reaching out
      ctx.beginPath();
      ctx.ellipse(0, 0, 16, 18, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();

      // Open fingers
      const fingers = [-10, -5, 0, 5, 10];
      fingers.forEach((fx, idx) => {
        const fLen = 14 - Math.abs(idx - 2) * 2;
        ctx.beginPath();
        ctx.moveTo(fx, 5 * -dir);
        ctx.lineTo(fx * 1.2, (5 + fLen) * -dir);
        ctx.stroke();
      });
    }
  }

  _drawObstacle(ctx, obs, time) {
    ctx.save();
    ctx.translate(obs.x, obs.y);
    const wobble = Math.sin(time * 5 + obs.id) * 3;

    // Obstacle bubble
    ctx.fillStyle = 'rgba(255, 230, 235, 0.9)';
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(0, wobble, obs.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    // Icon & Label
    ctx.fillStyle = PALETTE.ink;
    ctx.font = 'bold 18px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(obs.icon, 0, wobble - 5);

    ctx.font = '8px "Press Start 2P", monospace';
    ctx.fillText(obs.name, 0, wobble + 18);

    ctx.restore();
  }

  _drawBonus(ctx, b, time) {
    ctx.save();
    ctx.translate(b.x, b.y);
    const floatY = Math.sin(time * 4 + b.id) * 5;

    // Golden glow
    ctx.fillStyle = 'rgba(255, 209, 102, 0.3)';
    ctx.beginPath();
    ctx.arc(0, floatY, b.radius + 6, 0, Math.PI * 2);
    ctx.fill();

    // Bonus bubble
    ctx.fillStyle = PALETTE.cream;
    ctx.strokeStyle = PALETTE.gold;
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.arc(0, floatY, b.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    // Icon
    ctx.font = '22px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(b.icon, 0, floatY - 2);

    ctx.fillStyle = PALETTE.ink;
    ctx.font = '7px "Press Start 2P", monospace';
    ctx.fillText(b.name, 0, floatY + 16);

    ctx.restore();
  }

  // --- HEART RHYTHM / SYNC OSCILLOSCOPE GRAPHICS ---
  drawHeartbeatMonitor(ctx, width, height, beats, syncScore, stage, time) {
    ctx.clearRect(0, 0, width, height);

    // Dark retro phosphor CRT display
    ctx.fillStyle = '#16101F';
    ctx.fillRect(0, 0, width, height);

    // Oscillogram grid
    ctx.strokeStyle = 'rgba(255, 107, 139, 0.12)';
    ctx.lineWidth = 1;
    const gridSize = 24;
    for (let x = 0; x < width; x += gridSize) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
    }
    for (let y = 0; y < height; y += gridSize) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
    }

    const centerY = height / 2;
    const centerX = width / 2;

    // Glowing cardiogram pulse line
    ctx.save();
    ctx.strokeStyle = PALETTE.pinkMain;
    ctx.lineWidth = 2.5;
    ctx.shadowColor = PALETTE.pinkMain;
    ctx.shadowBlur = 8;

    ctx.beginPath();
    ctx.moveTo(0, centerY);
    for (let x = 0; x < width; x += 3) {
      // Traveling ECG wave
      const waveX = (x - time * 120) % width;
      let waveY = centerY;
      const distFromCenter = Math.abs(x - centerX);
      if (distFromCenter < 120) {
        const pulse = Math.sin((x + time * 180) * 0.1);
        waveY += pulse * (1.0 - distFromCenter / 120) * 35;
      }
      ctx.lineTo(x, waveY);
    }
    ctx.stroke();
    ctx.restore();

    // Center rhythm target node
    ctx.save();
    const targetRadius = 36;
    const pulseRing = (time * 3) % 1;
    
    // Outer ripple
    ctx.strokeStyle = `rgba(255, 107, 139, ${1 - pulseRing})`;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(centerX, centerY, targetRadius + pulseRing * 25, 0, Math.PI * 2);
    ctx.stroke();

    // Target circle
    ctx.strokeStyle = PALETTE.gold;
    ctx.lineWidth = 3;
    ctx.fillStyle = 'rgba(255, 107, 139, 0.2)';
    ctx.beginPath();
    ctx.arc(centerX, centerY, targetRadius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    // Center symbol
    ctx.fillStyle = PALETTE.white;
    ctx.font = '10px "Press Start 2P", monospace';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('SYNC', centerX, centerY);
    ctx.restore();

    // Draw travelling beats (His heart from left, Her heart from right)
    for (const b of beats) {
      // Left heart (Boy: warm crimson / rose)
      this.drawHeart(ctx, b.leftX, centerY, 14, '#FF4D6D');
      // Right heart (Girl: pastel bright pink)
      this.drawHeart(ctx, b.rightX, centerY, 14, '#FF85A2');

      // Connection beam between them
      if (Math.abs(b.leftX - b.rightX) < 180) {
        ctx.strokeStyle = 'rgba(255, 209, 102, 0.5)';
        ctx.lineWidth = 1.5;
        ctx.setLineDash([4, 4]);
        ctx.beginPath();
        ctx.moveTo(b.leftX + 10, centerY);
        ctx.lineTo(b.rightX - 10, centerY);
        ctx.stroke();
        ctx.setLineDash([]);
      }
    }

    // If fully synchronized (100%), draw the grand glowing infinity heart!
    if (syncScore >= 100) {
      ctx.save();
      const glowScale = 1.0 + Math.sin(time * 6) * 0.15;
      this.drawHeart(ctx, centerX, centerY, 34 * glowScale, PALETTE.pinkMain);
      
      // Infinity loop inside
      ctx.strokeStyle = PALETTE.white;
      ctx.lineWidth = 3;
      ctx.beginPath();
      // Draw infinity symbol ∞
      const infR = 10;
      ctx.arc(centerX - infR, centerY, infR, 0, Math.PI * 2);
      ctx.arc(centerX + infR, centerY, infR, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    }
  }

  // Helper to draw a pixel-perfect doodle heart
  drawHeart(ctx, x, y, size = 12, color = PALETTE.pinkMain) {
    ctx.save();
    ctx.translate(x, y);
    ctx.fillStyle = color;
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2;

    ctx.beginPath();
    ctx.moveTo(0, size * 0.4);
    ctx.bezierCurveTo(-size, -size * 0.2, -size * 0.8, -size * 0.9, 0, -size * 0.5);
    ctx.bezierCurveTo(size * 0.8, -size * 0.9, size, -size * 0.2, 0, size * 0.4);
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  }
}

export const art = new ArtRenderer();
