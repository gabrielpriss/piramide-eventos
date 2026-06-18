#!/usr/bin/env node
/**
 * Converte fotos HEIC corporativas para WebP (sm/md/lg).
 * Requer: npm install heic-decode sharp (devDependencies)
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import decode from 'heic-decode';
import sharp from 'sharp';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUT_DIR = path.join(ROOT, 'assets', 'img');
const QUALITY = 82;
const SIZES = { sm: 400, md: 800, lg: 1200 };

const SOURCES = [
  {
    file: 'IMG_0307.HEIC',
    stem: 'corporativo-treinamento-audiencia',
  },
  {
    file: 'IMG_0442.HEIC',
    stem: 'corporativo-palestra-auditorio',
  },
  {
    file: 'IMG_0443.HEIC',
    stem: 'corporativo-apresentacao-palco',
  },
];

async function convertOne({ file, stem }) {
  const src = path.join(ROOT, 'assets', file);
  if (!fs.existsSync(src)) throw new Error(`Arquivo não encontrado: ${src}`);

  const buffer = fs.readFileSync(src);
  const { width, height, data } = await decode({ buffer });
  const base = sharp(Buffer.from(data), {
    raw: { width, height, channels: 4 },
  }).rotate();

  for (const [label, targetW] of Object.entries(SIZES)) {
    const out = path.join(OUT_DIR, `${stem}-${label}.webp`);
    await base
      .clone()
      .resize({ width: targetW, withoutEnlargement: true })
      .webp({ quality: QUALITY, effort: 6 })
      .toFile(out);

    const kb = Math.round(fs.statSync(out).size / 1024);
    const meta = await sharp(out).metadata();
    console.log(`  ${path.basename(out)}  ${meta.width}x${meta.height}  ${kb}KB`);
  }
}

async function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  for (const item of SOURCES) {
    console.log(`→ ${item.file} → ${item.stem}`);
    await convertOne(item);
  }
  console.log('OK: fotos corporativas convertidas.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
