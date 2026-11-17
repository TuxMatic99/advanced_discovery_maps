#!/usr/bin/env python3
"""Asegura que recuperamos funciones y no dos implementaciones."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=(root/'init.lua').read_text()
feature=(root/'adm_funciones_restauradas.lua').read_text()
assert source.count('dofile(modpath .. "/adm_funciones_restauradas.lua")') == 1
assert '::continue::' not in source
assert 'local function tuxmatic_sync_boom' not in source
assert 'local function tuxmatic_async_layer' not in source
assert 'minetest.register_chatcommand("nv", {' not in source
assert 'core.register_chatcommand("nv", {' in feature
assert 'core.register_tool("advanced_discovery_maps:tuxmatic_wand",{' in feature
for s in ['core.register_lbm','core.is_protected','core.register_privilege','core.after','core.get_voxel_manip','core.swap_node','restore_key','adm_wand_cancel','core.get_mod_storage']:
    assert s in feature,s
assert not 'temporarily disabled for world safety' in feature
print('OK P5C-R: faros reales, varita activa, proteccion y recuperación')
