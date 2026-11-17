-- Regresión P5A: los timeouts liberan las plazas aun sin solicitar la misma imagen.
local root = assert(arg[1], "ruta del mod")
local tmp = assert(arg[2], "directorio temporal")
local t, downloads, steps, leave = 0, {}, {}, {}
local player = {get_player_name = function() return "test_player" end}

persistent_map = {map_path = tmp .. "/"}
minetest = {
    get_us_time = function() return t end,
    get_player_by_name = function(name) if name == "test_player" then return player end end,
    dynamic_add_media = function(opts, callback)
        downloads[#downloads + 1] = {opts = opts, callback = callback}
        return true
    end,
    register_globalstep = function(callback) steps[#steps + 1] = callback end,
    register_on_leaveplayer = function(callback) leave[#leave + 1] = callback end,
}

assert(loadfile(root .. "/map_media.lua"))()

for i = 1, 4 do
    local file = string.format("tile_%d_0.png", i)
    local f = assert(io.open(tmp .. "/" .. file, "wb"))
    f:write("PNG mock")
    f:close()
end
for i = 1, 3 do
    assert(persistent_map.media_request("test_player", "tile_" .. i .. "_0.png") == false)
end
assert(#downloads == 3)
assert(not persistent_map.media_request("test_player", "tile_4_0.png"))
assert(#downloads == 3, "la cuarta textura no debe iniciar si hay 3 pendientes")

-- Han transcurrido 16 s; el jugador ya no solicita ninguno de los 3 anteriores.
t = 16000000
for _, step in ipairs(steps) do step(1.01) end
assert(not persistent_map.media_request("test_player", "tile_4_0.png"))
assert(#downloads == 4, "el mantenimiento debe liberar espacio para otra textura")
downloads[4].callback("test_player")
assert(persistent_map.media_is_ready("test_player", "tile_4_0.png"))

-- El callback de un medio antiguo también puede llegar después del timeout.
downloads[1].callback("test_player")
assert(persistent_map.media_is_ready("test_player", "tile_1_0.png"))

for _, f in ipairs(leave) do f(player) end
assert(persistent_map.media_epoch("test_player") == 0)
print("OK P5A: liberación de cupos, callback tardío y limpieza al desconectar")
