-- Advanced Discovery Maps: sensor de biomas (etapa 1).
-- Compatible con las APIs de Luanti 5.10 y 5.18.
-- Inspirado en la API biomeinfo de Wuzzy (licencia MIT).
-- Implementacion independiente; no crea ni modifica nodos ni genera terreno.

local core = minetest
local modname = core.get_current_modname()
local S = core.get_translator(modname)
local P = persistent_map

local sensor = {}
P.biome_sensor = sensor

local mapgen = core.get_mapgen_setting("mg_name") or ""
local is_v6 = mapgen == "v6"

-- Los biomas v6 se basan en ruidos internos, no en los biomas registrados
-- por los juegos. Las fronteras con biomeblend son aproximadas.
local v6 = {
    ready = false,
    valid = false,
    heat_noise = nil,
    humidity_noise = nil,
}

local v6_default_heat = {
    offset = 0, scale = 1,
    spread = {x = 500, y = 500, z = 500},
    seed = 9130, octaves = 3, persistence = 0.5,
    lacunarity = 2, flags = "eased",
}
local v6_default_humidity = {
    offset = 0.5, scale = 0.5,
    spread = {x = 500, y = 500, z = 500},
    seed = 72384, octaves = 3, persistence = 0.5,
    lacunarity = 2, flags = "eased",
}

local function parse_v6_flags()
    local flags = core.get_mapgen_setting("mgv6_spflags") or ""
    local snow, jungles = true, true
    local has_blend = true
    for token in flags:gmatch("[^,]+") do
        local flag = token:match("^%s*(.-)%s*$")
        if flag == "nosnowbiomes" then snow = false
        elseif flag == "snowbiomes" then snow = true
        elseif flag == "nojungles" then jungles = false
        elseif flag == "jungles" then jungles = true
        elseif flag == "nobiomeblend" then has_blend = false
        elseif flag == "biomeblend" then has_blend = true
        end
    end
    if snow then jungles = true end
    return snow, jungles, has_blend
end

local snow_biomes, jungles_enabled, biome_blend = parse_v6_flags()
local freq_desert = tonumber(core.get_mapgen_setting("mgv6_freq_desert") or "") or 0.45

local function get_noiseparams(name, fallback)
    if core.get_mapgen_setting_noiseparams then
        local ok, value = pcall(core.get_mapgen_setting_noiseparams, name)
        if ok and type(value) == "table" then
            return value
        end
    end
    return fallback
end

local function initialize_v6()
    if v6.ready then return v6.valid end
    v6.ready = true
    if type(core.get_perlin) ~= "function" then return false end

    local heat_params = get_noiseparams("mgv6_np_biome", v6_default_heat)
    local humid_params = get_noiseparams("mgv6_np_humidity", v6_default_humidity)
    local ok1, heat = pcall(core.get_perlin, heat_params)
    local ok2, humidity = pcall(core.get_perlin, humid_params)
    if not (ok1 and ok2 and heat and humidity) then
        core.log("warning", "[advanced_discovery_maps] No se pudo inicializar el sensor de biomas v6")
        return false
    end
    v6.heat_noise = heat
    v6.humidity_noise = humidity
    v6.heat_spread = heat_params.spread or v6_default_heat.spread
    v6.valid = true
    return true
end

local function sample_v6(pos)
    if not initialize_v6() then return nil end
    local x, z = math.floor(pos.x), math.floor(pos.z)
    local spread = v6.heat_spread
    local heat = v6.heat_noise:get_2d({
        x = x + spread.x * 0.6, y = z + spread.z * 0.2,
    })
    local humidity = v6.humidity_noise:get_2d({x = x, y = z})
    if type(heat) ~= "number" or type(humidity) ~= "number" then
        return nil
    end

    local name
    if snow_biomes then
        if heat > 0.4 then
            name = humidity > 0.5 and "Jungle" or "Desert"
        elseif heat < -0.4 then
            name = humidity > 0.5 and "Taiga" or "Tundra"
        else
            name = "Normal"
        end
    elseif heat > freq_desert then
        name = "Desert"
    elseif jungles_enabled and humidity > 0.75 then
        name = "Jungle"
    else
        name = "Normal"
    end
    return {
        name = name,
        heat = heat,
        humidity = humidity,
        generator = "v6",
        -- La aproximacion no reproduce la transicion aleatoria biomeblend.
        approximate = biome_blend,
    }
end

--- Devuelve una muestra puntual. No escanea ni carga terreno.
--- En v6, calor y humedad son valores de ruido (no grados ni porcentajes).
--- En otros mapgens se devuelven los valores nativos del motor.
function sensor.get_at(pos)
    if not pos or not pos.x or not pos.y or not pos.z then return nil end
    if is_v6 then return sample_v6(pos) end
    if type(core.get_biome_data) ~= "function" then return nil end

    local data = core.get_biome_data(pos)
    if not data or data.biome == nil then return nil end
    local name = core.get_biome_name(data.biome)
    if not name or name == "" then return nil end
    return {
        name = name,
        id = data.biome,
        heat = data.heat,
        humidity = data.humidity,
        generator = mapgen,
        approximate = false,
    }
end

local huds = {}  -- Solo jugadores con HUD habilitado.
local META_HUD = "adm_biome_hud"

local function hud_text(info)
    local label = info and info.name or S("Unknown")
    if info and info.approximate then label = label .. " ~" end
    return S("Biome: @1", label)
end

local function update_hud(player, record)
    local pos = player:get_pos()
    if not pos then return end
    local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
    if record.x == x and record.y == y and record.z == z then return end
    record.x, record.y, record.z = x, y, z
    local info = sensor.get_at({x = x, y = y, z = z})
    local value = hud_text(info)
    if value ~= record.text then
        player:hud_change(record.id, "text", value)
        record.text = value
    end
end

local function enable_hud(player)
    local name = player:get_player_name()
    if huds[name] then return end
    local id = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        offset = {x = 16, y = 84},
        alignment = {x = 1, y = 1},
        number = 0xC7EAD8,
        text = S("Biome: @1", S("Loading")),
    })
    if not id then return end
    huds[name] = {id = id, text = nil}
    update_hud(player, huds[name])
end

local function disable_hud(player)
    local name = player:get_player_name()
    local record = huds[name]
    if record then
        player:hud_remove(record.id)
        huds[name] = nil
    end
end

-- El seguimiento solo recorre jugadores cuando hay al menos un HUD activo.
local elapsed = 0
core.register_globalstep(function(dt)
    if not next(huds) then return end
    elapsed = elapsed + dt
    if elapsed < 1.5 then return end
    elapsed = elapsed - math.floor(elapsed / 1.5) * 1.5
    for name, record in pairs(huds) do
        local player = core.get_player_by_name(name)
        if player then update_hud(player, record) end
    end
end)

core.register_on_joinplayer(function(player)
    if player:get_meta():get_string(META_HUD) == "1" then
        enable_hud(player)
    end
end)

core.register_on_leaveplayer(function(player)
    -- El motor destruye los elementos HUD al desconectar al jugador.
    huds[player:get_player_name()] = nil
end)

core.register_chatcommand("bioma", {
    params = "[hud]",
    description = S("Show current biome data, or toggle the optional biome HUD"),
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if not player then return false, S("Player not found") end
        param = (param or ""):match("^%s*(.-)%s*$"):lower()
        if param == "hud" then
            local meta = player:get_meta()
            if meta:get_string(META_HUD) == "1" then
                meta:set_string(META_HUD, "0")
                disable_hud(player)
                return true, S("Biome HUD disabled")
            end
            meta:set_string(META_HUD, "1")
            enable_hud(player)
            return true, S("Biome HUD enabled")
        end
        if param ~= "" then return false, S("Usage: /bioma [hud]") end
        local info = sensor.get_at(player:get_pos())
        if not info then return false, S("Biome information unavailable") end
        local heat = info.heat and string.format("%.2f", info.heat) or "?"
        local humidity = info.humidity and string.format("%.2f", info.humidity) or "?"
        local note = info.approximate and S(" (estimated near biome boundaries)") or ""
        return true, S("Biome: @1", info.name) .. note .. " | " ..
            S("Heat: @1", heat) .. " | " .. S("Humidity: @1", humidity) ..
            " | " .. S("Mapgen: @1", info.generator)
    end,
})

core.log("action", "[advanced_discovery_maps] Sensor de biomas activo (mapgen: " .. mapgen .. ")")
