#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
SOURCE="$ROOT/index-dark-form.html"

echo "→ Build produção (dist/) — Cloudflare Pages"

rm -rf "$DIST"
mkdir -p "$DIST/assets/img"

# Página de produção
cp "$SOURCE" "$DIST/index.html"

# Assets estáticos
cp "$ROOT/assets/reviews-carousel.css" "$DIST/assets/"
cp "$ROOT/assets/reviews-carousel.js" "$DIST/assets/"
cp "$ROOT/assets/site-config.js" "$DIST/assets/"

# Imagens WebP (ignora duplicatas de desenvolvimento)
shopt -s nullglob
copied=0
for img in "$ROOT/assets/img/"*.webp; do
  base="$(basename "$img")"
  [[ "$base" == *" copy."* ]] && continue
  cp "$img" "$DIST/assets/img/"
  copied=$((copied + 1))
done
if [[ $copied -eq 0 ]]; then
  echo "ERRO: nenhuma imagem em assets/img/" >&2
  echo "Execute: python3 scripts/optimize-images.py" >&2
  exit 1
fi

# Redireciona URLs antigas para a home
cat > "$DIST/_redirects" << 'EOF'
/index-dark-form.html / 301
/index-dark.html / 301
/index-light.html / 301
/index-mixed.html / 301
/index-legacy.html / 301
/index.html / 301
EOF

# Headers de segurança e cache (Cloudflare Pages)
cat > "$DIST/_headers" << 'EOF'
/*
  X-Content-Type-Options: nosniff
  X-Frame-Options: SAMEORIGIN
  Referrer-Policy: strict-origin-when-cross-origin

/
  Cache-Control: public, max-age=0, must-revalidate

/index.html
  Cache-Control: public, max-age=0, must-revalidate

/assets/*
  Cache-Control: public, max-age=31536000, immutable
EOF

# Página 404
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

# Validação: todos os assets referenciados existem no dist
missing=0
while IFS= read -r ref; do
  [[ -f "$DIST/$ref" ]] || { echo "ERRO: asset ausente no build: $ref" >&2; missing=$((missing + 1)); }
done < <(grep -oE 'assets/[^"'"'"'[:space:]]+' "$SOURCE" | sort -u)

if [[ $missing -gt 0 ]]; then
  echo "ERRO: $missing asset(s) faltando — corrija antes do deploy." >&2
  exit 1
fi

BYTES=$(du -sh "$DIST" | cut -f1)
FILES=$(find "$DIST" -type f | wc -l)
echo "✓ Build concluído: $DIST ($BYTES, $FILES arquivos, $copied imagens)"
