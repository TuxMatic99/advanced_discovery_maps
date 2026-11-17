#!/usr/bin/env python3
"""P5B: verifica rutas de entrega bajo demanda sin simular el cliente Luanti."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
src = (root / 'init.lua').read_text(encoding='utf-8')
ui = (root / 'map_ui_modern.lua').read_text(encoding='utf-8')
eng = (root / 'map_engine_progressive.lua').read_text(encoding='utf-8')
media = (root / 'map_media.lua').read_text(encoding='utf-8')
walk = (root / 'map_walk.lua').read_text(encoding='utf-8')

checks = {
    'arranque con carga diferida opcional': 'adm_lazy_media' in src and 'Reloaded standard tile' in src,
    'solicitud por cuadrante descubierto': 'persistent_map.media_request(player_name, tile_id .. ".png")' in src,
    'generador evita difusión cuando es diferido': 'if not minetest.settings:get_bool("adm_lazy_media", true) then' in eng,
    'interfaz solicita medios visibles': 'P.media_request(player_name, file_base .. ".png")' in ui,
    'interfaz admite reintento': 'state.waiting and state.elapsed >= 1.5' in ui,
    'interfaz deja de actualizarse al cerrar': 'atlas_sessions[player:get_player_name()] = nil' in ui,
    'minimapa solicita por jugador': 'P.media_request(player:get_player_name(), file)' in walk,
    'P5A recupera envíos pendientes': 'housekeeping_elapsed' in media,
}
for label, ok in checks.items():
    if not ok:
        raise AssertionError('FALLÓ: ' + label)
    print('OK:', label)
print('OK P5B: rutas de medios verificadas (NO son pruebas de clics reales).')
