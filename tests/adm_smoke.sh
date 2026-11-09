#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/test_adm_routes.py
if command -v texlua >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    printf 'fixture' > "$tmp/tile_0_0.png"
    printf 'fixture' > "$tmp/tile_0_1.png"
    texlua tests/adm_luasyntax.lua .
    texlua tests/test_adm_media.lua . "$tmp"
else
    echo 'AVISO: texlua no está instalado; se omiten pruebas Lua simuladas.'
fi
git diff --check
echo 'OK: comprobaciones estáticas completadas; resta probar dentro del juego.'
