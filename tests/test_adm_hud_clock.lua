-- Prueba P6: solo sensor/HUD/reloj, sin abrir una ventana de Luanti.
local root = assert(arg[1], 'indicar ruta del repositorio')
local calls = {join={}, leave={}, step={}}
local commands = {}
local t = 0.25 -- 06:00
local samples = 0
local changes = {}
local ids, meta = {}, {}
local player = {pos={x=0,y=12,z=0}}
function player:get_player_name() return 'singleplayer' end
function player:get_pos() return self.pos end
function player:get_meta() return {
    get_string=function(_, k) return meta[k] or '' end,
    set_string=function(_, k, v) meta[k] = v end,
} end
function player:hud_add(def)
    -- Emula la validacion estricta de vectores que usa Luanti 5.18.
    for _, field in ipairs({"position", "alignment", "offset", "size"}) do
        local v = def[field]
        assert(type(v) == "table" and type(v.x) == "number"
            and type(v.y) == "number",
            "HUD " .. tostring(field) .. " carece de x/y numericos")
    end
    local id = #ids + 1
    ids[id] = def
    return id
end
function player:hud_change(id, key, val)
    assert(ids[id] and not ids[id].removed, 'hud_change sobre ID invalido')
    ids[id][key] = val
    changes[#changes+1] = {id=id,key=key,value=val}
    return true
end
function player:hud_remove(id)
    assert(ids[id], 'HUD inexistente')
    ids[id].removed=true
end
local function translate(text,...)
    local args={...}
    return (text:gsub('@(%d+)',function(n) return tostring(args[tonumber(n)] or '?') end))
end
minetest={
    get_current_modname=function() return 'advanced_discovery_maps' end,
    get_translator=function() return translate end,
    get_mapgen_setting=function(k) if k=='mg_name' then return 'v7' end return '' end,
    get_biome_data=function(pos) samples=samples+1; return {biome=9,heat=37.5+pos.x,humidity=62.3} end,
    get_biome_name=function() return 'Forest' end,
    get_timeofday=function() return t end,
    settings={get=function(_,k) return nil end},
    register_globalstep=function(f) calls.step[#calls.step+1]=f end,
    register_on_joinplayer=function(f) calls.join[#calls.join+1]=f end,
    register_on_leaveplayer=function(f) calls.leave[#calls.leave+1]=f end,
    register_chatcommand=function(n,d) commands[n]=d end,
    get_player_by_name=function(n) if n=='singleplayer' then return player end end,
    log=function() end,
}
persistent_map={}
assert(loadfile(root..'/biome_sensor.lua'))()
assert(commands.reloj and commands.bioma,'faltan comandos')
for _,f in ipairs(calls.join) do f(player) end
assert(#ids==1, 'solo reloj por defecto')
assert(ids[1].text=='Game time: 06:00', 'hora inicial incorrecta: '..tostring(ids[1].text))
assert(ids[1].style==1, 'tipografia de reloj no resaltada')
local ok, msg = commands.bioma.func('singleplayer','hud')
assert(ok, tostring(msg))
assert(#ids==4,'el HUD de bioma debe tener 3 lineas')
assert(ids[2].text=='Biome: Forest')
assert(ids[3].text:find('Heat: 37.50',1,true),'falta temperatura/calor')
assert(ids[3].text:find('Humidity: 62.30',1,true),'falta humedad')
assert(ids[4].text=='Mapgen: v7')
assert(ids[1].offset.y==78, 'el reloj debe separarse del bioma')
local before = samples
for _,f in ipairs(calls.step) do f(1.1) end
assert(samples==before,'movimiento estacionario no debe consultar bioma')
t=0.5
for _,f in ipairs(calls.step) do f(1.1) end
assert(ids[1].text=='Game time: 12:00','hora del juego desactualizada')
player.pos.x = 8
for _,f in ipairs(calls.step) do f(2.1) end
assert(samples==before+1,'no se consulto bioma al desplazarse')
assert(ids[3].text:find('45.50',1,true),'informacion del bioma desactualizada')
ok,msg=commands.reloj.func('singleplayer','off')
assert(ok and ids[1].removed and meta.adm_clock_hud=='0','no se desactiva reloj')
ok,msg=commands.bioma.func('singleplayer','hud')
assert(ok and ids[2].removed and ids[3].removed and ids[4].removed,'no se desactiva bioma')
ok,msg=commands.reloj.func('singleplayer','on')
assert(ok and ids[5].text=='Game time: 12:00' and ids[5].offset.y==0, 'reloj independiente del bioma')
local oops=commands.reloj.func('singleplayer','mal')
assert(not oops, 'debe rechazar parametros invalidos')
for _,f in ipairs(calls.leave) do f(player) end
print('OK P6: HUD legible, bioma extendido, reloj 24h, actualizacion eficiente, comandos y limpieza')
