#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"

echo "→ Build produção (versão dark) para Cloudflare Pages"

rm -rf "$DIST"
mkdir -p "$DIST/assets/img"

cp "$ROOT/index.html" "$DIST/index.html"

cp "$ROOT/assets/reviews-carousel.css" "$DIST/assets/"
cp "$ROOT/assets/reviews-carousel.js" "$DIST/assets/"
cp "$ROOT/assets/site-config.js" "$DIST/assets/"

for img in "$ROOT/assets/img"/*.webp; do
  [[ -f "$img" ]] || continue
  cp "$img" "$DIST/assets/img/"
done

cat > "$DIST/_headers" << 'EOF'
/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin

/assets/*
  Cache-Control: public, max-age=31536000, immutable

/index.html
  Cache-Control: public, max-age=0, must-revalidate
EOF

cat > "$DIST/404.html" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Página não encontrada | Espaço Pirâmide Eventos</title>
  <meta http-equiv="refresh" content="3;url=/">
  <style>
    body { margin: 0; min-height: 100vh; display: grid; place-items: center;
      background: #050505; color: #e0e0e0; font-family: system-ui, sans-serif; text-align: center; padding: 2rem; }
    a { color: #D4AF37; }
  </style>
</head>
<body>
  <div>
    <h1>Página não encontrada</h1>
    <p>Redirecionando para a página inicial…</p>
    <p><a href="/">Voltar agora</a></p>
  </div>
</body>
</html>
EOF

BYTES=$(du -sh "$DIST" | cut -f1)
FILES=$(find "$DIST" -type f | wc -l)
echo "✓ Build concluído: $DIST ($BYTES, $FILES arquivos)"
