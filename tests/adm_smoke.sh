#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/test_adm_routes.py
python3 tests/test_adm_p5b_lazy.py
python3 tests/test_adm_p5c_safety.py
if command -v texlua >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    printf 'fixture' > "$tmp/tile_0_0.png"
    printf 'fixture' > "$tmp/tile_0_1.png"
    texlua tests/adm_luasyntax.lua .
    texlua tests/test_adm_media.lua . "$tmp"
    texlua tests/test_adm_p5a_timeout.lua . "$tmp"
    texlua tests/test_adm_p5c_runtime.lua .
    texlua tests/test_adm_wand_v2.lua .
    texlua tests/test_adm_wand_v3.lua .
    reference="$(mktemp)"
    git show 4d08663:map_engine_progressive.lua > "$reference"
    texlua tests/test_adm_p7a_equivalence.lua "$reference" map_engine_progressive.lua
    texlua tests/test_adm_p7b1.lua .
    texlua tests/test_adm_topography_renderer.lua .
    rm -f "$reference"
else
    echo 'AVISO: texlua no está instalado; se omiten pruebas Lua simuladas.'
fi
if command -v texlua >/dev/null 2>&1; then
    texlua tests/test_adm_navigation_tools.lua .
fi
python3 tests/test_adm_p7b2_integration.py
git diff --check
echo 'OK: comprobaciones estáticas completadas; resta probar dentro del juego.'
