#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
SOURCE_FORM="$ROOT/index-dark-form.html"
SOURCE_WA="$ROOT/index.html"

echo "→ Build produção (dist/) — Cloudflare Pages"

rm -rf "$DIST"
mkdir -p "$DIST/assets/img" "$DIST/form"

# Página principal (foco WhatsApp)
cp "$SOURCE_WA" "$DIST/index.html"

# Página /form (com formulário de orçamento)
cp "$SOURCE_FORM" "$DIST/form/index.html"

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
/index-dark-form.html /form 301
/index-dark.html / 301
/index-light.html / 301
/index-mixed.html / 301
/index-legacy.html / 301
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

/form/
  Cache-Control: public, max-age=0, must-revalidate

/assets/*
  Cache-Control: public, max-age=31536000, immutable
EOF

# SEO: robots.txt
cat > "$DIST/robots.txt" << 'EOF'
User-agent: *
Allow: /

Sitemap: https://xn--espaopiramideeventos-60b.com.br/sitemap.xml
EOF

# SEO: sitemap.xml
cat > "$DIST/sitemap.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://xn--espaopiramideeventos-60b.com.br/</loc>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://xn--espaopiramideeventos-60b.com.br/form</loc>
    <changefreq>monthly</changefreq>
    <priority>0.7</priority>
  </url>
</urlset>
EOF

# AI indexing: llms.txt
cat > "$DIST/llms.txt" << 'EOF'
# Espaço Pirâmide Eventos

> Salão de eventos premium no Pilarzinho, Curitiba (PR). Ideal para casamentos, debutantes (15 anos), formaturas, aniversários e corporativos, com capacidade para até 200 convidados.

## Sobre

Fundado há 7 anos pela família Pirâmide, o espaço é gerenciado por Vinicius e Tatiana, que lideram uma equipe especializada em celebrações inesquecíveis. Localizado na Rua Orestes Beltrami, 330 — Pilarzinho, Curitiba - PR.

## Tipos de Evento

- Aniversários e festas familiares
- Debutantes / Festas de 15 Anos
- Casamentos e recepções
- Formaturas
- Eventos corporativos

## Estrutura

- Capacidade: até 200 convidados
- Pista de dança com iluminação LED
- Buffet completo e alta gastronomia
- DJ da casa
- Staff especializado
- Assessoria de evento
- Estacionamento

## Contato

- WhatsApp: (41) 98890-9600 — https://wa.me/5541988909600
- Orçamento online: https://xn--espaopiramideeventos-60b.com.br/form
- Avaliação: 5 estrelas no Google

## Páginas

- / — Página principal com contato via WhatsApp
- /form — Formulário de solicitação de orçamento
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
done < <(grep -hoE 'assets/[^"'"'"'[:space:]]+' "$SOURCE_FORM" "$SOURCE_WA" | sort -u)

if [[ $missing -gt 0 ]]; then
  echo "ERRO: $missing asset(s) faltando — corrija antes do deploy." >&2
  exit 1
fi

BYTES=$(du -sh "$DIST" | cut -f1)
FILES=$(find "$DIST" -type f | wc -l)
echo "✓ Build concluído: $DIST ($BYTES, $FILES arquivos, $copied imagens)"
echo "  → /       = index.html (foco WhatsApp)"
echo "  → /form   = formulário de orçamento"
