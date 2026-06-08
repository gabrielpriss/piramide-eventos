#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
SRC_HTML="$ROOT/index-dark.html"

echo "→ Build versão dark para Cloudflare Pages"

rm -rf "$DIST"
mkdir -p "$DIST/assets/img"

# Página principal
sed \
  -e 's/Espaço Pirâmide Eventos | Premium Dark/Espaço Pirâmide Eventos | Curitiba/' \
  "$SRC_HTML" > "$DIST/index.html"

# Assets estáticos
cp "$ROOT/assets/reviews-carousel.css" "$DIST/assets/"
cp "$ROOT/assets/reviews-carousel.js" "$DIST/assets/"
cp "$ROOT/assets/site-config.js" "$DIST/assets/"

# Imagens WebP usadas na versão dark
IMAGES=(
  logo-sm.webp logo-lg.webp
  AR2A0823-xl.webp AR2A0823-lg.webp AR2A0823-md.webp
  BL7A8783-lg.webp BL7A8783-md.webp
  IMG_1747-lg.webp IMG_1747-md.webp
  BL7A8780-lg.webp BL7A8780-md.webp
  IMG_9853-lg.webp
  AR2A0826-lg.webp
  IMG_9851-lg.webp
  BL7A8787-lg.webp
)

for img in "${IMAGES[@]}"; do
  src="$ROOT/assets/img/$img"
  if [[ ! -f "$src" ]]; then
    echo "ERRO: imagem ausente: $src" >&2
    echo "Execute: python3 scripts/optimize-images.py" >&2
    exit 1
  fi
  cp "$src" "$DIST/assets/img/"
done

# Cache e segurança (Cloudflare Pages)
cat > "$DIST/_headers" << 'EOF'
/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin

/assets/*
  Cache-Control: public, max-age=31536000, immutable

/index.html
  Cache-Control: public, max-age=0, must-revalidate
EOF

# Página 404 (Cloudflare Pages serve automaticamente)
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
