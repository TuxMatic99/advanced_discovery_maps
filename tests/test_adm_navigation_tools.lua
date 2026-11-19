-- P7-B2: test funcional sin motor, archivos ni lecturas de terreno.
local base = assert(arg[1], "Se requiere carpeta del mod")
local fields_cb, leave_cb = {}, {}
local last_form, last_content, last_offset
local fields_saved = {}
local player = {}
function player:get_player_name() return "singleplayer" end
function player:get_pos() return {x=5, y=42, z=9} end
function player:get_meta()
    return {get_string=function(_,key) return fields_saved[key] or "" end,
            set_string=function(_,key,value) fields_saved[key]=value end}
end
_G.minetest = {
    get_translator=function() return function(x) return x end end,
    get_current_modname=function() return "advanced_discovery_maps" end,
    formspec_escape=function(x) return x end,
    get_player_by_name=function(n) return n=="singleplayer" and player end,
    show_formspec=function(n,f,c) last_form, last_content=f,c end,
    register_on_player_receive_fields=function(cb) fields_cb[#fields_cb+1]=cb end,
    register_on_leaveplayer=function(cb) leave_cb[#leave_cb+1]=cb end,
    get_voxel_manip=function() error("Never read map in nav tools") end,
    register_chatcommand=function(_,def) assert(def.func) end,
}
_G.persistent_map = {
    tile_size=128, default_zoom_index=2, zoom_offsets={[2]={x=0,z=0}},
    player_units={singleplayer="Metros"}, active_target={singleplayer="home"},
    get_map_zoom_level=function() return 2 end,
    get_player_data=function() return {markers={home={x=2048,y=10,z=-320,name="Home"}}, discovered_tiles={["tile_-1_2"]=true}} end,
    set_map_view_offset=function(n,v) last_offset=v end,
    show_map=function(n) last_form="persistent_map:map" end,
    adm_suspend_atlas=function() end,
}
assert(loadfile(base.."/map_navigation_tools.lua"))()
local P = persistent_map
local function send(form, fields)
    for _, cb in ipairs(fields_cb) do cb(player,form,fields) end
end
local function near(a,b,epsilon) assert(math.abs(a-b)<(epsilon or 0.001), a.." != "..b) end
local m = P.adm_nav_math
near(m.distance({x=0,z=0},{x=3,z=4},"Metros").blocks,5)
assert(m.distance({x=0,z=0},{x=0,z=10},"Metros").bearing=="0.0")
assert(m.distance({x=0,z=0},{x=10,z=0},"Metros").bearing=="90.0")
assert(m.distance({x=0,z=0},{x=0,z=-10},"Metros").bearing=="180.0")
assert(m.distance({x=0,z=0},{x=-10,z=0},"Metros").bearing=="270.0")
assert(m.distance({x=0,z=0},{x=3,z=4},"Centimetros").text=="500.00 cm")
assert(m.distance({x=0,z=0},{x=3,z=4},"Kilometros").text=="0.01 km")
assert(not m.valid_coord("nan"))
assert(not m.valid_coord("30928"))
assert(m.valid_coord("-128") == -128)
-- Abrir herramientas desde Atlas.
send("persistent_map:map",{adm_nav_tools=true})
assert(last_form=="advanced_discovery_maps:navigation")
assert(last_content:find("adm_jump_go",1,true))
assert(last_content:find("adm_measure_apply",1,true))
-- A: jugador exacto, B: marcador exacto.
send(last_form,{adm_a_player=true})
send(last_form,{adm_b_marker=true})
local a,b=P.adm_nav_get_points("singleplayer")
near(a.x,5); near(a.z,9); near(b.x,2048); near(b.z,-320)
-- Conversiones persistidas: dropdown debe modificar unidad, sin tocar puntos.
send(last_form,{adm_measure_unit="Pies",adm_measure_apply=true,
    adm_a_x="0",adm_a_z="0",adm_b_x="3",adm_b_z="4"})
assert(fields_saved.adm_nav_measure_unit=="Pies")
assert(P.player_units.singleplayer=="Pies")
assert(last_content:find("16.40 ft",1,true),"No convirtió 5 m a pies")
-- Salto lejano: se centra en el cuadrante que contiene X,Z (no teletransporta).
send(last_form,{adm_jump_go=true,adm_jump_x="-257",adm_jump_z="300"})
assert(last_form=="persistent_map:map")
assert(last_offset.x == -3 and last_offset.z == 2,"Falló cálculo de salto en X negativa")
-- Selector desde el mapa: aproximado al centro del cuadrante.
send("persistent_map:map",{adm_nav_tools=true})
send(last_form,{adm_a_pick=true})
assert(last_form=="persistent_map:map")
assert(P.adm_nav_pending("singleplayer")=="a")
send("persistent_map:map",{["map_click_-1_2"]=true})
a,b=P.adm_nav_get_points("singleplayer")
assert(a.x==-64 and a.z==320)
assert(last_form=="advanced_discovery_maps:navigation")
assert(P.adm_nav_pending("singleplayer")==nil)
-- No cambiar puntos si se envían coordenadas inválidas.
send(last_form,{adm_measure_apply=true,adm_a_x="1e400",adm_a_z="100"})
a=P.adm_nav_get_points("singleplayer")
assert(a.x==-64 and a.z==320)
assert(last_content:find("Invalid coordinates",1,true))
-- Ir a marcador no afecta mundo.
send(last_form,{adm_jump_marker=true})
assert(last_offset.x==16 and last_offset.z==-3)
-- Salida: limpiar referencias.
for _, cb in ipairs(leave_cb) do cb(player) end
assert(P.adm_nav_get_points("singleplayer")==nil)
print("OK P7B2: unidades, distancia, rumbo, salto, marcadores, selección por cuadrante y limpieza")
