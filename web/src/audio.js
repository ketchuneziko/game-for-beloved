// Web Audio API Synthesizer Engine for "Print I Love You: For My Beloved"
// Procedural lo-fi chiptune music and authentic cute retro sound effects

class SoundEngine {
  constructor() {
    this.ctx = null;
    this.masterGain = null;
    this.musicGain = null;
    this.sfxGain = null;
    this.isMuted = false;
    this.currentTrack = null;
    this.isPlaying = false;
    this.timerId = null;
    this.step = 0;
    this.tempo = 90;
    this.musicVolume = 0.45;
    this.sfxVolume = 0.6;
    this.hasUnlocked = false;
  }

  init() {
    if (this.ctx) return;
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    
    this.ctx = new AudioContext();
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.setValueAtTime(1.0, this.ctx.currentTime);
    this.masterGain.connect(this.ctx.destination);

    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.setValueAtTime(this.musicVolume, this.ctx.currentTime);
    this.musicGain.connect(this.masterGain);

    this.sfxGain = this.ctx.createGain();
    this.sfxGain.gain.setValueAtTime(this.sfxVolume, this.ctx.currentTime);
    this.sfxGain.connect(this.masterGain);

    this.hasUnlocked = true;
  }

  unlock() {
    if (!this.ctx) this.init();
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  setVolume(musicVol, sfxVol) {
    if (musicVol !== undefined) {
      this.musicVolume = Math.max(0, Math.min(1, musicVol));
      if (this.musicGain && this.ctx) {
        this.musicGain.gain.setValueAtTime(this.isMuted ? 0 : this.musicVolume, this.ctx.currentTime);
      }
    }
    if (sfxVol !== undefined) {
      this.sfxVolume = Math.max(0, Math.min(1, sfxVol));
      if (this.sfxGain && this.ctx) {
        this.sfxGain.gain.setValueAtTime(this.isMuted ? 0 : this.sfxVolume, this.ctx.currentTime);
      }
    }
  }

  toggleMute() {
    this.isMuted = !this.isMuted;
    if (this.masterGain && this.ctx) {
      this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : 1.0, this.ctx.currentTime);
    }
    return this.isMuted;
  }

  // Frequency table for notes
  mtof(midi) {
    return 440 * Math.pow(2, (midi - 69) / 12);
  }

  // --- SOUND EFFECTS ---

  playTypewriter() {
    if (!this.ctx || this.isMuted) return;
    this.unlock();
    const t = this.ctx.currentTime;
    
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    const filter = this.ctx.createBiquadFilter();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(650 + Math.random() * 180, t);
    
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(1200, t);
    filter.Q.setValueAtTime(3.0, t);

    gain.gain.setValueAtTime(0.08, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.04);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(t);
    osc.stop(t + 0.04);
  }

  playClick() {
    if (!this.ctx || this.isMuted) return;
    this.unlock();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, t);
    osc.frequency.exponentialRampToValueAtTime(400, t + 0.05);

    gain.gain.setValueAtTime(0.12, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.05);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(t);
    osc.stop(t + 0.05);
  }

  playHeartbeat() {
    if (!this.ctx || this.isMuted) return;
    this.unlock();
    const t = this.ctx.currentTime;

    // First thump (lub)
    this._synthThump(t, 55, 0.22, 0.18);
    // Second thump (dub)
    this._synthThump(t + 0.14, 68, 0.18, 0.14);
  }

  _synthThump(time, freq, gainVal, dur) {
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    const filter = this.ctx.createBiquadFilter();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(freq * 1.5, time);
    osc.frequency.exponentialRampToValueAtTime(freq * 0.7, time + dur);

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(140, time);

    gain.gain.setValueAtTime(gainVal, time);
    gain.gain.exponentialRampToValueAtTime(0.001, time + dur);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(time);
    osc.stop(time + dur);
  }

  playHandConnect() {
    if (!this.ctx || this.isMuted) return;
    this.unlock();
    const t = this.ctx.currentTime;
    
    // Warm harmonic chord
    const notes = [60, 64, 67, 72]; // C - E - G - C
    notes.forEach((midi, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(this.mtof(midi), t + idx * 0.04);
      
      gain.gain.setValueAtTime(0.1, t + idx * 0.04);
      gain.gain.exponentialRampToValueAtTime(0.001, t + idx * 0.04 + 0.35);

      osc.connect(gain);
      gain.connect(this.sfxGain);

      osc.start(t + idx * 0.04);
      osc.stop(t + idx * 0.04 + 0.35);
    });
  }

  playSparkle() {
    if (!this.ctx || this.isMuted) return;
    this.unlock();
    const t = this.ctx.currentTime;
    const notes = [72, 76, 79, 84, 88];
    notes.forEach((midi, i) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(this.mtof(midi), t + i * 0.05);
      gain.gain.setValueAtTime(0.08, t + i * 0.05);
      gain.gain.exponentialRampToValueAtTime(0.001, t + i * 0.05 + 0.25);
      osc.connect(gain);
      gain.connect(this.sfxGain);
      osc.start(t + i * 0.05);
      osc.stop(t + i * 0.05 + 0.25);
    });
  }

  playHit(isPerfect = true) {
    if (!this.ctx || this.isMuted) return;
    this.unlock();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = isPerfect ? 'triangle' : 'sine';
    const baseFreq = isPerfect ? 880 : 660;
    osc.frequency.setValueAtTime(baseFreq, t);
    osc.frequency.exponentialRampToValueAtTime(baseFreq * 1.5, t + 0.12);

    gain.gain.setValueAtTime(isPerfect ? 0.2 : 0.12, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.2);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(t);
    osc.stop(t + 0.2);

    if (isPerfect) {
      // Little sub-bass chime
      this.playHeartbeat();
    }
  }

  playColdShiver() {
    if (!this.ctx || this.isMuted) return;
    this.unlock();
    const t = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(260, t);
    osc.frequency.linearRampToValueAtTime(140, t + 0.18);

    gain.gain.setValueAtTime(0.12, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 0.18);

    osc.connect(gain);
    gain.connect(this.sfxGain);

    osc.start(t);
    osc.stop(t + 0.18);
  }

  playAchievement() {
    if (!this.ctx || this.isMuted) return;
    this.unlock();
    const t = this.ctx.currentTime;
    const fanfare = [
      { midi: 60, time: 0.00, dur: 0.12 },
      { midi: 64, time: 0.12, dur: 0.12 },
      { midi: 67, time: 0.24, dur: 0.12 },
      { midi: 72, time: 0.36, dur: 0.35 },
      { midi: 76, time: 0.50, dur: 0.50 }
    ];

    fanfare.forEach(n => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(this.mtof(n.midi), t + n.time);
      gain.gain.setValueAtTime(0.15, t + n.time);
      gain.gain.exponentialRampToValueAtTime(0.001, t + n.time + n.dur);
      osc.connect(gain);
      gain.connect(this.sfxGain);
      osc.start(t + n.time);
      osc.stop(t + n.time + n.dur);
    });
  }

  // --- PROCEDURAL MUSIC ENGINE ---

  playMusic(themeName) {
    this.unlock();
    if (this.currentTrack === themeName && this.isPlaying) return;
    this.stopMusic();
    this.currentTrack = themeName;
    this.isPlaying = true;
    this.step = 0;

    switch (themeName) {
      case 'desktop':
        this.tempo = 84;
        this._scheduleLoop = this._desktopLoop.bind(this);
        break;
      case 'hand':
        this.tempo = 78;
        this._scheduleLoop = this._handLoop.bind(this);
        break;
      case 'dress':
        this.tempo = 96;
        this._scheduleLoop = this._dressLoop.bind(this);
        break;
      case 'heart':
        this.tempo = 80;
        this._scheduleLoop = this._heartLoop.bind(this);
        break;
      case 'finale':
        this.tempo = 75;
        this._scheduleLoop = this._finaleLoop.bind(this);
        break;
      default:
        this.tempo = 84;
        this._scheduleLoop = this._desktopLoop.bind(this);
    }

    const intervalMs = (60 / this.tempo / 4) * 1000; // 16th notes
    this.timerId = setInterval(() => {
      if (this.isPlaying && this._scheduleLoop) {
        this._scheduleLoop(this.step);
        this.step = (this.step + 1) % 64;
      }
    }, intervalMs);
  }

  stopMusic() {
    this.isPlaying = false;
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
  }

  _playNote(midi, timeOffset, dur, type = 'sine', gainVal = 0.08) {
    if (!this.ctx || this.isMuted) return;
    const t = this.ctx.currentTime + timeOffset;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    const filter = this.ctx.createBiquadFilter();

    osc.type = type;
    osc.frequency.setValueAtTime(this.mtof(midi), t);

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(2400, t);

    gain.gain.setValueAtTime(gainVal, t);
    gain.gain.exponentialRampToValueAtTime(0.0001, t + dur);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(this.musicGain);

    osc.start(t);
    osc.stop(t + dur);
  }

  // Soft bass tone
  _playBass(midi, timeOffset, dur) {
    this._playNote(midi, timeOffset, dur, 'triangle', 0.12);
  }

  // --- LO-FI CHIPTUNE THEMES ---

  _desktopLoop(s) {
    // Gentle 16-bar romantic progression in C major / A minor
    // Chords: Am -> F -> C -> G
    const chordIdx = Math.floor(s / 16);
    const chords = [
      { bass: 45, arp: [57, 60, 64, 69] }, // Am
      { bass: 41, arp: [53, 57, 60, 65] }, // F
      { bass: 48, arp: [60, 64, 67, 72] }, // C
      { bass: 43, arp: [55, 59, 62, 67] }  // G
    ];
    const current = chords[chordIdx];

    // Bass on beats 0 and 8
    if (s % 8 === 0) {
      this._playBass(current.bass, 0, 0.45);
    }

    // Cozy arpeggio on 16ths
    if (s % 2 === 0) {
      const note = current.arp[(s / 2) % 4];
      this._playNote(note, 0, 0.25, 'sine', 0.04);
    }

    // Melodic accents
    const melodyMap = {
      0: 72, 6: 74, 10: 76, 14: 72,
      16: 69, 22: 72, 26: 71, 30: 67,
      32: 67, 38: 69, 42: 72, 46: 74,
      48: 76, 54: 74, 58: 72, 62: 71
    };
    if (melodyMap[s]) {
      this._playNote(melodyMap[s], 0, 0.4, 'triangle', 0.09);
    }
  }

  _handLoop(s) {
    // Warm waltz feel: C -> Em -> F -> G
    const chordIdx = Math.floor(s / 16);
    const bassNotes = [48, 52, 41, 43];
    const highArp = [
      [64, 67, 72], [64, 67, 71], [65, 69, 72], [62, 67, 71]
    ];

    if (s % 16 === 0) {
      this._playBass(bassNotes[chordIdx], 0, 0.6);
    }
    if (s % 4 === 0) {
      const notes = highArp[chordIdx];
      const n = notes[(s / 4) % notes.length];
      this._playNote(n, 0, 0.35, 'sine', 0.05);
    }
    // Melody
    const melody = {
      4: 76, 8: 74, 12: 72,
      20: 71, 24: 72, 28: 74,
      36: 76, 40: 79, 44: 77,
      52: 76, 56: 74, 60: 72
    };
    if (melody[s]) {
      this._playNote(melody[s], 0, 0.45, 'triangle', 0.08);
    }
  }

  _dressLoop(s) {
    // Bouncy, fashionable, cheerful groove
    const chordIdx = Math.floor(s / 16);
    const bass = [45, 48, 41, 43][chordIdx];
    if (s % 4 === 0) {
      this._playBass(bass, 0, 0.2);
    }
    if (s % 2 === 0) {
      const notes = [64, 67, 69, 72, 74, 76];
      this._playNote(notes[s % notes.length], 0, 0.15, 'triangle', 0.04);
    }
    const tune = {
      0: 69, 3: 72, 6: 74, 8: 76, 12: 72,
      16: 71, 19: 74, 22: 76, 24: 79, 28: 76,
      32: 77, 36: 76, 40: 74, 44: 72,
      48: 74, 52: 76, 56: 74, 60: 71
    };
    if (tune[s]) {
      this._playNote(tune[s], 0, 0.3, 'sine', 0.09);
    }
  }

  _heartLoop(s) {
    // Pulse driven by heartbeats
    if (s % 8 === 0) {
      this.playHeartbeat();
    }
    if (s % 4 === 2) {
      // Soft background pad tone
      const padNotes = [60, 64, 67, 71];
      this._playNote(padNotes[Math.floor(s / 16)], 0, 0.4, 'sine', 0.03);
    }
  }

  _finaleLoop(s) {
    // Emotional resolution: F -> G -> Em -> Am -> F -> G -> C
    const chordIdx = Math.floor(s / 8);
    const chords = [41, 43, 40, 45, 41, 43, 48, 48];
    if (s % 8 === 0) {
      this._playBass(chords[chordIdx], 0, 0.7);
    }
    if (s % 2 === 0) {
      this._playNote(60 + (s % 12), 0, 0.3, 'sine', 0.04);
    }
    const melody = {
      0: 65, 4: 69, 8: 71, 12: 74,
      16: 72, 20: 76, 24: 72, 28: 69,
      32: 65, 36: 67, 40: 71, 44: 74,
      48: 76, 52: 79, 56: 76, 60: 72
    };
    if (melody[s]) {
      this._playNote(melody[s], 0, 0.5, 'triangle', 0.1);
    }
  }
}

export const soundEngine = new SoundEngine();
