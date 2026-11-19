from pathlib import Path
root=Path(__file__).resolve().parents[1]
ui=(root/'map_ui_modern.lua').read_text(encoding='utf-8')
init=(root/'init.lua').read_text(encoding='utf-8')
module=(root/'map_navigation_tools.lua').read_text(encoding='utf-8')
assert ui.count('adm_nav_tools;') == 1
assert 'P.adm_nav_get_points(player_name)' in ui
assert 'function P.adm_suspend_atlas(name)' in ui
assert 'map_navigation_tools.lua' in init
assert 'map_topography.lua' in init
assert 'register_chatcommand("regla"' in module
assert 'P.set_map_view_offset(name' in module
assert 'map_click_(-?%d+)_(-?%d+)' in module
assert not any(n in module for n in ['get_voxel_manip(', 'set_node(', 'remove_node('])
print('OK P7-B2: integración del Atlas y módulo sin modificaciones del mundo')
