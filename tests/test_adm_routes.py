#!/usr/bin/env python3
"""Auditoría conservadora de rutas de controles. Solo confirma presencia de rutas de código."""
import pathlib, sys, re
root=pathlib.Path(sys.argv[1] if len(sys.argv)>1 else '.').resolve()
ui=(root/'map_ui_modern.lua').read_text(encoding='utf-8')
init=(root/'init.lua').read_text(encoding='utf-8')
party=(root/'map-party-gui.lua').read_text(encoding='utf-8')
walk=(root/'map_walk.lua').read_text(encoding='utf-8')
marker=(root/'marker-gui.lua').read_text(encoding='utf-8')
controls={
  'norte':('nav_north',ui,init),'sur':('nav_south',ui,init),
  'este':('nav_east',ui,init),'oeste':('nav_west',ui,init),
  'centrar':('nav_center',ui,init),'zoom_in':('zoom_in',ui,init),
  'zoom_out':('zoom_out',ui,init),'capas':('toggle_map_mode',ui,init),
  'cuadricula':('toggle_grid',ui,init),'unidades':('unidad_selector',ui,init),
  'marcador':('add_marker_',ui,init),'editar marcadores':('manage_markers',ui,init),
  'destino':('target_selector',ui,init),'perfil X':('perfil_x',ui,init),
  'perfil Z':('perfil_z',ui,init),'equipos':('party_gui',ui,party),
  'mapa movil':('adm_walk_switch',ui,walk),'clic en mapa':('map_click_',ui,init),
}
errors=[]
for description,(field,gui,handler) in controls.items():
  if field not in gui or field not in handler:
    errors.append(description+': faltan referencias '+field)
  else:
    print('[RUTA] '+description)
print('Comprobación adicional de rutas secundarias:',
    'marker_gui' if 'persistent_map:marker_gui' in marker else 'NO marker_gui')
if errors:
  for e in errors:print('[FALLO] '+e)
  sys.exit(1)
print('OK: 18 controles del Atlas conectados por nombre a manejadores; NO prueba clics reales')
