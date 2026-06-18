#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"

echo "→ Build produção (dist/)"

rm -rf "$DIST"
mkdir -p "$DIST/assets/img"

# Páginas HTML
for page in index.html index-light.html index-mixed.html index-dark.html index-dark-form.html; do
  if [[ -f "$ROOT/$page" ]]; then
    cp "$ROOT/$page" "$DIST/$page"
  fi
done

# Assets estáticos
cp "$ROOT/assets/reviews-carousel.css" "$DIST/assets/"
cp "$ROOT/assets/reviews-carousel.js" "$DIST/assets/"
cp "$ROOT/assets/site-config.js" "$DIST/assets/"

# Imagens da página hub (logo e previews)
shopt -s nullglob
hub_imgs=("$ROOT/assets/logoTransparente.png" "$ROOT/assets/print-"*.png)
if [[ ${#hub_imgs[@]} -gt 0 ]]; then
  cp "${hub_imgs[@]}" "$DIST/assets/"
fi

# Imagens WebP (todas as variantes do site)
shopt -s nullglob
imgs=("$ROOT/assets/img/"*.webp)
if [[ ${#imgs[@]} -eq 0 ]]; then
  echo "ERRO: nenhuma imagem em assets/img/" >&2
  echo "Execute: python3 scripts/optimize-images.py" >&2
  exit 1
fi
cp "${imgs[@]}" "$DIST/assets/img/"

# Produção: index.html é a versão dark principal
cat > "$DIST/_redirects" << 'EOF'
/index-dark.html /index.html 301
EOF

# Cache (Cloudflare Pages; na Vercel use vercel.json na raiz)
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
