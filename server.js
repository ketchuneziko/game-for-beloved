import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PORT = process.env.PORT || 3000;
const PUBLIC_DIR = path.join(__dirname, 'web');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.wav': 'audio/wav',
  '.mp3': 'audio/mpeg',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.ico': 'image/x-icon'
};

function generateSingleFileHtml() {
  const indexHtml = fs.readFileSync(path.join(PUBLIC_DIR, 'index.html'), 'utf-8');
  let css = fs.readFileSync(path.join(PUBLIC_DIR, 'src/style.css'), 'utf-8');
  
  // Replace relative asset URLs in CSS if needed
  css = css.replace("url('../assets/PressStart2P-Regular.woff2')", "url('assets/PressStart2P-Regular.woff2')");
  css = css.replace("url('../assets/JetBrainsMono-Regular.ttf')", "url('assets/JetBrainsMono-Regular.ttf')");
  css = css.replace("url('../assets/JetBrainsMono-Bold.ttf')", "url('assets/JetBrainsMono-Bold.ttf')");

  // Read JS files
  const configJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/config.js'), 'utf-8');
  const audioJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/audio.js'), 'utf-8');
  const artJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/art.js'), 'utf-8');
  const desktopJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/desktop.js'), 'utf-8');
  const gameJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/game.js'), 'utf-8');
  const mainJs = fs.readFileSync(path.join(PUBLIC_DIR, 'src/main.js'), 'utf-8');

  // Strip imports/exports to create a combined bundle
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

  const imgMap = [
    'assets/characters/boyfriend_pixel.png',
    'assets/characters/girlfriend_pixel.png',
    'assets/characters/couple_pixel.png',
    'assets/characters/couple_date_night.png',
    'assets/characters/girlfriend_portrait.png',
    'assets/characters/boyfriend_portrait.png'
  ];

  for (const rel of imgMap) {
    const fullPath = path.join(PUBLIC_DIR, rel);
    if (fs.existsSync(fullPath)) {
      const b64 = fs.readFileSync(fullPath).toString('base64');
      const dataUri = `data:image/png;base64,${b64}`;
      bundled = bundled.split(rel).join(dataUri);
    }
  }

  return bundled;
}

const server = http.createServer((req, res) => {
  // Allow all preview hosts
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  let reqPath = decodeURIComponent(req.url.split('?')[0]);
  
  if (reqPath === '/export-single-file') {
    try {
      const html = generateSingleFileHtml();
      res.statusCode = 200;
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.setHeader('Content-Disposition', 'attachment; filename="PRINT_I_LOVE_YOU_OFFLINE.html"');
      res.end(html);
    } catch (e) {
      res.statusCode = 500;
      res.end(`Export error: ${e.message}`);
    }
    return;
  }

  if (reqPath === '/') reqPath = '/index.html';

  const filePath = path.join(PUBLIC_DIR, reqPath);

  // Security: prevent path traversal outside PUBLIC_DIR
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.statusCode = 403;
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.statusCode = 404;
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.end('Not Found');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.statusCode = 200;
    res.setHeader('Content-Type', contentType);
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[LoveOS] Server listening on http://0.0.0.0:${PORT}`);
});
