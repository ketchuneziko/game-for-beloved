import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PUBLIC_DIR = path.join(__dirname, '..', 'web');

function buildOffline() {
  const indexHtml = fs.readFileSync(path.join(PUBLIC_DIR, 'index.html'), 'utf-8');
  let css = fs.readFileSync(path.join(PUBLIC_DIR, 'src/style.css'), 'utf-8');
  
  // Convert fonts to base64 for truly standalone offline experience!
  const woff2Path = path.join(PUBLIC_DIR, 'assets/PressStart2P-Regular.woff2');
  if (fs.existsSync(woff2Path)) {
    const woff2Base64 = fs.readFileSync(woff2Path).toString('base64');
    css = css.replace(
      "url('../assets/PressStart2P-Regular.woff2') format('woff2')",
      `url('data:font/woff2;base64,${woff2Base64}') format('woff2')`
    );
  }

  // Read JS files
  const configJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/config.js'), 'utf-8');
  const audioJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/audio.js'), 'utf-8');
  const artJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/art.js'), 'utf-8');
  const desktopJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/desktop.js'), 'utf-8');
  const gameJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/game.js'), 'utf-8');
  const mainJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/main.js'), 'utf-8');

  const stripModules = (code) => {
    return code
      .replace(/import\s+[\s\S]*?from\s+['"][^'"]+['"];?/g, '')
      .replace(/export\s+class\s+/g, 'class ')
      .replace(/export\s+const\s+/g, 'const ')
      .replace(/export\s+default\s+/g, '');
  };

  const combinedJs = `
    (function() {
      ${stripModules(configJs)}
      ${stripModules(audioJs)}
      ${stripModules(artJs)}
      ${stripModules(desktopJs)}
      ${stripModules(gameJs)}
      ${stripModules(mainJs)}
    })();
  `;

  let bundled = indexHtml
    .replace('<link rel="stylesheet" href="src/style.css">', `<style>${css}</style>`)
    .replace('<script type="module" src="src/main.js"></script>', `<script>${combinedJs}</script>`);

  const outPath = path.join(__dirname, '..', 'PRINT_I_LOVE_YOU_OFFLINE.html');
  fs.writeFileSync(outPath, bundled, 'utf-8');
  console.log(`[Success] Bundled standalone offline game to ${outPath}`);
}

buildOffline();
