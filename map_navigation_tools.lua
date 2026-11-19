-- Advanced Discovery Maps P7-B2: navegación rápida y regla cartográfica.
-- Solo interfaz: nunca modifica nodos ni archivos del mundo. Lua 5.1.
local core = minetest
local P = persistent_map
local S = core.get_translator(core.get_current_modname())
local esc, fmt = core.formspec_escape, string.format
local floor, abs, sqrt, atan, pi = math.floor, math.abs, math.sqrt, math.atan, math.pi
local sessions = {}
local units = {
    {"Metros",       1,           "m"},
    {"Centimetros",  100,         "cm"},
    {"Kilometros",   0.001,       "km"},
    {"Pulgadas",     39.37007874, "in"},
    {"Pies",         3.280839895, "ft"},
    {"Yardas",       1.093613298, "yd"},
    {"Millas",       1/1609.344,  "mi"},
}
local unit_by_name = {}
for i, row in ipairs(units) do unit_by_name[row[1]] = {i = i, factor = row[2], symbol = row[3]} end
local function valid_coord(value)
    local n = tonumber(value)
    if not n or n ~= n or abs(n) > 30927 then return nil end
    return n
end
local function point(pos)
    if not pos then return nil end
    local x, z = valid_coord(pos.x), valid_coord(pos.z)
    if not x or not z then return nil end
    return {x = x, z = z}
end
local function player_point(player)
    return point(player and player:get_pos())
end
local function selected_marker(name)
    local pdata = P.get_player_data(name)
    local id = P.active_target[name]
    return point(pdata and pdata.markers and pdata.markers[id])
end
local function get_session(name, player)
    local session = sessions[name]
    if session then
        local current = P.player_units[name]
        if unit_by_name[current] then session.unit = current end
        return session
    end
    local pos = player_point(player) or {x = 0, z = 0}
    local saved = player:get_meta():get_string("adm_nav_measure_unit")
    local chosen = P.player_units[name] or saved
    if not unit_by_name[chosen] then chosen = "Metros" end
    P.player_units[name] = chosen
    session = {a = point(pos), b = nil, jump_x = pos.x, jump_z = pos.z,
        pending = nil, notice = "", unit = chosen}
    sessions[name] = session
    return session
end
local function format_distance(value, unit)
    local chosen = unit_by_name[unit] or unit_by_name.Metros
    local converted = value * chosen.factor
    return fmt("%.2f %s", converted, chosen.symbol)
end
local function distance(a, b, unit)
    if not a or not b then return nil end
    local dx, dz = b.x - a.x, b.z - a.z
    local d = sqrt(dx * dx + dz * dz)
    local angle
    if dz == 0 then
        angle = dx < 0 and 270 or (dx > 0 and 90 or 0)
    else
        angle = atan(dx / dz) * 180 / pi
        if dz < 0 then angle = angle + 180 end
        if angle < 0 then angle = angle + 360 end
    end
    return {blocks = d, text = format_distance(d, unit),
        dx = format_distance(abs(dx), unit), dz = format_distance(abs(dz), unit),
        bearing = fmt("%.1f", angle)}
end
-- Expuesto para pruebas automatizadas y marcadores A/B del Atlas.
P.adm_nav_math = {valid_coord = valid_coord, distance = distance,
    format_distance = format_distance, point = point}
function P.adm_nav_get_points(name)
    local s = sessions[name]
    return s and s.a, s and s.b
end
function P.adm_nav_pending(name)
    local s = sessions[name]
    return s and s.pending
end
local function center_on(name, player, x, z)
    local p = player_point(player)
    if not p then return false end
    local tile_size = P.tile_size or 128
    local zoom_index = P.get_map_zoom_level(name) or P.default_zoom_index or 2
    local zoom_offset = P.zoom_offsets and P.zoom_offsets[zoom_index] or {x = 0, z = 0}
    local tx, tz = floor(x / tile_size), floor(z / tile_size)
    P.set_map_view_offset(name, {x = tx - floor(p.x / tile_size) - zoom_offset.x,
        z = tz - floor(p.z / tile_size) - zoom_offset.z})
    return true
end
local function show_tools(name)
    local player = core.get_player_by_name(name)
    if not player then return end
    local s = get_session(name, player)
    local a, b = s.a, s.b
    local m = distance(a, b, s.unit)
    local out = {
        "formspec_version[6]",
        "size[12.1,9.5]",
        "bgcolor[#0C1C26F5;true]",
        "style_type[label;font_size=*0.92;textcolor=#E4F5F2]",
        "style_type[button;font_size=*0.88;bgcolor=#214451;textcolor=#FFFFFF]",
        "style_type[field;bgcolor=#18323D;textcolor=#FFFFFF]",
        "style_type[dropdown;font_size=*0.90]",
        fmt("label[0.5,0.4;%s]", esc(S("MAP NAVIGATION AND RULER"))),
        "box[0.4,0.75;11.3,0.025;#60D8C2]",
        fmt("label[0.5,1.15;%s]", esc(S("Jump to world coordinates X / Z (no teleport)"))),
        fmt("field[0.6,1.57;2.45,0.68;adm_jump_x;X;%s]", esc(fmt("%.1f", s.jump_x))),
        fmt("field[3.2,1.57;2.45,0.68;adm_jump_z;Z;%s]", esc(fmt("%.1f", s.jump_z))),
        fmt("button[5.95,1.57;2.4,0.68;adm_jump_go;%s]", esc(S("Center map"))),
        fmt("button[8.55,1.57;2.75,0.68;adm_jump_marker;%s]", esc(S("Center marker"))),
        fmt("label[0.5,2.55;%s]", esc(S("DISTANCE BETWEEN TWO POINTS (horizontal X/Z)"))),
        "box[0.4,2.85;11.3,0.025;#60D8C2]",
        fmt("label[0.55,3.23;%s]", esc(S("Point A"))),
        fmt("label[6.15,3.23;%s]", esc(S("Point B"))),
        fmt("field[0.55,3.55;2.35,0.68;adm_a_x;X;%s]", esc(a and fmt("%.1f", a.x) or "")),
        fmt("field[3.00,3.55;2.35,0.68;adm_a_z;Z;%s]", esc(a and fmt("%.1f", a.z) or "")),
        fmt("field[6.15,3.55;2.35,0.68;adm_b_x;X;%s]", esc(b and fmt("%.1f", b.x) or "")),
        fmt("field[8.60,3.55;2.35,0.68;adm_b_z;Z;%s]", esc(b and fmt("%.1f", b.z) or "")),
        fmt("button[0.55,4.4;1.55,0.6;adm_a_player;%s]", esc(S("Me"))),
        fmt("button[2.2,4.4;1.55,0.6;adm_a_marker;%s]", esc(S("Marker"))),
        fmt("button[3.85,4.4;1.55,0.6;adm_a_pick;%s]", esc(S("Map"))),
        fmt("button[6.15,4.4;1.55,0.6;adm_b_player;%s]", esc(S("Me"))),
        fmt("button[7.8,4.4;1.55,0.6;adm_b_marker;%s]", esc(S("Marker"))),
        fmt("button[9.45,4.4;1.55,0.6;adm_b_pick;%s]", esc(S("Map"))),
    }
    local selected = unit_by_name[s.unit] or unit_by_name.Metros
    local names = {}
    for _, row in ipairs(units) do names[#names + 1] = row[1] end
    out[#out + 1] = fmt("label[0.55,5.52;%s]", esc(S("Measurement unit")))
    out[#out + 1] = fmt("dropdown[3.3,5.18;3.05,0.65;adm_measure_unit;%s;%d]",
        table.concat(names, ","), selected.i)
    out[#out + 1] = fmt("button[6.65,5.18;2.35,0.64;adm_measure_apply;%s]", esc(S("Measure")))
    out[#out + 1] = fmt("button[9.15,5.18;2,0.64;adm_measure_clear;%s]", esc(S("Clear")))
    if m then
        out[#out + 1] = fmt("label[0.55,6.24;%s]", esc(S("Distance") .. ": " .. m.text))
        out[#out + 1] = fmt("label[0.55,6.69;%s]", esc("|ΔX| " .. m.dx .. "    |ΔZ| " .. m.dz))
        out[#out + 1] = fmt("label[0.55,7.15;%s]", esc(S("Bearing") .. ": " .. m.bearing .. "°"))
    else
        out[#out + 1] = fmt("label[0.55,6.24;%s]", esc(S("Choose both points A and B.")))
    end
    out[#out + 1] = fmt("label[0.55,7.77;%s]", esc(S("A map click selects the tile center. Enter X/Z for precise measurement.")))
    out[#out + 1] = fmt("label[0.55,8.18;%s]", esc(S("One tile") .. " = " .. format_distance(P.tile_size or 128, s.unit) .. ". " .. S("One block = one meter (convention).")))
    if s.notice ~= "" then
        out[#out + 1] = fmt("label[0.55,8.62;%s]", esc(s.notice))
    end
    out[#out + 1] = fmt("button_exit[8.4,8.86;3.2,0.52;adm_nav_back;%s]", esc(S("Back to Atlas")))
    core.show_formspec(name, "advanced_discovery_maps:navigation", table.concat(out))
end
P.adm_nav_show = show_tools
core.register_chatcommand("regla", {
    description = S("Open Atlas ruler and navigation"),
    func = function(name)
        show_tools(name)
        return true
    end,
})
local function choose_coordinate_fields(fields, prefix)
    local x, z = valid_coord(fields[prefix .. "_x"]), valid_coord(fields[prefix .. "_z"])
    if x and z then return {x = x, z = z} end
    return nil
end
local function set_unit(name, player, s, value)
    if unit_by_name[value] then
        s.unit = value
        P.player_units[name] = value
        player:get_meta():set_string("adm_nav_measure_unit", value)
    end
end
core.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    if formname == "persistent_map:map" then
        if fields.adm_nav_tools then
            if P.adm_suspend_atlas then P.adm_suspend_atlas(name) end
            show_tools(name)
            return true
        end
        local s = sessions[name]
        if s and s.pending then
            for key in pairs(fields) do
                local tx, tz = key:match("^map_click_(-?%d+)_(-?%d+)$")
                if tx and tz then
                    tx, tz = tonumber(tx), tonumber(tz)
                    local pdata = P.get_player_data(name)
                    local key_tile = "tile_" .. tx .. "_" .. tz
                    -- No aceptar selecciones inventadas de cuadrantes no explorados.
                    if not (pdata and pdata.discovered_tiles
                            and pdata.discovered_tiles[key_tile]) then return end
                    local size = P.tile_size or 128
                    local p = {x = tx * size + size / 2, z = tz * size + size / 2}
                    s[s.pending] = p
                    s.pending = nil
                    s.notice = S("Map selection uses the center of its quadrant.")
                    if P.adm_suspend_atlas then P.adm_suspend_atlas(name) end
                    show_tools(name)
                    return true
                end
            end
        end
        return
    end
    if formname ~= "advanced_discovery_maps:navigation" then return end
    local s = get_session(name, player)
    if fields.quit and not fields.adm_nav_back then return true end
    if fields.adm_measure_unit then set_unit(name, player, s, fields.adm_measure_unit) end
    if fields.adm_nav_back then
        P.show_map(name)
        return true
    end
    if fields.adm_measure_clear then
        s.a, s.b, s.pending, s.notice = nil, nil, nil, ""
    elseif fields.adm_a_pick or fields.adm_b_pick then
        s.pending = fields.adm_a_pick and "a" or "b"
        s.notice = S("Click a discovered tile in the Atlas.")
        P.show_map(name)
        return true
    elseif fields.adm_a_player or fields.adm_b_player then
        local p = player_point(player)
        if p then s[fields.adm_a_player and "a" or "b"] = p end
    elseif fields.adm_a_marker or fields.adm_b_marker then
        local p = selected_marker(name)
        if p then
            s[fields.adm_a_marker and "a" or "b"] = p
            s.notice = ""
        else
            s.notice = S("First select a marker in the Atlas.")
        end
    elseif fields.adm_jump_go then
        local x, z = valid_coord(fields.adm_jump_x), valid_coord(fields.adm_jump_z)
        if x and z and center_on(name, player, x, z) then
            s.jump_x, s.jump_z = x, z
            P.show_map(name)
            return true
        else
            s.notice = S("Invalid coordinates.")
        end
    elseif fields.adm_jump_marker then
        local p = selected_marker(name)
        if p and center_on(name, player, p.x, p.z) then
            s.jump_x, s.jump_z = p.x, p.z
            P.show_map(name)
            return true
        else
            s.notice = S("First select a marker in the Atlas.")
        end
    elseif fields.adm_measure_apply then
        local a, b = choose_coordinate_fields(fields, "adm_a"), choose_coordinate_fields(fields, "adm_b")
        s.notice = ""
        if (fields.adm_a_x or "") ~= "" or (fields.adm_a_z or "") ~= "" then
            if a then s.a = a else s.notice = S("Invalid coordinates.") end
        end
        if (fields.adm_b_x or "") ~= "" or (fields.adm_b_z or "") ~= "" then
            if b then s.b = b else s.notice = S("Invalid coordinates.") end
        end
    end
    show_tools(name)
    return true
end)
core.register_on_leaveplayer(function(player)
    sessions[player:get_player_name()] = nil
end)
