-- Pruebas de integración simulada; NO sustituyen una partida en Luanti.
local root = assert(arg[1], 'ruta del paquete')
local tmp = assert(arg[2], 'carpeta temporal')
local callbacks={step={},leave={},fields={},join={}}
local commands, media_callbacks = {}, {}
local clock=0
local logs={}
local player={ids={},updates={},removed={},pos={x=45,y=12,z=64},yaw=math.pi/2}
function player:get_player_name()return 'singleplayer' end
function player:get_pos()return self.pos end
function player:get_look_horizontal()return self.yaw end
function player:hud_add(def) local id=#self.ids+1;self.ids[id]=def;return id end
function player:hud_change(id,key,value)
    self.updates[#self.updates+1]={id=id,key=key,value=value}
    if self.ids[id] then self.ids[id][key]=value end
    return true
end
function player:hud_remove(id)self.removed[#self.removed+1]=id end
local pdata={discovered_tiles={['tile_0_0']={x=0,z=0},['tile_0_1']={x=0,z=1}},markers={}}
local P={tile_size=128,map_path=tmp..'/',tile_versions={},player_map_mode={},get_player_data=function()return pdata end}
persistent_map=P
minetest={
 settings={get=function(_,key)return key=='adm_walkmap_hz' and '10' or nil end},
 get_us_time=function()return clock end,
 get_player_by_name=function(name)if name=='singleplayer' then return player end end,
 register_chatcommand=function(name,def)commands[name]=def end,
 register_globalstep=function(f)callbacks.step[#callbacks.step+1]=f end,
 register_on_leaveplayer=function(f)callbacks.leave[#callbacks.leave+1]=f end,
 register_on_player_receive_fields=function(f)callbacks.fields[#callbacks.fields+1]=f end,
 close_formspec=function()end,
 dynamic_add_media=function(opt,callback)
     assert(opt.to_player=='singleplayer')
     media_callbacks[#media_callbacks+1]={opt=opt,callback=callback}
     return true
 end,
 log=function(...)logs[#logs+1]={...}end,
}

local function tick(dt)
 clock=clock+dt*1e6
 for _,fun in ipairs(callbacks.step) do fun(dt) end
end
assert(loadfile(root..'/map_media.lua'))()
assert(loadfile(root..'/map_walk.lua'))()
assert(commands.map_movil and commands.map_movil.func)
local ok, msg = commands.map_movil.func('singleplayer','on')
assert(ok, tostring(msg))
assert(#player.ids==12,'se esperaban 12 HUD elementos')
assert(#media_callbacks==2,'se esperaban dos medios de cuadrantes')
local colored=0
for _,elem in ipairs(player.ids) do
 if elem.name=='ADM tile' and elem.text~='adm_empty.png' then colored=colored+1 end
end
assert(colored==0,'PNG usado ANTES del callback')
local after_first=#player.updates
-- Antes de 100 ms no hay un nuevo ciclo; a 100 ms sí.
tick(0.05)
assert(#player.updates==after_first,'frecuencia no limitada')
media_callbacks[1].callback('singleplayer')
tick(0.06)
local shown=0
for _,elem in ipairs(player.ids) do
 if elem.name=='ADM tile' and elem.text~='adm_empty.png' then shown=shown+1 end
end
assert(shown==1,'primera imagen no aparece tras la confirmacion: '..shown)
media_callbacks[2].callback('singleplayer')
tick(0.11)
shown=0
for _,elem in ipairs(player.ids) do
 if elem.name=='ADM tile' and elem.text~='adm_empty.png' then shown=shown+1 end
end
assert(shown==2,'segunda imagen no aparece tras la confirmacion')

-- Un cambio de version NO debe mostrar el nuevo PNG hasta su confirmacion.
P.tile_versions['tile_0_0']=1
local fh=assert(io.open(tmp..'/tile_0_0_v1.png','wb'));fh:write('test');fh:close()
tick(0.90)
assert(#media_callbacks==3,'no se solicito la version nueva')
local active_v1=0
for _,elem in ipairs(player.ids) do
 if elem.text=='tile_0_0_v1.png' then active_v1=active_v1+1 end
end
assert(active_v1==0,'version sin recibir se mostro anticipadamente')
media_callbacks[3].callback('singleplayer')
tick(0.12)
for _,elem in ipairs(player.ids) do
 if elem.text=='tile_0_0_v1.png' then active_v1=active_v1+1 end
end
assert(active_v1==1,'version confirmada no se mostro')

-- Posiciones negativas y movimiento no deben disparar nuevas transferencias por fotograma.
player.pos={x=-12,y=12,z=-22}
local n0=#media_callbacks
tick(0.11)
tick(0.11)
assert(#media_callbacks==n0,'se pidieron medios no descubiertos')
local good,err=commands.map_movil.func('singleplayer','bad')
assert(good==false,'se acepto argumento invalido')
assert(commands.map_movil.func('singleplayer','off'))
assert(#player.removed==12,'HUD no retirado por completo')
commands.map_movil.func('singleplayer','on')
assert(#player.ids==24,'activar de nuevo no recreo HUD')
for _,f in ipairs(callbacks.leave)do f(player)end
assert(P.media_epoch('singleplayer')==0,'cache no vaciada al desconectar')
print('OK: entrega por callback, sin dummy anticipado, versionado, 10 Hz, coordenadas negativas, apagado y limpieza')
