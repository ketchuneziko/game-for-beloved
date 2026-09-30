// Configuration and state management for "Print I Love You: For My Beloved"

const DEFAULT_CONFIG = {
  herName: "Мария",
  herNickname: "Солнышко",
  hisName: "Твой парень",
  anniversaryDate: "Наш особенный день",
  secretWord: "LOVE",
  compliments: [
    "У тебя самая красивая улыбка на свете",
    "Твои глаза светятся теплом",
    "Рядом с тобой я дома",
    "Ты делаешь каждый мой день лучше",
    "Я обожаю то, как ты смеёшься",
    "Твои объятия — моё любимое место во Вселенной",
    "Ты самое дорогое, что у меня есть"
  ]
};

export class ConfigManager {
  constructor() {
    this.config = this.load();
    this.listeners = [];
  }

  load() {
    try {
      const saved = localStorage.getItem('pilu_love_config');
      if (saved) {
        return { ...DEFAULT_CONFIG, ...JSON.parse(saved) };
      }
    } catch (e) {
      console.warn('Failed to load config from localStorage', e);
    }
    return { ...DEFAULT_CONFIG };
  }

  save(newConfig) {
    this.config = { ...this.config, ...newConfig };
    try {
      localStorage.setItem('pilu_love_config', JSON.stringify(this.config));
    } catch (e) {
      console.warn('Failed to save config to localStorage', e);
    }
    this.notify();
  }

  reset() {
    this.config = { ...DEFAULT_CONFIG };
    try {
      localStorage.removeItem('pilu_love_config');
    } catch (e) {}
    this.notify();
  }

  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  notify() {
    for (const listener of this.listeners) {
      listener(this.config);
    }
  }

  get(key) {
    return this.config[key] ?? DEFAULT_CONFIG[key];
  }
}

export const configManager = new ConfigManager();
