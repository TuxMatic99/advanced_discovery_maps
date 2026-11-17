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

-- ADM-P6-HUD: Telemetria de biomas y reloj en una sola rutina ligera.
-- No modifica el sensor, los mapas, la varita ni la vision nocturna.
local huds = {}
local clocks = {}
local META_HUD = "adm_biome_hud"
local META_CLOCK = "adm_clock_hud"
local step_elapsed = 0
local biome_elapsed = 0

-- El HUD del Atlas movil se situa a la derecha; por defecto estos datos
-- se muestran a la izquierda, por debajo de la zona habitual del chat.
local function layout()
    local corner = core.settings:get("adm_info_hud_corner") or "top-left"
    local is_right = corner == "top-right"
    local is_bottom = corner == "bottom-left"
    local y_default = is_bottom and 0.65 or 0.24
    local y = tonumber(core.settings:get("adm_info_hud_y")) or y_default
    y = math.max(0.08, math.min(0.82, y))
    return {x = is_right and 1 or 0, y = y},
           is_right and -18 or 18,
           is_right and -1 or 1
end

local function font_scale()
    local v = tonumber(core.settings:get("adm_info_hud_font_scale")) or 1.25
    return math.max(1, math.min(1.75, v))
end

local function add_text(player, title, initial, dy, color, bold, size)
    local pos, offx, alignx = layout()
    return player:hud_add({
        type = "text", name = title,
        position = pos, alignment = {x = alignx, y = 1},
        offset = {x = offx, y = dy},
        number = color, style = bold and 1 or 0,
        size = {x = size, y = 0}, text = initial,
        z_index = 0,
    })
end

local function set_text(player, rec, key, value)
    local id = rec.ids[key]
    if id and value ~= rec.text[key] then
        player:hud_change(id, "text", value)
        rec.text[key] = value
    end
end

local function update_biome(player, rec)
    local pos = player:get_pos()
    if not pos then return end
    local x, y, z = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
    if rec.x == x and rec.y == y and rec.z == z then return end
    rec.x, rec.y, rec.z = x, y, z
    local info = sensor.get_at({x = x, y = y, z = z})
    local label = info and info.name or S("Unknown")
    if info and info.approximate then label = label .. " ~" end
    local heat = info and type(info.heat) == "number" and string.format("%.2f", info.heat) or "?"
    local humidity = info and type(info.humidity) == "number" and string.format("%.2f", info.humidity) or "?"
    local generator = info and info.generator or "?"
    set_text(player, rec, "title", S("Biome: @1", label))
    set_text(player, rec, "details", S("Heat: @1", heat) .. "   " .. S("Humidity: @1", humidity))
    set_text(player, rec, "source", S("Mapgen: @1", generator))
end

local function refresh_clock_offset(player)
    local name = player:get_player_name()
    local rec = clocks[name]
    if not rec or not rec.id then return end
    local _, ox = layout()
    player:hud_change(rec.id, "offset", {x = ox, y = huds[name] and 78 or 0})
end

local function enable_biome(player)
    local name = player:get_player_name()
    if huds[name] then return end
    local size = font_scale()
    local ids = {
        title = add_text(player, "ADM biome", "", 0, 0xDFF9F1, true, size),
        details = add_text(player, "ADM environment", "", 28, 0xBFE4E1, false, 1),
        source = add_text(player, "ADM mapgen", "", 49, 0xAEC4CA, false, 1),
    }
    if not (ids.title and ids.details and ids.source) then
        for _, id in pairs(ids) do player:hud_remove(id) end
        return
    end
    local rec = {ids = ids, text = {}}
    huds[name] = rec
    update_biome(player, rec)
    refresh_clock_offset(player)
end

local function disable_biome(player)
    local name = player:get_player_name()
    local rec = huds[name]
    if not rec then return end
    for _, id in pairs(rec.ids) do player:hud_remove(id) end
    huds[name] = nil
    refresh_clock_offset(player)
end

local function clock_text()
    -- get_timeofday(): 0 = medianoche, 0.5 = mediodia.
    local time = tonumber(core.get_timeofday()) or 0
    local minute = math.floor((time % 1) * 1440) % 1440
    return S("Game time: @1", string.format("%02d:%02d", math.floor(minute / 60), minute % 60))
end

local function enable_clock(player)
    local name = player:get_player_name()
    if clocks[name] then return end
    local id = add_text(player, "ADM game clock", "", huds[name] and 78 or 0,
                        0xF5D98A, true, font_scale())
    if not id then return end
    clocks[name] = {id = id}
    local value = clock_text()
    player:hud_change(id, "text", value)
    clocks[name].text = value
end

local function disable_clock(player)
    local name = player:get_player_name()
    local rec = clocks[name]
    if rec then player:hud_remove(rec.id) end
    clocks[name] = nil
end

core.register_globalstep(function(dt)
    if not next(huds) and not next(clocks) then return end
    step_elapsed = step_elapsed + dt
    if step_elapsed < 1 then return end
    local elapsed = step_elapsed
    step_elapsed = step_elapsed % 1
    biome_elapsed = biome_elapsed + elapsed
    if next(clocks) then
        local value = clock_text() -- una sola lectura para todos los jugadores
        for name, rec in pairs(clocks) do
            if value ~= rec.text then
                local player = core.get_player_by_name(name)
                if player then player:hud_change(rec.id, "text", value); rec.text = value end
            end
        end
    end
    if biome_elapsed >= 2 then
        biome_elapsed = biome_elapsed % 2
        for name, rec in pairs(huds) do
            local player = core.get_player_by_name(name)
            if player then update_biome(player, rec) end
        end
    end
end)

core.register_on_joinplayer(function(player)
    local meta = player:get_meta()
    if meta:get_string(META_HUD) == "1" then enable_biome(player) end
    -- Reloj activado inicialmente, salvo que el jugador lo apague.
    if meta:get_string(META_CLOCK) ~= "0" then enable_clock(player) end
end)

core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    huds[name], clocks[name] = nil, nil
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
                disable_biome(player)
                return true, S("Biome HUD disabled")
            end
            meta:set_string(META_HUD, "1")
            enable_biome(player)
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

core.register_chatcommand("reloj", {
    params = "[on|off]",
    description = S("Show or hide the in-game clock"),
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if not player then return false, S("Player not found") end
        param = (param or ""):match("^%s*(.-)%s*$"):lower()
        if param ~= "" and param ~= "on" and param ~= "off" then
            return false, S("Usage: /reloj [on|off]")
        end
        local meta = player:get_meta()
        local enabled = clocks[name] ~= nil
        local desired = param == "on" or (param == "" and not enabled)
        if desired then
            meta:set_string(META_CLOCK, "1")
            enable_clock(player)
            return true, S("Clock HUD enabled")
        end
        meta:set_string(META_CLOCK, "0")
        disable_clock(player)
        return true, S("Clock HUD disabled")
    end,
})

core.log("action", "[advanced_discovery_maps] Sensor de biomas activo (mapgen: " .. mapgen .. ")")
