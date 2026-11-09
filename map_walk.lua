-- Advanced Discovery Maps: exploracion con mapa HUD, Luanti 5.10+.
-- Este modulo no cambia el terreno ni genera cuadrantes.
local core = minetest
local P = persistent_map
local S = core.get_translator(core.get_current_modname())
local floor, abs, pi = math.floor, math.abs, math.pi
local fmt = string.format
local active = {}
local accumulator = 0
local TILES_PIXELS = 64
local CX, CY = -137, 150
local BLANK = "adm_empty.png"

local function direction_index(yaw)
    yaw = tonumber(yaw) or 0
    return floor((yaw % (2 * pi)) * 16 / (2 * pi) + 0.5) % 16
end

local function tile_texture(pdata, tx, tz, mode)
    local id = fmt("tile_%d_%d", tx, tz)
    if not pdata.discovered_tiles or not pdata.discovered_tiles[id] then
        return BLANK
    end
    local version = P.tile_versions and P.tile_versions[id] or 0
    local base = version > 0 and (id .. "_v" .. version) or id
    local suffix = mode == "relief" and "_relief" or mode == "cave" and "_cave" or ""
    local name = base .. suffix .. ".png"
    local file = io.open(P.map_path .. name, "rb")
    if not file then return BLANK end
    file:close()
    return name
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
    local state = active[name]
    if not state then return end
    if player then
        for _, id in ipairs(state.ids) do
            player:hud_remove(id)
        end
    end
    active[name] = nil
end

local function start(player)
    local name = player:get_player_name()
    if active[name] then return end
    local state = {ids = {}, cells = {}, mode = nil, tx = nil, tz = nil, refresh = 0}
    active[name] = state
    local function register(id)
        state.ids[#state.ids + 1] = id
        return id
    end
    register(image(player, "ADM Map frame", "adm_map_hud_frame.png", CX, CY, 1, -1))
    for dz = 1, -1, -1 do
        for dx = -1, 1 do
            local id = register(image(player, "ADM tile", BLANK,
                CX + dx * TILES_PIXELS, CY - dz * TILES_PIXELS, 0.5, 0))
            state.cells[#state.cells + 1] = {id = id, dx = dx, dz = dz, texture = BLANK}
        end
    end
    state.pointer = register(image(player, "ADM Player Compass", "adm_player_00.png", CX, CY, 0.48, 5))
    state.label = register(player:hud_add({
        type = "text", name = "ADM Coordinates",
        position = {x = 1, y = 0}, alignment = {x = 0, y = 0},
        offset = {x = CX, y = 276},
        number = 0xD4F8F4, text = "", z_index = 6,
    }))
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
    if state.tx ~= tx or state.tz ~= tz or state.mode ~= mode or state.refresh >= 3 then
        state.tx, state.tz, state.mode, state.refresh = tx, tz, mode, 0
        for _, cell in ipairs(state.cells) do
            local texture = tile_texture(pdata, tx + cell.dx, tz + cell.dz, mode)
            if texture ~= cell.texture then
                player:hud_change(cell.id, "text", texture)
                cell.texture = texture
            end
        end
    end
    -- El mapa permanece fijo dentro del cuadrante; el indicador se desplaza.
    local fx, fz = pos.x / n - tx, pos.z / n - tz
    local cursor_x = CX + (fx - 0.5) * TILES_PIXELS
    local cursor_y = CY + (0.5 - fz) * TILES_PIXELS
    local yaw_index = direction_index(player:get_look_horizontal())
    if state.cursor_x ~= cursor_x or state.cursor_y ~= cursor_y then
        player:hud_change(state.pointer, "offset", {x = cursor_x, y = cursor_y})
        state.cursor_x, state.cursor_y = cursor_x, cursor_y
    end
    if state.direction ~= yaw_index then
        player:hud_change(state.pointer, "text", fmt("adm_player_%02d.png", yaw_index))
        state.direction = yaw_index
    end
    local label = fmt("X %d   Z %d  |  %s", floor(pos.x), floor(pos.z), mode)
    if label ~= state.last_label then
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
        update(player, active[name], 3)
        return true
    end
    stop(name, player)
    return false
end

core.register_chatcommand("map_movil", {
    params = "[on|off]",
    description = "Mostrar u ocultar el mapa HUD para caminar y explorar",
    func = function(name, param)
        local player = core.get_player_by_name(name)
        if not player then return false, "Jugador no disponible" end
        param = (param or ""):lower():match("^%s*(.-)%s*$")
        if param ~= "" and param ~= "on" and param ~= "off" then
            return false, "Uso: /map_movil [on|off]"
        end
        local enabled = toggle(player, param == "" and nil or param == "on")
        return true, enabled and "Mapa movil activado. Usa /map_movil off para ocultarlo."
            or "Mapa movil desactivado."
    end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "persistent_map:map" or not fields.adm_walk_switch then return end
    toggle(player, true)
    core.close_formspec(player:get_player_name(), "persistent_map:map")
    return true
end)

core.register_globalstep(function(dtime)
    accumulator = accumulator + dtime
    if accumulator < 0.25 then return end
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
core.log("action", "[advanced_discovery_maps] Mapa HUD para caminar disponible: /map_movil")
