// Procedural Pixel Art Renderer for "Print I Love You: For My Beloved"
// 100% Authentic Retro Pixel-Art Graphics

export const PALETTE = {
  bgLight: '#FCF1F4',
  bgDark: '#120A21',
  ink: '#1A1423',
  inkLight: '#3D2D4D',
  pinkSoft: '#FFB8C6',
  pinkMain: '#FF6B8B',
  pinkDeep: '#E83E6E',
  cream: '#FFF9FA',
  gold: '#FFD166',
  goldLight: '#FFF275',
  purpleSoft: '#DDD2F2',
  mint: '#70E4BA',
  iceBlue: '#A0D2EB',
  white: '#FFFFFF'
};

export class ArtRenderer {
  constructor() {
    this.imgCache = {};
  }

  loadImage(src) {
    if (this.imgCache[src]) return this.imgCache[src];
    const img = new Image();
    img.src = src;
    this.imgCache[src] = img;
    return img;
  }

  // --- PIXEL RECT & HELPERS ---
  drawPixelRect(ctx, x, y, w, h, fill, stroke = PALETTE.ink, strokeW = 2) {
    ctx.fillStyle = fill;
    ctx.fillRect(Math.floor(x), Math.floor(y), Math.floor(w), Math.floor(h));
    if (stroke && strokeW > 0) {
      ctx.strokeStyle = stroke;
      ctx.lineWidth = strokeW;
      ctx.strokeRect(Math.floor(x), Math.floor(y), Math.floor(w), Math.floor(h));
    }
  }

  // --- TEST 1: HAND-HOLDING SCENE ---
  drawHandHoldingScene(ctx, width, height, playerHand, girlHand, isHolding, warmth, obstacles, bonuses, time) {
    ctx.clearRect(0, 0, width, height);

    // Retro pixel checkerboard / dither background
    ctx.fillStyle = isHolding ? '#26142c' : '#1a1423';
    ctx.fillRect(0, 0, width, height);

    // Pixel stars / warm glow in background
    ctx.fillStyle = isHolding ? 'rgba(255, 107, 139, 0.15)' : 'rgba(255, 255, 255, 0.05)';
    const step = 16;
    for (let x = 0; x < width; x += step) {
      for (let y = 0; y < height; y += step) {
        if ((Math.floor(x / step) + Math.floor(y / step)) % 2 === 0) {
          ctx.fillRect(x, y, 2, 2);
        }
      }
    }

    // Warm aura when holding
    if (isHolding) {
      const midX = Math.floor((playerHand.x + girlHand.x) / 2);
      const midY = Math.floor((playerHand.y + girlHand.y) / 2);

      // Pixelated concentric heart circles
      for (let r = 80; r > 10; r -= 14) {
        ctx.fillStyle = `rgba(255, 107, 139, ${(80 - r) / 220})`;
        ctx.fillRect(midX - r, midY - r, r * 2, r * 2);
      }

      // Floating pixel hearts
      for (let i = 0; i < 5; i++) {
        const hx = midX + Math.sin(time * 3 + i * 1.3) * (20 + i * 10);
        const hy = midY - ((time * 40 + i * 25) % 80);
        this.drawPixelHeart(ctx, hx, hy, 12, PALETTE.pinkMain);
      }
    }

    // Draw boyfriend's pixel hand (blue jacket cuff)
    this.drawPixelHand(ctx, playerHand.x, playerHand.y, isHolding, 'boy', time);

    // Draw girlfriend's pixel hand (white lace cuff)
    this.drawPixelHand(ctx, girlHand.x, girlHand.y, isHolding, 'girl', time);

    // Obstacles
    for (const obs of obstacles) {
      this.drawPixelObstacle(ctx, obs, time);
    }

    // Bonuses
    for (const b of bonuses) {
      this.drawPixelBonus(ctx, b, time);
    }
  }

  drawPixelHand(ctx, x, y, isHolding, side = 'boy', time = 0) {
    ctx.save();
    ctx.translate(Math.floor(x), Math.floor(y));

    const isBoy = side === 'boy';
    const cuffColor = isBoy ? '#2563EB' : '#FFFFFF'; // Blue bomber jacket vs white lace
    const skinColor = '#FBD3B6';
    const shadowSkin = '#E2B294';
    const dir = isBoy ? 1 : -1;

    // Sleeve / Arm (stepped pixel block)
    ctx.fillStyle = cuffColor;
    ctx.fillRect(-18, dir > 0 ? 20 : -80, 36, 60);
    // Dark outline
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.strokeRect(-18, dir > 0 ? 20 : -80, 36, 60);

    // Cuff detail
    ctx.fillStyle = isBoy ? '#1D4ED8' : '#F3E8FF';
    ctx.fillRect(-18, dir > 0 ? 20 : -28, 36, 8);
    ctx.strokeRect(-18, dir > 0 ? 20 : -28, 36, 8);

    // Hand palm
    ctx.fillStyle = skinColor;
    ctx.fillRect(-14, -14, 28, 28);
    ctx.fillStyle = shadowSkin;
    ctx.fillRect(-14, 6, 28, 8);
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.strokeRect(-14, -14, 28, 28);

    // Fingers
    if (isHolding) {
      // Clasping fingers
      ctx.fillStyle = skinColor;
      for (let i = -10; i <= 6; i += 5) {
        ctx.fillRect(i, -6, 4, 16);
        ctx.strokeRect(i, -6, 4, 16);
      }
    } else {
      // Open reaching fingers
      const fingers = [-12, -6, 0, 6];
      fingers.forEach((fx, idx) => {
        const fLen = 14 - Math.abs(idx - 1.5) * 3;
        const fy = dir > 0 ? -14 - fLen : 14;
        ctx.fillStyle = skinColor;
        ctx.fillRect(fx, fy, 5, fLen);
        ctx.strokeRect(fx, fy, 5, fLen);
      });
    }

    ctx.restore();
  }

  drawPixelObstacle(ctx, obs, time) {
    ctx.save();
    ctx.translate(Math.floor(obs.x), Math.floor(obs.y));
    const wobble = Math.floor(Math.sin(time * 6 + obs.id) * 3);

    // Stepped pixel bubble
    ctx.fillStyle = '#FFE5EC';
    ctx.fillRect(-22, -22 + wobble, 44, 44);
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.strokeRect(-22, -22 + wobble, 44, 44);

    // Emoji icon
    ctx.font = '16px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(obs.icon, 0, wobble - 2);

    ctx.fillStyle = PALETTE.ink;
    ctx.font = '7px "PressStart2P", monospace';
    ctx.fillText(obs.name, 0, wobble + 16);

    ctx.restore();
  }

  drawPixelBonus(ctx, b, time) {
    ctx.save();
    ctx.translate(Math.floor(b.x), Math.floor(b.y));
    const floatY = Math.floor(Math.sin(time * 5 + b.id) * 4);

    // Golden pixel box
    ctx.fillStyle = PALETTE.gold;
    ctx.fillRect(-24, -24 + floatY, 48, 48);
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.strokeRect(-24, -24 + floatY, 48, 48);

    ctx.font = '18px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(b.icon, 0, floatY - 2);

    ctx.fillStyle = PALETTE.ink;
    ctx.font = '7px "PressStart2P", monospace';
    ctx.fillText(b.name, 0, floatY + 16);

    ctx.restore();
  }

  // --- NEW TEST 2: STARGAZING & CATCHING STARS OF WISHES ---
  drawStarCatcherScene(ctx, width, height, stars, catcher, constellation, starEnergy, time) {
    ctx.clearRect(0, 0, width, height);

    // Deep pixel night sky gradient with dither
    ctx.fillStyle = '#0F091A';
    ctx.fillRect(0, 0, width, height);

    // Dithered skyline / milky way
    ctx.fillStyle = 'rgba(255, 117, 151, 0.08)';
    for (let y = 0; y < height; y += 4) {
      if ((y / 4) % 2 === 0) {
        ctx.fillRect(0, y, width, 2);
      }
    }

    // Glowing Pixel Moon in the top-right
    const moonX = 550;
    const moonY = 60;
    ctx.fillStyle = PALETTE.goldLight;
    ctx.fillRect(moonX, moonY, 32, 32);
    ctx.fillStyle = '#0F091A';
    ctx.fillRect(moonX + 12, moonY, 26, 32); // Crescent cutout
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 2;
    ctx.strokeRect(moonX, moonY, 32, 32);

    // Twinkling background stars
    for (let i = 0; i < 40; i++) {
      const sx = ((i * 137) % width);
      const sy = ((i * 89) % 260);
      const blink = Math.sin(time * 4 + i) > 0.3;
      if (blink) {
        ctx.fillStyle = i % 2 === 0 ? PALETTE.white : PALETTE.pinkSoft;
        ctx.fillRect(sx, sy, 3, 3);
      }
    }

    // Constellation lines that form between caught stars
    if (constellation.length > 1) {
      ctx.save();
      ctx.strokeStyle = PALETTE.gold;
      ctx.lineWidth = 2;
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(constellation[0].x, constellation[0].y);
      for (let i = 1; i < constellation.length; i++) {
        ctx.lineTo(constellation[i].x, constellation[i].y);
      }
      ctx.stroke();
      ctx.setLineDash([]);

      // Stars on the constellation vertices
      for (const pt of constellation) {
        this.drawPixelStar(ctx, pt.x, pt.y, 10, PALETTE.goldLight, time);
      }
      ctx.restore();
    }

    // If constellation completed (100%), draw glowing giant heart in sky
    if (starEnergy >= 100) {
      this.drawPixelHeart(ctx, width / 2, 120, 48 + Math.sin(time * 5) * 6, PALETTE.pinkMain);
    }

    // Rooftop balcony silhouette at bottom
    ctx.fillStyle = '#181024';
    ctx.fillRect(0, height - 70, width, 70);
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.strokeRect(0, height - 70, width, 70);

    // Balcony railing posts
    for (let rx = 10; rx < width; rx += 28) {
      ctx.fillStyle = '#26193A';
      ctx.fillRect(rx, height - 70, 6, 25);
    }
    ctx.fillRect(0, height - 70, width, 6);

    // Silhouettes of Boyfriend & Girlfriend watching the sky together on the left
    this.drawRooftopCoupleSilhouette(ctx, 60, height - 68, time);

    // Falling Shooting Stars
    for (const star of stars) {
      this.drawFallingStar(ctx, star, time);
    }

    // Player's Celestial Catcher / Basket
    this.drawCatcher(ctx, catcher.x, catcher.y, catcher.width, catcher.height, time);
  }

  drawRooftopCoupleSilhouette(ctx, x, y, time) {
    ctx.save();
    ctx.translate(x, y);

    // Boyfriend pixel silhouette (blue hints)
    ctx.fillStyle = '#1D4ED8';
    ctx.fillRect(0, -45, 18, 45); // Body
    ctx.fillStyle = '#FBD3B6';
    ctx.fillRect(2, -62, 14, 16); // Face
    ctx.fillStyle = '#1A1423';
    ctx.fillRect(0, -68, 18, 12); // Textured hair with fade

    // Girlfriend pixel silhouette (white lace / dark hair)
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(18, -42, 16, 42); // Body
    ctx.fillStyle = '#FBD3B6';
    ctx.fillRect(19, -60, 14, 16); // Face
    ctx.fillStyle = '#1A1423';
    ctx.fillRect(16, -66, 20, 36); // Long cascading hair

    // Holding hands silhouette
    ctx.fillStyle = '#FBD3B6';
    ctx.fillRect(14, -28, 8, 6);

    // Little heart above them
    const hY = -78 + Math.sin(time * 3) * 4;
    this.drawPixelHeart(ctx, 18, hY, 7, PALETTE.pinkMain);

    ctx.restore();
  }

  drawFallingStar(ctx, star, time) {
    ctx.save();
    ctx.translate(Math.floor(star.x), Math.floor(star.y));

    // Pixel tail
    ctx.fillStyle = star.color || PALETTE.gold;
    ctx.globalAlpha = 0.5;
    for (let t = 1; t <= 4; t++) {
      ctx.fillRect(-t * 3, -t * 8, 4 - t * 0.8, 6);
    }
    ctx.globalAlpha = 1.0;

    // Star Core
    this.drawPixelStar(ctx, 0, 0, star.size || 14, star.color || PALETTE.gold, time);

    // Small label tag if wish star
    if (star.wishText) {
      ctx.fillStyle = '#FFFFFF';
      ctx.font = '7px "PressStart2P", monospace';
      ctx.textAlign = 'center';
      ctx.fillText(star.wishText, 0, -14);
    }

    ctx.restore();
  }

  drawCatcher(ctx, x, y, w, h, time) {
    ctx.save();
    ctx.translate(Math.floor(x), Math.floor(y));

    // Stepped pixel catcher basket
    ctx.fillStyle = PALETTE.gold;
    ctx.fillRect(-w / 2, -h / 2, w, h);
    ctx.fillStyle = PALETTE.pinkMain;
    ctx.fillRect(-w / 2 + 4, -h / 2 + 4, w - 8, h - 8);

    // Outline
    ctx.strokeStyle = PALETTE.ink;
    ctx.lineWidth = 3;
    ctx.strokeRect(-w / 2, -h / 2, w, h);

    // Wings on sides
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(-w / 2 - 10, -6, 10, 12);
    ctx.strokeRect(-w / 2 - 10, -6, 10, 12);
    ctx.fillRect(w / 2, -6, 10, 12);
    ctx.strokeRect(w / 2, -6, 10, 12);

    // Heart badge in center
    this.drawPixelHeart(ctx, 0, 0, 8, '#FFFFFF');

    ctx.restore();
  }

  // --- TEST 3: HEARTBEAT MONITOR ---
  drawHeartbeatMonitor(ctx, width, height, beats, syncScore, stage, time) {
    ctx.clearRect(0, 0, width, height);

    // Dark retro phosphor CRT
    ctx.fillStyle = '#100B18';
    ctx.fillRect(0, 0, width, height);

    // Pixel grid
    ctx.fillStyle = 'rgba(255, 107, 139, 0.1)';
    for (let x = 0; x < width; x += 20) {
      ctx.fillRect(x, 0, 1, height);
    }
    for (let y = 0; y < height; y += 20) {
      ctx.fillRect(0, y, width, 1);
    }

    const centerY = Math.floor(height / 2);
    const centerX = Math.floor(width / 2);

    // Stepped pixel cardiogram line
    ctx.fillStyle = PALETTE.pinkMain;
    for (let x = 0; x < width; x += 3) {
      let waveY = centerY;
      const dist = Math.abs(x - centerX);
      if (dist < 120) {
        const pulse = Math.sin((x + time * 200) * 0.12);
        waveY += Math.floor(pulse * (1.0 - dist / 120) * 36);
      }
      ctx.fillRect(x, waveY, 3, 3);
    }

    // Center rhythm target box
    ctx.fillStyle = 'rgba(255, 209, 102, 0.2)';
    ctx.fillRect(centerX - 30, centerY - 30, 60, 60);
    ctx.strokeStyle = PALETTE.gold;
    ctx.lineWidth = 3;
    ctx.strokeRect(centerX - 30, centerY - 30, 60, 60);

    // Center pulse icon
    this.drawPixelHeart(ctx, centerX, centerY, 14, PALETTE.pinkMain);

    // Moving hearts
    for (const b of beats) {
      // Boyfriend heart (warm crimson / blue)
      this.drawPixelHeart(ctx, b.leftX, centerY, 14, '#FF4D6D');
      // Girlfriend heart (pastel rose)
      this.drawPixelHeart(ctx, b.rightX, centerY, 14, '#FF85A2');

      // Pixel connection line
      if (Math.abs(b.leftX - b.rightX) < 180) {
        ctx.fillStyle = PALETTE.gold;
        for (let lx = b.leftX + 12; lx < b.rightX - 12; lx += 8) {
          ctx.fillRect(Math.floor(lx), centerY - 1, 4, 3);
        }
      }
    }

    // If fully synchronized (100%), show grand infinity heart!
    if (syncScore >= 100) {
      this.drawPixelHeart(ctx, centerX, centerY, 40, PALETTE.pinkMain);
      ctx.fillStyle = '#FFFFFF';
      ctx.font = '10px "PressStart2P", monospace';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('∞', centerX, centerY);
    }
  }

  // Helper: Draw a crisp pixel-art heart
  drawPixelHeart(ctx, x, y, size = 12, color = PALETTE.pinkMain) {
    ctx.save();
    ctx.translate(Math.floor(x), Math.floor(y));
    ctx.fillStyle = color;

    // Stepped pixel blocks for classic 8-bit heart
    const s = Math.max(1, Math.floor(size / 6));

    // Top two lobes
    ctx.fillRect(-3 * s, -3 * s, 2 * s, 2 * s);
    ctx.fillRect(1 * s, -3 * s, 2 * s, 2 * s);

    // Middle body
    ctx.fillRect(-4 * s, -1 * s, 8 * s, 2 * s);
    ctx.fillRect(-3 * s, 1 * s, 6 * s, 2 * s);
    ctx.fillRect(-2 * s, 3 * s, 4 * s, 2 * s);
    ctx.fillRect(-1 * s, 5 * s, 2 * s, 1 * s);

    ctx.restore();
  }

  // Helper: Draw a 4-point pixel star
  drawPixelStar(ctx, x, y, size = 10, color = PALETTE.gold, time = 0) {
    ctx.save();
    ctx.translate(Math.floor(x), Math.floor(y));
    ctx.fillStyle = color;
    const s = Math.max(1, Math.floor(size / 4));

    ctx.fillRect(-s, -s * 3, 2 * s, s * 6);
    ctx.fillRect(-s * 3, -s, s * 6, 2 * s);
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(-s, -s, 2 * s, 2 * s);

    ctx.restore();
  }
}

export const art = new ArtRenderer();
