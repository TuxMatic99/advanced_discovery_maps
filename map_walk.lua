-- ADM: minimapa HUD de marcha, sin ventanas modales (Luanti 5.10+).
-- Media enviada solo cuando el cliente confirma la recepción.
local core = minetest
local P = persistent_map
local floor, abs, pi = math.floor, math.abs, math.pi
local fmt = string.format
local active = {}
local accumulator = 0
local TILES_PIXELS = 64
local CX, CY = -137, 150
local BLANK = "adm_empty.png"
local hz = tonumber(core.settings:get("adm_walkmap_hz")) or 10
hz = math.max(2, math.min(15, hz))
local PERIOD = 1 / hz

local function direction_index(yaw)
    yaw = tonumber(yaw) or 0
    return floor((yaw % (2 * pi)) * 16 / (2 * pi) + 0.5) % 16
end

local function round(value)
    return floor(value + 0.5)
end

local function image(player, name, texture, x, y, scale, z_index)
    return player:hud_add({
        type = "image", name = name,
        position = {x = 1, y = 0},
        alignment = {x = 0, y = 0},
        offset = {x = x, y = y},
        scale = {x = scale, y = scale},
        text = texture, z_index = z_index,
    })
end

local function stop(name, player)
    local s = active[name]
    if not s then return end
    if player then
        for _, id in ipairs(s.ids) do
            player:hud_remove(id)
        end
    end
    active[name] = nil
end

local function start(player)
    local name = player:get_player_name()
    if active[name] then return end
    local state = {ids = {}, cells = {}, tx = nil, tz = nil, mode = nil, refresh = 0}
    active[name] = state
    local function register(id)
        if id then state.ids[#state.ids + 1] = id end
        return id
    end
    register(image(player, "ADM Map frame", "adm_map_hud_frame.png", CX, CY, 1, -1))
    -- Enviar primero el cuadrante central: transferencias bajo presupuesto.
    local coords = {}
    for dz = 1, -1, -1 do
        for dx = -1, 1 do
            coords[#coords + 1] = {dx = dx, dz = dz}
        end
    end
    table.sort(coords, function(a, b)
        return abs(a.dx) + abs(a.dz) < abs(b.dx) + abs(b.dz)
    end)
    for _, coord in ipairs(coords) do
        local id = register(image(player, "ADM tile", BLANK,
            CX + coord.dx * TILES_PIXELS, CY - coord.dz * TILES_PIXELS, 0.5, 0))
        state.cells[#state.cells + 1] = {
            id = id, dx = coord.dx, dz = coord.dz, texture = BLANK,
        }
    end
    state.pointer = register(image(player, "ADM Player Compass", "adm_player_00.png", CX, CY, 0.48, 5))
    state.label = register(player:hud_add({
        type = "text", name = "ADM Coordinates",
        position = {x = 1, y = 0}, alignment = {x = 0, y = 0},
        offset = {x = CX, y = 276},
        number = 0xD4F8F4, text = "", z_index = 6,
    }))
end

local function draw_tiles(player, state, pdata, tx, tz, mode)
    local suffix = mode == "relief" and "_relief" or mode == "cave" and "_cave" or ""
    local discovered = pdata.discovered_tiles or {}
    for _, cell in ipairs(state.cells) do
        local x, z = tx + cell.dx, tz + cell.dz
        local base = fmt("tile_%d_%d", x, z)
        local texture = BLANK
        if discovered[base] then
            local ver = P.tile_versions and P.tile_versions[base] or 0
            local file = (ver > 0 and (base .. "_v" .. ver) or base) .. suffix .. ".png"
            if P.media_request(player:get_player_name(), file) then
                texture = file
            end
        end
        if texture ~= cell.texture and cell.id then
            player:hud_change(cell.id, "text", texture)
            cell.texture = texture
        end
    end
end

local function update(player, state, dtime)
    local name = player:get_player_name()
    local pdata = P.get_player_data(name)
    if not pdata then return end
    local pos = player:get_pos()
    if not pos then return end
    local n = P.tile_size or 128
    local tx, tz = floor(pos.x / n), floor(pos.z / n)
    local mode = P.player_map_mode[name] or "standard"
    state.refresh = state.refresh + dtime
    local epoch = P.media_epoch(name)
    if state.tx ~= tx or state.tz ~= tz or state.mode ~= mode
            or state.refresh >= 0.75 or epoch ~= state.epoch then
        state.tx, state.tz, state.mode, state.refresh, state.epoch = tx, tz, mode, 0, epoch
        draw_tiles(player, state, pdata, tx, tz, mode)
    end

    local fx, fz = pos.x / n - tx, pos.z / n - tz
    local cursor_x = round(CX + (fx - 0.5) * TILES_PIXELS)
    local cursor_y = round(CY + (0.5 - fz) * TILES_PIXELS)
    if state.pointer and (state.cursor_x ~= cursor_x or state.cursor_y ~= cursor_y) then
        player:hud_change(state.pointer, "offset", {x = cursor_x, y = cursor_y})
        state.cursor_x, state.cursor_y = cursor_x, cursor_y
    end
    local yaw_index = direction_index(player:get_look_horizontal())
    if state.pointer and state.direction ~= yaw_index then
        player:hud_change(state.pointer, "text", fmt("adm_player_%02d.png", yaw_index))
        state.direction = yaw_index
    end
    local label = fmt("X %d   Z %d  |  %s", floor(pos.x), floor(pos.z), mode)
    if state.label and label ~= state.last_label then
        player:hud_change(state.label, "text", label)
        state.last_label = label
    end
end

local function toggle(player, desired)
    local name = player:get_player_name()
    local should_enable = desired
    if should_enable == nil then should_enable = active[name] == nil end
    if should_enable then
        if not active[name] then start(player) end
        update(player, active[name], 1)
        return true
    end
    stop(name, player)
    return false
end

core.register_chatcommand("map_movil", {
    params = "[on|off]",
    description = "Mostrar u ocultar el mapa HUD mientras caminas",
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if not player then return false, "Jugador no disponible" end
        param = (param or ""):lower():match("^%s*(.-)%s*$")
        if param ~= "" and param ~= "on" and param ~= "off" then
            return false, "Uso: /map_movil [on|off]"
        end
        local enabled = toggle(player, param == "" and nil or param == "on")
        return true, enabled and "Mapa movil activado" or "Mapa movil desactivado"
    end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "persistent_map:map" or not fields.adm_walk_switch then return end
    toggle(player, true)
    core.close_formspec(player:get_player_name(), "persistent_map:map")
    return true
end)

core.register_globalstep(function(dtime)
    if next(active) == nil then return end
    accumulator = accumulator + dtime
    if accumulator < PERIOD then return end
    local dt = accumulator
    accumulator = 0
    for name, state in pairs(active) do
        local player = core.get_player_by_name(name)
        if player then
            update(player, state, dt)
        else
            active[name] = nil
        end
    end
end)

core.register_on_leaveplayer(function(player)
    stop(player:get_player_name(), player)
end)
core.log("action", "[advanced_discovery_maps] HUD optimizado: /map_movil")
