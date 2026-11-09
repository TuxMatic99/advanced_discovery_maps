-- Advanced Discovery Maps: atlas compacto y adaptable (Luanti 5.10+).
-- Solo reemplaza la presentacion. No lee ni modifica nodos del mundo.
local core = minetest
local P = persistent_map
local S = core.get_translator(core.get_current_modname())
local esc = core.formspec_escape
local fmt = string.format
local abs, floor, ceil, min, max = math.abs, math.floor, math.ceil, math.min, math.max

local function clean_name(value, limit)
    value = tostring(value or "")
    -- Recortar por caracteres UTF-8, no por bytes: no rompe acentos.
    local n, cut = 0, #value
    for i = 1, #value do
        local b = value:byte(i)
        if b < 128 or b >= 192 then
            n = n + 1
            if n > limit then
                cut = i - 1
                break
            end
        end
    end
    if cut < #value then return value:sub(1, cut) .. "..." end
    return value
end

local function add(out, element)
    out[#out + 1] = element
end

local themes = {
    night = {
        bg = "#0B1721FF", panel = "#172A35F2", panel2 = "#203642FF",
        edge = "#47707B99", accent = "#67D7C9", text = "#E5F2F4",
        muted = "#A8BBC5", undiscovered = "#10212B", missing = "#344856",
    },
    paper = {
        bg = "#232A27FF", panel = "#394842F2", panel2 = "#485A52FF",
        edge = "#8DA59599", accent = "#EBCB88", text = "#FFF6E3",
        muted = "#E0D8C7", undiscovered = "#29352F", missing = "#58665B",
    },
}

function P.show_map(player_name)
    local player = core.get_player_by_name(player_name)
    local pdata = P.get_player_data(player_name)
    if not (player and pdata) then return end

    local win = core.get_player_window_information and core.get_player_window_information(player_name)
    local maxsize = win and win.max_formspec_size
    local W = max(15.5, min(18.6, (maxsize and maxsize.x or 19.0) - 0.35))
    -- Altura constante: al reducirse la ventana, Luanti escala el formulario
    -- completo, evitando que los controles inferiores se desborden.
    local H = 10.5
    local left_x, left_w = 0.30, 2.95
    local map_x, map_y = 3.43, 1.07
    local right_w, gap = 3.25, 0.18
    local map_w = W - map_x - right_w - gap - 0.24
    local map_h = H - 2.05
    local right_x = map_x + map_w + gap
    local theme = themes[core.settings:get("adm_ui_theme") or "night"] or themes.night

    local pos = player:get_pos()
    local tile_size = P.tile_size or 128
    local tile_x, tile_z = floor(pos.x / tile_size), floor(pos.z / tile_size)
    local fx = pos.x / tile_size - tile_x
    local fz = pos.z / tile_size - tile_z
    local offset = P.get_map_view_offset(player_name) or {x = 0, z = 0}
    local zoom_index = P.get_map_zoom_level(player_name) or P.default_zoom_index or 2
    local zoom = (P.zoom_levels and P.zoom_levels[zoom_index]) or 1
    local zoffs = (P.zoom_offsets and P.zoom_offsets[zoom_index]) or {x = 0, z = 0}
    local cx = tile_x + offset.x + zoffs.x
    local cz = tile_z + offset.z + zoffs.z
    local tile_px = 1.65 * zoom
    local radius = min(16, ceil(max(map_w, map_h) / tile_px / 2) + 2)
    local mode = P.player_map_mode[player_name] or "standard"
    local suffix = mode == "relief" and "_relief" or mode == "cave" and "_cave" or ""
    local out = {}

    add(out, "formspec_version[6]")
    add(out, fmt("size[%.2f,%.2f]", W, H))
    add(out, "bgcolor[" .. theme.bg .. ";true]")
    add(out, "style_type[label;font_size=*0.89;textcolor=" .. theme.text .. "]")
    add(out, "style_type[button;font_size=*0.87;bgcolor=" .. theme.panel2 .. ";textcolor=" .. theme.text .. ";border=false]")
    add(out, "style_type[button:hovered;bgcolor=#376A74]")
    add(out, "style_type[button:pressed;bgcolor=#2D5661]")
    add(out, "style_type[field;bgcolor=" .. theme.panel2 .. ";textcolor=" .. theme.text .. ";border=false]")
    add(out, "style_type[dropdown;font_size=*0.85]")
    add(out, fmt("box[0.18,0.15;%.2f,0.76;%s]", W - .36, theme.panel))
    add(out, fmt("box[0.18,0.88;%.2f,0.035;%s]", W - .36, theme.accent))
    add(out, fmt("label[0.49,0.51;%s]", esc(S("ADVANCED DISCOVERY MAPS  /  ATLAS"))))
    add(out, fmt("label[%.2f,0.51;%s]", W - 3.10, esc(S("Zoom: @1x", zoom))))
    add(out, fmt("box[%.2f,%.2f;%.2f,%.2f;%s]", left_x, map_y, left_w, map_h, theme.panel))
    add(out, fmt("box[%.2f,%.2f;%.2f,%.2f;%s]", right_x, map_y, right_w, map_h, theme.panel))
    add(out, fmt("box[%.2f,%.2f;%.2f,%.2f;%s]", map_x - .035, map_y - .035, map_w + .07, map_h + .07, theme.edge))
    add(out, fmt("box[%.2f,%.2f;%.2f,%.2f;%s]", map_x, map_y, map_w, map_h, theme.undiscovered))

    -- Un contenedor recortado evita que el mapa desborde los paneles laterales.
    add(out, fmt("scroll_container[%.2f,%.2f;%.2f,%.2f;adm_clip;horizontal;0.1]", map_x, map_y, map_w, map_h))
    local visible = 0
    local discovered = pdata.discovered_tiles or {}
    local map_path = P.map_path
    local cxi = map_w * 0.5 - fx * tile_px
    local cyi = map_h * 0.5 - (1 - fz) * tile_px

    for dz = -radius, radius do
        local tz = cz + dz
        local y = cyi - dz * tile_px
        if y < map_h and y + tile_px > 0 then
            for dx = -radius, radius do
                local tx = cx + dx
                local x = cxi + dx * tile_px
                if x < map_w and x + tile_px > 0 then
                    local base = fmt("tile_%d_%d", tx, tz)
                    if discovered[base] then
                        visible = visible + 1
                        local ver = P.tile_versions and P.tile_versions[base] or 0
                        local version_name = ver > 0 and (base .. "_v" .. ver) or base
                        local file_base = version_name .. suffix
                        local fp = map_path .. file_base .. ".png"
                        local f = io.open(fp, "rb")
                        if f then
                            f:close()
                            add(out, fmt("image_button[%.3f,%.3f;%.3f,%.3f;%s.png;map_click_%d_%d;;false;false]", x, y, tile_px, tile_px, file_base, tx, tz))
                        else
                            add(out, fmt("box[%.3f,%.3f;%.3f,%.3f;%s]", x, y, tile_px, tile_px, theme.missing))
                        end
                    end
                    if P.player_show_grid[player_name] then
                        add(out, fmt("box[%.3f,%.3f;0.015,%.3f;%s]", x, y, tile_px, theme.edge))
                        add(out, fmt("box[%.3f,%.3f;%.3f,0.015;%s]", x, y, tile_px, theme.edge))
                    end
                end
            end
        end
    end

    local function marker_at(p, color, label)
        local px, pz = p.x / tile_size, p.z / tile_size
        local tx, tz = floor(px), floor(pz)
        local x = cxi + (tx - cx + (px - tx)) * tile_px
        local y = cyi - (tz - cz) * tile_px + (1 - (pz - tz)) * tile_px
        if x < .18 or y < .2 or x > map_w - .18 or y > map_h - .18 then return end
        add(out, fmt("box[%.3f,%.3f;0.20,0.20;#071016CC]", x - .10, y - .10))
        add(out, fmt("box[%.3f,%.3f;0.12,0.12;%s]", x - .06, y - .06, color))
        if label and zoom >= 2 and x < map_w - 2 then
            add(out, fmt("label[%.3f,%.3f;%s]", x + .15, y, esc(clean_name(label, 13))))
        end
    end

    for _, m in pairs(pdata.markers or {}) do
        if type(m) == "table" and m.x and m.z then
            local ci = P.marker_colors[m.color_index] or P.marker_colors[1]
            marker_at(m, ci.color, m.name)
        end
    end
    if P.get_party_member_positions then
        for member, entry in pairs(P.get_party_member_positions(player_name) or {}) do
            if entry.pos then marker_at(entry.pos, "#73BBFF", member) end
        end
    end
    -- Brújula del jugador: textura de 16 orientaciones, tamaño fijo.
    -- La posición respeta el desplazamiento del Atlas al navegar por el mapa.
    local cursor_x = cxi + (tile_x - cx + fx) * tile_px
    local cursor_y = cyi - (tile_z - cz) * tile_px + (1 - fz) * tile_px
    if cursor_x >= 0.36 and cursor_y >= 0.36
            and cursor_x <= map_w - 0.36 and cursor_y <= map_h - 0.36 then
        local yaw = tonumber(player:get_look_horizontal()) or 0
        local index = floor((yaw % (2 * math.pi)) * 16 / (2 * math.pi) + 0.5) % 16
        add(out, fmt("image[%.3f,%.3f;0.68,0.68;adm_player_%02d.png]",
            cursor_x - 0.34, cursor_y - 0.34, index))
    end
    add(out, "scroll_container_end[]")

    -- Panel de navegación compacto.
    local lx, lw = left_x + .18, left_w - .36
    local bw = .82
    local mid = lx + (lw - bw) / 2
    add(out, fmt("label[%.2f,1.43;%s]", lx, esc(S("NAVIGATION"))))
    add(out, fmt("button[%.2f,1.87;%.2f,0.56;nav_north;N]", mid, bw))
    add(out, fmt("button[%.2f,2.50;%.2f,0.56;nav_west;W]", lx + .20, bw))
    add(out, fmt("button[%.2f,2.50;%.2f,0.56;nav_east;E]", lx + lw - bw - .20, bw))
    add(out, fmt("button[%.2f,3.13;%.2f,0.56;nav_south;S]", mid, bw))
    add(out, fmt("button[%.2f,3.91;%.2f,0.58;nav_center;%s]", lx, lw, esc(S("Center on Player"))))
    add(out, fmt("label[%.2f,4.84;%s]", lx, esc(S("ZOOM"))))
    add(out, fmt("button[%.2f,5.13;1.17,0.57;zoom_out;−]", lx))
    add(out, fmt("button[%.2f,5.13;1.17,0.57;zoom_in;+]", lx + lw - 1.17))
    local mode_name = mode == "relief" and S("Relief") or mode == "cave" and S("Caves") or S("Natural")
    add(out, fmt("label[%.2f,6.00;%s]", lx, esc(S("MAP LAYER"))))
    add(out, fmt("button[%.2f,6.31;%.2f,0.57;toggle_map_mode;%s]", lx, lw, esc(mode_name)))
    add(out, fmt("button[%.2f,7.04;%.2f,0.57;toggle_grid;%s]", lx, lw, esc(P.player_show_grid[player_name] and S("Hide Grid") or S("Show Grid"))))
    add(out, fmt("label[%.2f,7.91;%s]", lx, esc(S("UNITS"))))
    local units = {"Metros", "Centimetros", "Kilometros", "Pulgadas", "Pies", "Yardas", "Millas"}
    local selected_unit = P.player_units[player_name] or "Metros"
    local selected_idx = 1
    for i, unit in ipairs(units) do if unit == selected_unit then selected_idx = i end end
    add(out, fmt("dropdown[%.2f,8.26;%.2f,0.68;unidad_selector;%s;%d]", lx, lw, table.concat(units, ","), selected_idx))
    -- button_exit permite pasar del formulario modal al HUD no modal.
    if core.settings:get_bool("adm_walkmap_enabled", true) then
        add(out, fmt("button_exit[%.2f,9.03;%.2f,0.45;adm_walk_switch;%s]",
            lx, lw, esc(S("Walk with Map"))))
    end

    -- Herramientas de la derecha; mismos nombres de campo que la interfaz anterior.
    local rx, rw = right_x + .17, right_w - .34
    add(out, fmt("label[%.2f,1.43;%s]", rx, esc(S("MARKERS"))))
    add(out, fmt("label[%.2f,1.90;%s]", rx, esc(S("Marker Name:"))))
    add(out, fmt("field[%.2f,2.18;%.2f,0.68;marker_name;;]", rx, rw))
    add(out, fmt("label[%.2f,3.10;%s]", rx, esc(S("MARKER COLOR"))))
    local color_w = (rw - .15) / 2
    for i, c in ipairs(P.marker_colors) do
        local col = (i - 1) % 2
        local row = floor((i - 1) / 2)
        local x = rx + col * (color_w + .15)
        local y = 3.48 + row * .59
        add(out, fmt("button[%.2f,%.2f;%.2f,0.52;add_marker_%d;%s]", x, y, color_w, i, esc(clean_name(S(c.name), 8))))
        -- Tira de color sobre el boton; un box no captura clics.
        add(out, fmt("box[%.2f,%.2f;0.15,0.37;%s]", x + .06, y + .08, c.color))
    end
    add(out, fmt("button[%.2f,5.96;%.2f,0.56;manage_markers;%s]", rx, rw, esc(S("Manage Markers"))))
    add(out, fmt("label[%.2f,6.80;%s]", rx, esc(S("Track Marker"))))
    local options = {S("Closest")}
    local ids = {"closest"}
    local current = P.active_target[player_name] or "closest"
    local target_idx = 1
    for id, marker in pairs(pdata.markers or {}) do
        local label = clean_name((marker.name or "Unnamed"):gsub(",", " "), 21)
        options[#options + 1] = label
        ids[#ids + 1] = id
        if id == current then target_idx = #ids end
    end
    pdata.target_dropdown_map = ids
    pdata.target_dropdown_opts = options
    local opts_escaped = {}
    for i, opt in ipairs(options) do opts_escaped[i] = esc(opt) end
    add(out, fmt("dropdown[%.2f,7.13;%.2f,0.66;target_selector;%s;%d]", rx, rw, table.concat(opts_escaped, ","), target_idx))
    add(out, fmt("label[%.2f,7.96;%s]", rx, esc(S("Topographic Analysis"))))
    local half = (rw - .14) / 2
    add(out, fmt("button[%.2f,8.28;%.2f,0.58;perfil_x;%s]", rx, half, esc(S("X / E-W"))))
    add(out, fmt("button[%.2f,8.28;%.2f,0.58;perfil_z;%s]", rx + half + .14, half, esc(S("Z / N-S"))))
    if P.show_party_gui then
        add(out, fmt("button[%.2f,8.96;%.2f,0.55;party_gui;%s]", rx, rw, esc(S("Map Party"))))
    end

    local marks = 0
    for _ in pairs(pdata.markers or {}) do marks = marks + 1 end
    add(out, fmt("box[0.18,%.2f;%.2f,0.62;%s]", H - .73, W - .36, theme.panel))
    add(out, fmt("label[0.43,%.2f;%s]", H - .40, esc(fmt("X %d  Y %d  Z %d", floor(pos.x), floor(pos.y), floor(pos.z)))))
    add(out, fmt("label[%.2f,%.2f;%s]", max(6.8, W - 9.3), H - .40,
        esc(fmt("%s %d  |  %s %d", S("Visible"), visible, S("Markers"), marks))))
    add(out, fmt("label[%.2f,%.2f;%s]", W - 3.3, H - .40, esc(fmt("%s: %s", S("Layer"), mode_name))))

    core.show_formspec(player_name, "persistent_map:map", table.concat(out))
end

core.log("action", "[advanced_discovery_maps] Modern Atlas UI enabled")
