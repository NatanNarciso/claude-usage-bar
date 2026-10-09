#!/bin/zsh
# Publica a pasta wiki/ na Wiki do GitHub.
# Pré-requisito: ativar a Wiki no repositório e criar a primeira página pela interface
# (o repositório <repo>.wiki.git só existe depois disso).
# Uso: ./scripts/publish-wiki.sh git@github.com:USER/claude-usage-bar.wiki.git
set -e
[[ -n "$1" ]] || { echo "Uso: $0 <url do .wiki.git>"; exit 1; }
cd "$(dirname "$0")/.."
TMP=$(mktemp -d)
git clone "$1" "$TMP"
rsync -a --delete --exclude .git wiki/ "$TMP"/
cd "$TMP" && git add -A && git commit -m "Update wiki" && git push
