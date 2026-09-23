-- Persistent Fullscreen Map Mod for Luanti

persistent_map = {}

-- Configuration
persistent_map.tile_size = 128
persistent_map.map_image_size = 128
persistent_map.scan_interval = 0.5
persistent_map.max_height = 2000
persistent_map.min_height = -1000
persistent_map.gui_tile_size = 5.0
persistent_map.view_radius = 6
persistent_map.marker_scale = 7
persistent_map.player_marker_scale = 4
persistent_map.marker_name_scale = 2.0
persistent_map.marker_name_font_multiplier = 16
persistent_map.marker_name_padding = 0.1
persistent_map.marker_name_min_zoom = 0.5
persistent_map.marker_name_zoom_multiplier = 1.5
persistent_map.marker_name_char_width = 0.2
persistent_map.marker_name_text_height = 0.3

-- Formspec UI Configuration
persistent_map.ui = {
	button_size = 5,
	color_button_size = 5,
	side_panel_width = 20.0,
	padding = 1.0,
	header_height = 1.0,
	info_bottom_margin = 4,
	info_line_spacing = 2.0,
	info_left_align_with_panel = true,
	nav_panel_offset = 2,
	nav_section_spacing = 1,
	nav_button_spacing = 0.2,
	nav_button_multiplier = 1.2,
	nav_center_button_offset = 1,
	zoom_section_offset = 2,
	zoom_button_spacing = 0.5,
	marker_name_label_spacing = 0.8,
	marker_name_field_offset = 0.5,
	marker_name_field_height = 2,
	marker_colors_offset = 3.5,
	colors_per_row = 2,
	color_button_spacing = 0.5,
	color_button_row_spacing = 0.3,
	delete_buttons_offset = 1,
	delete_button_spacing = 0.3,
	formspec_version = 6,
	min_formspec_height = 25,
	header_title_offset = 4,
	scroll_content_center = 0.5,
	field_width_offset = 0.5,
	button_width_offset = 0.5,
	half_divisor = 2,
	arrow_height_factor = 0.5,
	total_width_factor = 0.5,
	padding_multiplier = 2,
}

-- =========================================================
-- NODOS DE VISIÓN NOCTURNA (Emisores de Fotones de Coste Cero)
-- =========================================================

-- 1. Faro para zonas secas (Cuevas y Superficie)
minetest.register_node("advanced_discovery_maps:nv_beacon", {
    description = "NV Beacon (Air)",
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    drop = "",
    groups = {not_in_creative_inventory = 1},
})

-- 2. Faro para zonas sumergidas (Mantiene las físicas de nado sin generar flujo)
minetest.register_node("advanced_discovery_maps:nv_beacon_liquid", {
    description = "NV Beacon (Liquid)",
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    drop = "",
    liquidtype = "source",
    liquid_alternative_flowing = "advanced_discovery_maps:nv_beacon_liquid",
    liquid_alternative_source = "advanced_discovery_maps:nv_beacon_liquid",
    liquid_viscosity = 1,
    liquid_renewable = false,
    liquid_range = 0, -- ESTO ES CRÍTICO: Previene el colapso del CPU por cálculos de fluidos
    post_effect_color = {a = 64, r = 17, g = 47, b = 100}, -- Tinte azulado bajo el agua
    groups = {not_in_creative_inventory = 1},
})

persistent_map.player_marker = {
	arrow_size = 0.25,
	arrow_height = 0.35,
	main_body_size = 0.2,
	tip_size = 0.14,
	mid_section_size = 0.16,
	wing_size = 0.1,
	mid_section_factor = 0.5,
	wing_factor = 0.6,
}

persistent_map.map_marker = {
	scale_factor = 0.15,
	half_size_factor = 0.5,
	text_center_factor = 0.6,
	position_flip_factor = 1.0,
}

persistent_map.generation = {
	default_color_r = 100,
	default_color_g = 100,
	default_color_b = 100,
	alpha_value = 255,
	min_radius = 2,
	y_scan_step = -1,
	tile_center_offset = 2,
	initial_discovery_delay = 0.1,
}

-- Cave Map Configuration Optimizada
persistent_map.cave_scan_depth = 128
persistent_map.cave_min_height = 4
persistent_map.zoom_levels = {0.5, 1.0, 2.0, 4.0, 6.0, 8.0, 10.0, 13.0, 16.0, 20.0}
persistent_map.default_zoom_index = 2
persistent_map.min_zoom_index = 1
persistent_map.max_zoom_index = 10

persistent_map.zoom_offsets = {
	[1] = {x = 0, z = 0},
	[2] = {x = 0, z = 0},
	[3] = {x = 0, z = 0},
	[4] = {x = 1, z = -1},
	[5] = {x = 2, z = -1},
	[6] = {x = 2, z = -2},
	[7] = {x = 2, z = -2},
	[8] = {x = 2, z = -2},
	[9] = {x = 2, z = -2},
	[10] = {x = 2, z = -2},
}

persistent_map.marker_name_zoom_x_offsets = {
	[1] = 0.0,
	[2] = 0.0,
	[3] = 0.0,
	[4] = 5,
	[5] = 10,
	[6] = 20,
	[7] = 25,
	[8] = 30,
	[9] = 30,
	[10] = 30,
}

persistent_map.world_size = 64000
persistent_map.total_world_tiles = math.floor(persistent_map.world_size / persistent_map.tile_size) ^ 2

persistent_map.marker_colors = {
	{name = "Red", color = "#FF0000"},
	{name = "Blue", color = "#0000FF"},
	{name = "Green", color = "#00FF00"},
	{name = "Yellow", color = "#FFFF00"},
	{name = "Purple", color = "#FF00FF"},
	{name = "Orange", color = "#FF8000"},
	{name = "White", color = "#FFFFFF"},
	{name = "Pink", color = "#FF80FF"}
}
persistent_map.marker_delete_distance = 25

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

local storage = minetest.get_mod_storage()
local worldpath = minetest.get_worldpath()
local map_path = worldpath .. "/persistent_maps/"
minetest.mkdir(map_path)

persistent_map.storage = storage
persistent_map.map_path = map_path

local player_data = {}
local map_view_offset = {}
local map_zoom_level = {}
persistent_map.player_map_mode = {}
persistent_map.player_show_grid = {} 
persistent_map.player_units = {} 
persistent_map.active_target = {} 

-- =========================================================
-- VARIABLES DE CONTENCIÓN (ESCUDOS TERMODINÁMICOS)
-- =========================================================
local cooldowns_mapa = {}
local cooldowns_perfil = {}
local TIEMPO_ENFRIAMIENTO_MAPA = 15    -- Segundos entre comandos de actualización masiva
local TIEMPO_ENFRIAMIENTO_PERFIL = 8   -- Segundos entre lecturas transversales de VoxelManip

local function convertir_distancia(bloques, unidad)
    if unidad == "Centimetros" then return (bloques * 100), "cm"
    elseif unidad == "Kilometros" then return (bloques / 1000), "km"
    elseif unidad == "Pulgadas" then return (bloques * 39.3701), "in"
    elseif unidad == "Pies" then return (bloques * 3.28084), "ft"
    elseif unidad == "Yardas" then return (bloques * 1.09361), "yd"
    elseif unidad == "Millas" then return (bloques / 1609.34), "mi"
    else return bloques, "m" end 
end

local nodecolors = dofile(modpath .. "/nodecolors.lua")
local node_color_cache = {}

local function get_node_color(nodename)
	local cached_color = node_color_cache[nodename]
	if cached_color then
		return cached_color
	end
	
	local color = nodecolors.get_color(nodename)
	node_color_cache[nodename] = color
	return color
end

local function pos_to_tile_coords(pos)
	return math.floor(pos.x / persistent_map.tile_size),
	       math.floor(pos.z / persistent_map.tile_size)
end

local function tile_coords_to_pos(tile_x, tile_z)
	return vector.new(
		tile_x * persistent_map.tile_size + persistent_map.tile_size / 2,
		0,
		tile_z * persistent_map.tile_size + persistent_map.tile_size / 2
	)
end

local function get_tile_id(tile_x, tile_z)
	return string.format("tile_%d_%d", tile_x, tile_z)
end

local function tile_exists(tile_id)
	local filename = map_path .. tile_id .. ".png"
	local file = io.open(filename, "r")
	if file then
		file:close()
		return true
	end
	return false
end

local function load_player_markers(player_name)
	local data = storage:get_string("markers_" .. player_name)
	if data == "" then return {} end
	local markers = minetest.deserialize(data) or {}
	for marker_id, marker in pairs(markers) do
		if not marker.name then
			marker.name = string.format("Marker %d,%d", math.floor(marker.x), math.floor(marker.z))
		end
	end
	return markers
end

local function save_player_markers(player_name, markers)
	storage:set_string("markers_" .. player_name, minetest.serialize(markers))
end

local function add_marker(player_name, pos, color_index, name)
	if not player_data[player_name] then return false end
	
	local markers = player_data[player_name].markers
	local marker_id = string.format("marker_%d_%d_%d", math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
	
	if markers[marker_id] then
		return false, "Marker already exists at this position"
	end
	
	markers[marker_id] = {
		x = pos.x, y = pos.y, z = pos.z,
		color_index = color_index,
		name = name or "Unnamed",
		timestamp = os.time()
	}
	
	save_player_markers(player_name, markers)
	return true, "Marker '" .. (name or "Unnamed") .. "' placed"
end

local function remove_marker_near_player(player_name, player_pos)
	if not player_data[player_name] then return false, "Player data not found" end
	local markers = player_data[player_name].markers
	local removed_count = 0
	
	for marker_id, marker in pairs(markers) do
		local marker_pos = vector.new(marker.x, marker.y, marker.z)
		local distance = vector.distance(player_pos, marker_pos)
		if distance <= persistent_map.marker_delete_distance then
			markers[marker_id] = nil
			removed_count = removed_count + 1
		end
	end
	
	if removed_count > 0 then
		save_player_markers(player_name, markers)
		return true, string.format("Removed %d marker(s)", removed_count)
	else
		return false, "No markers found nearby"
	end
end

local function delete_all_markers(player_name)
	if not player_data[player_name] then return false, "Player data not found" end
	player_data[player_name].markers = {}
	save_player_markers(player_name, {})
	return true, "All markers deleted"
end

function persistent_map.get_player_data(player_name) return player_data[player_name] end
function persistent_map.get_map_view_offset(player_name) return map_view_offset[player_name] end
function persistent_map.set_map_view_offset(player_name, offset) map_view_offset[player_name] = offset end
function persistent_map.get_map_zoom_level(player_name) return map_zoom_level[player_name] end
function persistent_map.set_map_zoom_level(player_name, zoom_level) map_zoom_level[player_name] = zoom_level end
function persistent_map.delete_all_markers_for_player(player_name) return delete_all_markers(player_name) end
function persistent_map.save_markers_for_player(player_name, markers) return save_player_markers(player_name, markers) end
function persistent_map.add_marker_for_player(player_name, pos, name, color_index) return add_marker(player_name, pos, color_index or 1, name) end

-- Generador de Mapas Híbrido (Triple Búfer: Estándar, Relieve, Cueva)
local function generate_tile(tile_x, tile_z, callback)
    local base_id = get_tile_id(tile_x, tile_z)
    local version = persistent_map.tile_versions and persistent_map.tile_versions[base_id] or 0
    local tile_id = version > 0 and (base_id .. "_v" .. version) or base_id
    
    if tile_exists(tile_id) then
        if callback then callback(base_id) end
        return base_id
    end
    
    local minp = vector.new(tile_x * persistent_map.tile_size, persistent_map.min_height, tile_z * persistent_map.tile_size)
    local maxp = vector.new((tile_x + 1) * persistent_map.tile_size - 1, persistent_map.max_height, (tile_z + 1) * persistent_map.tile_size - 1)
    
    minetest.after(0.05, function()
        local vm = minetest.get_voxel_manip()
        local emin, emax = vm:read_from_map(minp, maxp)
        local data = vm:get_data()
        local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
        
        local c_air = minetest.get_content_id("air")
        local c_ignore = minetest.get_content_id("ignore")
        local y_stride = area.ystride
        
        local color_cache_local = {}
        local is_liquid_cache = {}
        
        local pixels_std = {}
        local pixels_rel = {}
        local pixels_cave = {}   
        local pixel_count = persistent_map.tile_size * persistent_map.tile_size
        
        for i = 1, pixel_count do 
            pixels_std[i] = ""
            pixels_rel[i] = ""
            pixels_cave[i] = ""  
        end
        
        local tile_size = persistent_map.tile_size
        local min_x, max_z = minp.x, maxp.z
        local max_y, min_y = maxp.y, minp.y
        
        local pixel_index = 1
        local heightmap_norte = {}
        local heightmap_cave_norte = {} 
        local heightmap_visual_norte = {}

        for img_y = 0, tile_size - 1 do
            local world_z = max_z - img_y
            local heightmap_actual = {}
            local heightmap_cave_actual = {}
            local heightmap_visual_actual = {}
            
            for img_x = 0, tile_size - 1 do
                local world_x = min_x + img_x
                
                local final_r = persistent_map.generation.default_color_r
                local final_g = persistent_map.generation.default_color_g
                local final_b = persistent_map.generation.default_color_b
                
                local visual_surface_y = nil
                local cid_visual = c_air
                local ground_surface_y = nil
                local solid_y = nil
                local cid_ground = c_air
                
                local in_liquid = false
                local liquid_depth = 0
                
                local best_cave_ceiling = nil
                local best_cave_height = 0
                local in_cave = false
                local cave_air_count = 0
                local cave_top_y = nil
                local state = "surface"
                
                local vi = area:index(world_x, max_y, world_z)
                for y = max_y, min_y, -1 do
                    local cid = data[vi]
                    
                    if state == "surface" then
                        if cid ~= c_air and cid ~= c_ignore then
                            if not visual_surface_y then
                                visual_surface_y = y
                                cid_visual = cid
                            end
                            
                            if not ground_surface_y then
                                local node_name = minetest.get_name_from_content_id(cid)
                                local def = minetest.registered_nodes[node_name]
                                local is_veg = def and def.groups and (def.groups.leaves or def.groups.tree or def.groups.flora or def.groups.plant or def.groups.wood)
                                
                                if not is_veg then
                                    ground_surface_y = y
                                    cid_ground = cid
                                    
                                    if is_liquid_cache[cid] == nil then
                                        is_liquid_cache[cid] = def and (def.drawtype == "liquid" or def.drawtype == "flowingliquid" or (def.groups and (def.groups.water or def.groups.lava))) or false
                                    end
                                    
                                    if is_liquid_cache[cid] then
                                        state = "liquid"
                                        in_liquid = true
                                    else
                                        solid_y = y
                                        state = "cave_scan"
                                    end
                                end
                            end
                        end
                    elseif state == "liquid" then
                        if cid ~= c_air and cid ~= c_ignore then
                            if is_liquid_cache[cid] == nil then
                                local node_name = minetest.get_name_from_content_id(cid)
                                local def = minetest.registered_nodes[node_name]
                                is_liquid_cache[cid] = def and (def.drawtype == "liquid" or def.drawtype == "flowingliquid" or (def.groups and (def.groups.water or def.groups.lava))) or false
                            end
                            if not is_liquid_cache[cid] then
                                solid_y = y
                                liquid_depth = ground_surface_y - solid_y
                                state = "cave_scan"
                            end
                        end
                    elseif state == "cave_scan" then
                        if (ground_surface_y - y) > persistent_map.cave_scan_depth then break end
                        
                        if cid == c_air then
                            if not in_cave then
                                in_cave = true
                                cave_top_y = y
                                cave_air_count = 1
                            else
                                cave_air_count = cave_air_count + 1
                            end
                        else
                            if cid ~= c_ignore then
                                if in_cave then
                                    if cave_air_count >= persistent_map.cave_min_height then
                                        if cave_air_count > best_cave_height then
                                            best_cave_height = cave_air_count
                                            best_cave_ceiling = cave_top_y
                                        end
                                    end
                                    in_cave = false
                                    cave_air_count = 0
                                end
                            end
                        end
                    end
                    vi = vi - y_stride
                end
                
                if in_cave and cave_air_count >= persistent_map.cave_min_height then
                    if cave_air_count > best_cave_height then
                        best_cave_ceiling = cave_top_y
                    end
                end

                heightmap_visual_actual[img_x] = visual_surface_y or min_y
                heightmap_actual[img_x] = solid_y or min_y
                heightmap_cave_actual[img_x] = best_cave_ceiling or 0
                
                if cid_visual ~= c_air and cid_visual ~= c_ignore then
                    local node_name = minetest.get_name_from_content_id(cid_visual)
                    if not color_cache_local[cid_visual] then
                        color_cache_local[cid_visual] = get_node_color(node_name)
                    end
                    local n_color = color_cache_local[cid_visual]
                    final_r, final_g, final_b = n_color[1], n_color[2], n_color[3]
                    
                    if in_liquid and liquid_depth > 0 and cid_visual == cid_ground then
                        local max_depth = 30
                        local factor = math.min(1.0, liquid_depth / max_depth)
                        final_r = math.floor(final_r * (1 - factor) + 0 * factor)
                        final_g = math.floor(final_g * (1 - factor) + 0 * factor)
                        final_b = math.floor(final_b * (1 - factor) + 64 * factor)
                    end
                end
                
                local ry, rg, rb = persistent_map.generation.default_color_r, persistent_map.generation.default_color_g, persistent_map.generation.default_color_b
                if cid_ground ~= c_air and cid_ground ~= c_ignore then
                    if in_liquid then
                        local depth_factor = math.min(1.0, liquid_depth / 40.0)
                        ry = math.floor(20 * (1 - depth_factor) + 5 * depth_factor)
                        rg = math.floor(180 * (1 - depth_factor) + 20 * depth_factor)
                        rb = math.floor(255 * (1 - depth_factor) + 80 * depth_factor)
                    else
                        local sy = solid_y or 0
                        if sy < 0 then
                            local depth = math.max(-100, sy)
                            ry, rg, rb = 30, 40, 50 
                        elseif sy < 50 then
                            ry, rg, rb = math.floor(50 + sy), math.floor(150 + sy), 50
                        elseif sy < 150 then
                            local h = sy - 50
                            ry, rg, rb = math.floor(200 + (h/2)), math.floor(200 - (h/2)), 50
                        elseif sy < 400 then
                            local h = sy - 150
                            ry, rg, rb = math.floor(150 - (h/3)), math.floor(100 - (h/4)), 50
                        else
                            ry, rg, rb = 240, 240, 250
                        end

                        if sy > 0 then
                            if sy % 100 == 0 then
                                ry, rg, rb = 0, 0, 0
                                final_r = math.floor(final_r * 0.4)
                                final_g = math.floor(final_g * 0.4)
                                final_b = math.floor(final_b * 0.4)
                            elseif sy % 25 == 0 then
                                ry, rg, rb = math.max(0, ry - 60), math.max(0, rg - 60), math.max(0, rb - 60)
                            end
                        end
                    end
                end

                local cr = math.floor(final_r * 0.2)
                local cg = math.floor(final_g * 0.2)
                local cb = math.floor(final_b * 0.2)

                if best_cave_ceiling then
                    local prof = (ground_surface_y or 0) - best_cave_ceiling
                    local max_prof = 100 
                    local factor = math.min(1.0, math.max(0, prof / max_prof))
                    
                    if factor < 0.25 then
                        local f = factor / 0.25
                        cr, cg, cb = 255, math.floor(255 * (1 - f) + 165 * f), 0
                    elseif factor < 0.5 then
                        local f = (factor - 0.25) / 0.25
                        cr, cg, cb = 255, math.floor(165 * (1 - f)), 0
                    elseif factor < 0.75 then
                        local f = (factor - 0.5) / 0.25
                        cr, cg, cb = math.floor(255 * (1 - f) + 128 * f), 0, math.floor(128 * f)
                    else
                        local f = (factor - 0.75) / 0.25
                        cr, cg, cb = math.floor(128 * (1 - f)), 0, math.floor(128 * (1 - f) + 255 * f)
                    end
                end
                
                local shadow_std = 1.0
                local vn = heightmap_visual_norte[img_x] or (visual_surface_y or 0)
                local vo = heightmap_visual_actual[img_x - 1] or (visual_surface_y or 0)
                local diff_v = ((visual_surface_y or 0) - vn) + ((visual_surface_y or 0) - vo)
                if diff_v > 0 then
                    shadow_std = 1.0 + math.min(0.35, diff_v * 0.05)
                elseif diff_v < 0 then
                    shadow_std = 1.0 + math.max(-0.35, diff_v * 0.05)
                end

                local shadow_rel = 1.0
                local sn = heightmap_norte[img_x] or (solid_y or 0)
                local so = heightmap_actual[img_x - 1] or (solid_y or 0)
                local diff_s = ((solid_y or 0) - sn) + ((solid_y or 0) - so)
                if diff_s > 0 then
                    shadow_rel = 1.0 + math.min(0.35, diff_s * 0.05)
                elseif diff_s < 0 then
                    shadow_rel = 1.0 + math.max(-0.35, diff_s * 0.05)
                end
                
                local cave_shadow = 1.0
                if best_cave_ceiling then
                    local cn = heightmap_cave_norte[img_x] or best_cave_ceiling
                    local co = heightmap_cave_actual[img_x - 1] or best_cave_ceiling
                    local diff_c = (best_cave_ceiling - cn) + (best_cave_ceiling - co)
                    if diff_c > 0 then
                        cave_shadow = 1.0 + math.min(0.4, diff_c * 0.05)
                    elseif diff_c < 0 then
                        cave_shadow = 1.0 + math.max(-0.4, diff_c * 0.05)
                    end
                end
                
                final_r = math.min(255, math.floor(final_r * shadow_std))
                final_g = math.min(255, math.floor(final_g * shadow_std))
                final_b = math.min(255, math.floor(final_b * shadow_std))
                pixels_std[pixel_index] = string.char(final_r, final_g, final_b, persistent_map.generation.alpha_value)
                
                ry = math.min(255, math.floor(ry * shadow_rel))
                rg = math.min(255, math.floor(rg * shadow_rel))
                rb = math.min(255, math.floor(rb * shadow_rel))
                pixels_rel[pixel_index] = string.char(ry, rg, rb, persistent_map.generation.alpha_value)
                
                cr = math.min(255, math.floor(cr * cave_shadow))
                cg = math.min(255, math.floor(cg * cave_shadow))
                cb = math.min(255, math.floor(cb * cave_shadow))
                pixels_cave[pixel_index] = string.char(cr, cg, cb, persistent_map.generation.alpha_value)
                
                pixel_index = pixel_index + 1
            end
            heightmap_norte = heightmap_actual
            heightmap_cave_norte = heightmap_cave_actual
            heightmap_visual_norte = heightmap_visual_actual
        end
        
        local filename_std = persistent_map.map_path .. tile_id .. ".png"
        local filename_rel = persistent_map.map_path .. tile_id .. "_relief.png"
        local filename_cave = persistent_map.map_path .. tile_id .. "_cave.png"
        
        local png_std = minetest.encode_png(persistent_map.tile_size, persistent_map.tile_size, table.concat(pixels_std))
        local png_rel = minetest.encode_png(persistent_map.tile_size, persistent_map.tile_size, table.concat(pixels_rel))
        local png_cave = minetest.encode_png(persistent_map.tile_size, persistent_map.tile_size, table.concat(pixels_cave))
        
        minetest.safe_file_write(filename_std, png_std)
        minetest.safe_file_write(filename_rel, png_rel)
        minetest.safe_file_write(filename_cave, png_cave)
        
        minetest.dynamic_add_media(filename_std, function()
            minetest.dynamic_add_media(filename_rel, function()
                minetest.dynamic_add_media(filename_cave, function()
                    if callback then callback(base_id) end
                end)
            end)
        end)
    end)
    
    return base_id
end

local function load_player_tiles(player_name)
	local data = storage:get_string("player_" .. player_name)
	if data == "" then return {} end
	return minetest.deserialize(data) or {}
end

local function save_player_tiles(player_name, tiles)
	storage:set_string("player_" .. player_name, minetest.serialize(tiles))
end

local function is_tile_discovered(player_name, tile_x, tile_z)
	if not player_data[player_name] then return false end
	local tiles = player_data[player_name].discovered_tiles
	local tile_id = get_tile_id(tile_x, tile_z)
	return tiles[tile_id] ~= nil
end

local function add_discovered_tile(player_name, tile_x, tile_z, callback)
	if not player_data[player_name] then return false end
	
	local tiles = player_data[player_name].discovered_tiles
	local tile_id = get_tile_id(tile_x, tile_z)
	
	if tiles[tile_id] then return false end
	
	tiles[tile_id] = {x = tile_x, z = tile_z}
	save_player_tiles(player_name, tiles)
	
	generate_tile(tile_x, tile_z, function(id)
		minetest.log("action", "[persistent_map] Generated tile: " .. id .. " for " .. player_name)
		local filename = map_path .. tile_id .. ".png"
		minetest.dynamic_add_media({
			filepath = filename,
			to_player = player_name,
		}, function(pname)
			if callback then callback() end
		end)
	end)
	
	return true
end

local function get_position_in_tile(pos)
	local tile_x, tile_z = pos_to_tile_coords(pos)
	local tile_world_x = tile_x * persistent_map.tile_size
	local tile_world_z = tile_z * persistent_map.tile_size
	local offset_x = (pos.x - tile_world_x) / persistent_map.tile_size
	local offset_z = (pos.z - tile_world_z) / persistent_map.tile_size
	return offset_x, offset_z
end

-- =========================================================
-- GENERADOR DE PERFILES LONGITUDINALES (Altimetría y Geología)
-- =========================================================
function persistent_map.generate_profile(player_name, axis, fixed_coord)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    local pos = player:get_pos()
    local profile_dir = persistent_map.map_path .. "profiles/"
    minetest.mkdir(profile_dir)

    local length = 384  
    local height_up = 64 
    local height_down = 128 
    local img_width = length
    local img_height = height_up + height_down
    local base_y = math.floor(pos.y)

    local minp, maxp
    if axis == "x" then
        minp = vector.new(math.floor(pos.x) - length/2, base_y - height_down, fixed_coord)
        maxp = vector.new(math.floor(pos.x) + length/2 - 1, base_y + height_up - 1, fixed_coord)
    else 
        minp = vector.new(fixed_coord, base_y - height_down, math.floor(pos.z) - length/2)
        maxp = vector.new(fixed_coord, base_y + height_up - 1, math.floor(pos.z) + length/2 - 1)
    end

    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local data = vm:get_data()
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    
    local c_air = minetest.get_content_id("air")
    local c_ignore = minetest.get_content_id("ignore")

    local is_liquid_cache = {}
    local color_cache = {}

    local max_elevation = -math.huge
    local min_elevation = math.huge
    local max_water_depth = 0
    local max_cave_depth = 0

    local pixels = {}
    for i = 1, img_width * img_height do
        pixels[i] = string.char(0,0,0,0)
    end

    for x = 0, img_width - 1 do
        local world_x, world_z
        if axis == "x" then
            world_x = math.floor(pos.x) - length/2 + x
            world_z = fixed_coord
        else
            world_x = fixed_coord
            world_z = math.floor(pos.z) - length/2 + x
        end

        local surface_y = nil
        for y = 0, img_height - 1 do
            local world_y = base_y + height_up - 1 - y
            local vi = area:index(world_x, world_y, world_z)
            if vi then
                local cid = data[vi]
                if cid ~= c_air and cid ~= c_ignore then
                    surface_y = world_y
                    break
                end
            end
        end

        if surface_y then
            max_elevation = math.max(max_elevation, surface_y)
            min_elevation = math.min(min_elevation, surface_y)
        end

        local in_water = false
        local water_start_y = nil
        local water_depth_local = 0

        local in_cave = false
        local cave_start = nil
        local cave_depth_local = 0

        for y = 0, img_height - 1 do
            local world_y = base_y + height_up - 1 - y
            local vi = area:index(world_x, world_y, world_z)

            local r, g, b, a = 0, 0, 0, 255
            local is_solid = false

            if vi then
                local cid = data[vi]

                if cid == c_air or cid == c_ignore then
                    if world_y > (surface_y or -math.huge) then
                        local sky_factor = math.max(0, math.min(1, (world_y - base_y) / height_up))
                        r = math.floor(135 + (120 * sky_factor))
                        g = math.floor(206 + (49 * sky_factor))
                        b = math.floor(235 + (20 * sky_factor))
                    else
                        r, g, b = 40, 20, 15
                        if not in_cave then
                            in_cave = true
                            cave_start = world_y
                        end
                    end
                else
                    is_solid = true
                    if not color_cache[cid] then
                        local node_name = minetest.get_name_from_content_id(cid)
                        color_cache[cid] = get_node_color(node_name)
                    end
                    local n_color = color_cache[cid]
                    r, g, b = n_color[1], n_color[2], n_color[3]

                    -- ALGORITMO TUXMATIC: Espectrómetro Mineral 2D (Coste Cero)
                    local node_name = minetest.get_name_from_content_id(cid)
                    if string.find(node_name, "ore") or string.find(node_name, "diamond") or string.find(node_name, "gold") or string.find(node_name, "copper") then
                        r, g, b = 0, 255, 255 -- Cian fluorescente para metales/gemas
                    elseif string.find(node_name, "coal") then
                        r, g, b = 255, 0, 255 -- Magenta fluorescente para carbón
                    end

                    if is_liquid_cache[cid] == nil then
                        local def = minetest.registered_nodes[node_name]
                        is_liquid_cache[cid] = def and (def.drawtype == "liquid" or def.drawtype == "flowingliquid" or (def.groups and (def.groups.water or def.groups.lava))) or false
                    end

                    if is_liquid_cache[cid] then
                        if not in_water then
                            in_water = true
                            water_start_y = world_y
                        end
                        if string.find(minetest.get_name_from_content_id(cid), "water") then
                            local current_depth = water_start_y - world_y
                            local darken = math.max(0.3, 1.0 - (current_depth * 0.05))
                            r = math.floor(20 * darken)
                            g = math.floor(100 * darken)
                            b = math.floor(200 * darken)
                        end
                    end

                    if surface_y and world_y <= surface_y then
                        local depth_factor = (surface_y - world_y) / 150
                        local shade = 1.0 - math.min(0.6, depth_factor)
                        r = math.floor(r * shade)
                        g = math.floor(g * shade)
                        b = math.floor(b * shade)
                    end
                end
            end

            if is_solid and vi and not is_liquid_cache[data[vi]] then
                if in_water then
                    in_water = false
                    water_depth_local = math.max(water_depth_local, water_start_y - world_y)
                end
            end
            if is_solid or (vi and is_liquid_cache[data[vi]]) then
                if in_cave then
                    in_cave = false
                    cave_depth_local = math.max(cave_depth_local, cave_start - world_y)
                end
            end

            local px, py, pz = math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
            local dx = math.abs(world_x - px)
            local dz = math.abs(world_z - pz)
            local dy = math.abs(world_y - py)

            if ((axis == "x" and dz == 0) or (axis == "z" and dx == 0)) then
                local dist_h = (axis == "x") and dx or dz
                if (dist_h == 0 and dy <= 2) or (dy == 0 and dist_h <= 2) then
                    r, g, b = 255, 0, 0
                end
            end

            if world_y == surface_y then
                r = math.min(255, r + 60)
                g = math.min(255, g + 60)
                b = math.min(255, b + 60)
            end

            local idx = (y * img_width + x) + 1
            pixels[idx] = string.char(r, g, b, a)
        end

        if in_water then water_depth_local = math.max(water_depth_local, water_start_y - (base_y - height_down)) end
        if in_cave then cave_depth_local = math.max(cave_depth_local, cave_start - (base_y - height_down)) end

        max_water_depth = math.max(max_water_depth, water_depth_local)
        max_cave_depth = math.max(max_cave_depth, cave_depth_local)
    end

    if max_elevation == -math.huge then max_elevation = 0 end
    if min_elevation == math.huge then min_elevation = 0 end

    local timestamp = os.time()
    local filename_base = string.format("perfil_%s_%s_%d.png", player_name, axis, timestamp)
    local filename_full = profile_dir .. filename_base
    
    local png = minetest.encode_png(img_width, img_height, table.concat(pixels))
    minetest.safe_file_write(filename_full, png)

    minetest.dynamic_add_media({
        filepath = filename_full,
        to_player = player_name,
    }, function(pname)
        -- Guardamos la metadata del perfil en RAM para escalado asíncrono
        local p_data = persistent_map.get_player_data(pname)
        if p_data then
            p_data.profile_view = {
                file = filename_base,
                axis = axis,
                max_e = max_elevation,
                min_e = min_elevation,
                max_w = max_water_depth,
                max_c = max_cave_depth,
                base_y = base_y,
                h_up = height_up,
                h_down = height_down,
                zoom = 1.0 -- Escala original
            }
            persistent_map.show_profile_gui(pname)
        end
    end)
end

-- =========================================================
-- MOTOR ÓPTICO: INTERFAZ DE NAVEGACIÓN Y ZOOM 2D (TUXMATIC)
-- =========================================================
function persistent_map.show_profile_gui(player_name)
    local data = persistent_map.get_player_data(player_name)
    if not data or not data.profile_view then return end
    
    local p = data.profile_view
    local z = p.zoom
    
    -- Delegamos la ampliación visual a la GPU
    local img_w = 14.0 * z
    local img_h = 7.0 * z
    
    -- Corrección Matemática: Normalización exacta sobre 1000 puntos para evitar zonas grises
    local factor_x = math.max(0, (img_w - 13.0) / 1000)
    local factor_y = math.max(0, (img_h - 7.0) / 1000)
    
    local formspec = {
        "formspec_version[6]",
        "size[16,11.5]",
        "bgcolor[#000000FF;true]",
        "label[0.5,0.5;" .. S("Análisis Topográfico") .. " (" .. string.upper(p.axis) .. ") - Escala: " .. math.floor(z * 100) .. "%]",
        
        "label[0.5,1.0;" .. S("Elevación: Máx @1m | Mín @2m", p.max_e, p.min_e) .. "]",
        "label[8.0,1.0;" .. S("Prof. Agua: @1m | Prof. Cueva: @2m", p.max_w, p.max_c) .. "]",

        -- Barras de desplazamiento perimetrales nativas
        "scrollbar[2.5,9.1;13,0.4;horizontal;prof_scroll_x;0]",
        "scrollbar[15.6,2.0;0.4,7.0;vertical;prof_scroll_y;0]",

        -- 1. Contenedor Vertical (Mueve la imagen y la escala Y juntas hacia arriba/abajo)
        "scroll_container[2.5,2.0;13,7.0;prof_scroll_y;vertical;" .. factor_y .. "]",
            
            -- 2. Contenedor Horizontal (Aislado: Mueve solo la imagen y la escala X de lado a lado)
            "scroll_container[0,0;13," .. img_h .. ";prof_scroll_x;horizontal;" .. factor_x .. "]",
                "image[0,0;" .. img_w .. "," .. img_h .. ";" .. p.file .. "]",
    }

    -- Generación Dinámica del Eje X (Distancia Longitudinal)
    -- El corte transversal tiene siempre 384 bloques. El jugador es el punto 0.
    local total_x_meters = 384
    local f_scale_x = img_w / total_x_meters
    local step_x = 64
    if z >= 2.0 then step_x = 32 end
    if z >= 4.0 then step_x = 16 end

    for x_val = -192, 192, step_x do
        local gui_x = (x_val + 192) * f_scale_x
        -- Retícula vertical translúcida
        table.insert(formspec, string.format("box[%.2f,0;0.02,%.2f;#FFFFFF30]", gui_x, img_h))
        
        local color_x = (x_val == 0) and "#FF3030" or "#AAAAAA"
        local label_x = (x_val == 0) and "0m" or (x_val .. "m")
        table.insert(formspec, string.format("style_type[label;textcolor=%s]", color_x))
        table.insert(formspec, string.format("label[%.2f,%.2f;%s]", gui_x + 0.1, img_h - 0.4, label_x))
        table.insert(formspec, "style_type[label;textcolor=#FFFFFF]")
    end
    table.insert(formspec, "scroll_container_end[]") -- Cierra el contenedor X

    -- Generación Dinámica del Eje Y (Elevación)
    -- Anclado visualmente a la izquierda (Fuera del contenedor X, pero dentro del Y)
    local total_y_meters = p.h_up + p.h_down
    local f_scale_y = img_h / total_y_meters
    local step_y = 50
    if z >= 2.0 then step_y = 25 end
    if z >= 4.0 then step_y = 10 end
    
    for y_val = math.floor((p.base_y - p.h_down)/step_y)*step_y, p.base_y + p.h_up, step_y do
        local diff = (p.base_y + p.h_up) - y_val
        if diff >= 0 and diff <= total_y_meters then
            local gui_y = diff * f_scale_y
            -- Retícula horizontal translúcida a lo largo de toda la ventana
            table.insert(formspec, string.format("box[0,%.2f;13,0.02;#FFFFFF40]", gui_y))
            
            local color_y = (y_val == p.base_y) and "#00FF88" or "#FFFFFF"
            local label_y = (y_val == p.base_y) and (y_val .. "m (Avatar)") or (y_val .. "m")
            
            table.insert(formspec, string.format("style_type[label;textcolor=%s]", color_y))
            table.insert(formspec, string.format("label[0.1,%.2f;%s]", gui_y, label_y))
            table.insert(formspec, "style_type[label;textcolor=#FFFFFF]")
        end
    end
    table.insert(formspec, "scroll_container_end[]") -- Cierra el contenedor Y
        
    -- Botones de acción fijos en la base
    table.insert(formspec, "button[2.5,10.0;3,1;prof_zoom_in;" .. S("Acercar Lente (+)") .. "]")
    table.insert(formspec, "button[5.7,10.0;3,1;prof_zoom_out;" .. S("Alejar Lente (-)") .. "]")
    table.insert(formspec, "button[8.9,10.0;3,1;back_to_map;" .. S("Volver al Mapa") .. "]")
    table.insert(formspec, "button[12.1,10.0;3,1;close_profile;" .. S("Cerrar Escáner") .. "]")

    minetest.show_formspec(player_name, "persistent_map:profile", table.concat(formspec))
end

function persistent_map.show_map(player_name)
    local ui = persistent_map.ui
    local padding = ui.padding
    local side_panel_width = ui.side_panel_width
    local header_height = ui.header_height
    local button_size = ui.button_size
    local formspec = {}

	local player = minetest.get_player_by_name(player_name)
	if not player then return end
	if not player_data[player_name] then return end
	
	local tiles = player_data[player_name].discovered_tiles
	local markers = player_data[player_name].markers
	local pos = player:get_pos()
	local center_tile_x, center_tile_z = pos_to_tile_coords(pos)
	
	local view_offset = map_view_offset[player_name] or {x = 0, z = 0}
	local zoom_index = map_zoom_level[player_name] or persistent_map.default_zoom_index
	local zoom_factor = persistent_map.zoom_levels[zoom_index]
	local zoom_offset = persistent_map.zoom_offsets[zoom_index] or {x = 0, z = 0}
	
	local view_center_x = center_tile_x + view_offset.x + zoom_offset.x
	local view_center_z = center_tile_z + view_offset.z + zoom_offset.z
	
	local offset_x, offset_z = get_position_in_tile(pos)

    local offset_text = ""
	if view_offset.x ~= 0 or view_offset.z ~= 0 then
		offset_text = string.format(" (View offset: X%+d, Z%+d)", view_offset.x, view_offset.z)
	end

	local base_radius = persistent_map.view_radius
	local radius = math.max(persistent_map.generation.min_radius, math.floor(base_radius / zoom_factor))
	local view_size = radius * 2 + 1
	local tile_display_size = persistent_map.gui_tile_size * zoom_factor
	
	local ancho_terreno_visible = (view_size * persistent_map.tile_size) / zoom_factor
	local altitud_camara = math.floor(ancho_terreno_visible / 2)
	
	local base_tile_size = persistent_map.gui_tile_size
	local base_view_size = persistent_map.view_radius * 2 + 1
	local map_width = base_view_size * base_tile_size
	local map_height = base_view_size * base_tile_size
	
	local left_panel_x = padding
	local map_x = left_panel_x + side_panel_width + padding
	local right_panel_x = map_x + map_width + padding

	local total_width =
	    padding +
	    side_panel_width +
	    padding +
	    map_width +
	    padding +
	    side_panel_width +
	    padding

	local info_panel_height = 4.0

	local total_height = math.max(
	    map_height + header_height + padding * 2 + info_panel_height,
	    persistent_map.ui.min_formspec_height
	)

	local half_total_width =
	    total_width * persistent_map.ui.total_width_factor

	local header_y = padding
	local map_start_x = map_x
	local map_start_y = padding + header_height

	local info_y = map_start_y + map_height + 0.8
    
    local unidad = persistent_map.player_units[player_name] or "Metros"
	
	formspec[1] = string.format("formspec_version[%d]", persistent_map.ui.formspec_version)
	formspec[2] = string.format("size[%.2f,%.2f]", total_width, total_height)
	formspec[3] = "bgcolor[#000000FF;true]"
	formspec[4] = string.format("label[%.2f,%.2f;%s]", half_total_width - persistent_map.ui.header_title_offset, padding, S("Discovered Map - Close with ESC"))
	local formspec_index = 5
	
	local scroll_width = map_width
	local scroll_height = map_height
	local actual_content_width = view_size * tile_display_size
	local actual_content_height = view_size * tile_display_size
	local scroll_init = math.max(0, (actual_content_width - scroll_width) * persistent_map.ui.scroll_content_center)
	
	formspec[formspec_index] = string.format(
		"scroll_container[%.2f,%.2f;%.2f,%.2f;map_scroll;horizontal;%.2f]",
		map_x, map_start_y, scroll_width, scroll_height, scroll_init
	)
	formspec_index = formspec_index + 1
	
	local discovered_count = 0
	local total_tiles = view_size * view_size
	local player_tiles = player_data[player_name].discovered_tiles
	
	for gui_row = 0, view_size - 1 do
		local tile_z_base = view_center_z + radius - gui_row 
		local gui_y = gui_row * tile_display_size
		
		for gui_col = 0, view_size - 1 do
			local tile_x = view_center_x + gui_col - radius
			local tile_z = tile_z_base
			local gui_x = gui_col * tile_display_size
			
			local tile_id = string.format("tile_%d_%d", tile_x, tile_z)
			if player_tiles[tile_id] then
				discovered_count = discovered_count + 1
				
				local version = persistent_map.tile_versions and persistent_map.tile_versions[tile_id] or 0
				local file_id = version > 0 and (tile_id .. "_v" .. version) or tile_id
				
				local mode = persistent_map.player_map_mode[player_name] or "standard"
				local display_file = file_id
				if mode == "relief" then
				    display_file = file_id .. "_relief"
				elseif mode == "cave" then
				    display_file = file_id .. "_cave"
				end
				
				if tile_exists(display_file) then
					formspec[formspec_index] = string.format(
						"image_button[%.2f,%.2f;%.2f,%.2f;%s.png;map_click_%d_%d;;false;false;]",
						gui_x, gui_y, tile_display_size, tile_display_size, display_file, tile_x, tile_z
					)
				else
					formspec[formspec_index] = string.format(
						"box[%.2f,%.2f;%.2f,%.2f;#404040]",
						gui_x, gui_y, tile_display_size, tile_display_size
					)
				end
			else
				formspec[formspec_index] = string.format(
					"box[%.2f,%.2f;%.2f,%.2f;#000000]",
					gui_x, gui_y, tile_display_size, tile_display_size
				)
			end
			formspec_index = formspec_index + 1
		end
	end
	
	-- RENDERIZADO DE CUADRÍCULA CARTESIANA
	local show_grid = persistent_map.player_show_grid[player_name] or false
	if show_grid then
	    local grid_step = 1024
        if zoom_factor >= 8.0 then grid_step = 64
        elseif zoom_factor >= 4.0 then grid_step = 128
        elseif zoom_factor >= 2.0 then grid_step = 256
        elseif zoom_factor >= 1.0 then grid_step = 512
        end

	    for gui_row = 0, view_size - 1 do
	        local tile_z_base = view_center_z + radius - gui_row
	        local gui_y = gui_row * tile_display_size
            for gui_col = 0, view_size - 1 do
                local tile_x = view_center_x + gui_col - radius
                local gui_x = gui_col * tile_display_size
                
                if tile_x == 0 then
                    formspec[formspec_index] = string.format("box[%.2f,%.2f;%.2f,%.2f;#FFFFFF80]", gui_x, gui_y, 0.1, tile_display_size)
                    formspec_index = formspec_index + 1
                end
                if tile_z_base == 0 then
                    formspec[formspec_index] = string.format("box[%.2f,%.2f;%.2f,%.2f;#FFFFFF80]", gui_x, gui_y, tile_display_size, 0.1)
                    formspec_index = formspec_index + 1
                end
                
                if (tile_x * persistent_map.tile_size) % grid_step == 0 then
                    formspec[formspec_index] = string.format("box[%.2f,%.2f;%.2f,%.2f;#FFFFFF30]", gui_x, gui_y, 0.05, tile_display_size)
                    formspec_index = formspec_index + 1
                    
                    if zoom_factor >= 2.0 and gui_row == 0 then
                        formspec[formspec_index] = string.format("label[%.2f,%.2f;X:%d]", gui_x + 0.1, map_start_y + 0.2, tile_x * persistent_map.tile_size)
                        formspec_index = formspec_index + 1
                    end
                end
                
                if (tile_z_base * persistent_map.tile_size) % grid_step == 0 then
                    formspec[formspec_index] = string.format("box[%.2f,%.2f;%.2f,%.2f;#FFFFFF30]", gui_x, gui_y, tile_display_size, 0.05)
                    formspec_index = formspec_index + 1
                    
                    if zoom_factor >= 2.0 and gui_col == 0 then
                        formspec[formspec_index] = string.format("label[%.2f,%.2f;Z:%d]", map_x + 0.1, gui_y + 0.4, tile_z_base * persistent_map.tile_size)
                        formspec_index = formspec_index + 1
                    end
                end
            end
	    end
	end
	
	local marker_scale_factor = persistent_map.map_marker.scale_factor * persistent_map.marker_scale * zoom_factor
	local half_marker_size = marker_scale_factor * persistent_map.map_marker.half_size_factor
	local tile_size_f = persistent_map.tile_size
	
	for marker_id, marker in pairs(markers) do
		local marker_tile_x = math.floor(marker.x / tile_size_f)
		local marker_tile_z = math.floor(marker.z / tile_size_f)
		
		local marker_offset_x = marker_tile_x - view_center_x
		local marker_offset_z = marker_tile_z - view_center_z
		
		if math.abs(marker_offset_x) <= radius and math.abs(marker_offset_z) <= radius then
			local gui_col = marker_offset_x + radius
			local gui_row = radius - marker_offset_z 
			
			local marker_tile_gui_x = gui_col * tile_display_size
			local marker_tile_gui_y = gui_row * tile_display_size
			
			local tile_world_x = marker_tile_x * tile_size_f
			local tile_world_z = marker_tile_z * tile_size_f
			local marker_offset_in_tile_x = (marker.x - tile_world_x) / tile_size_f
			local marker_offset_in_tile_z = (marker.z - tile_world_z) / tile_size_f
			
			local marker_gui_x = marker_tile_gui_x + (marker_offset_in_tile_x * tile_display_size)
			local marker_gui_y = marker_tile_gui_y + ((1.0 - marker_offset_in_tile_z) * tile_display_size)
			
			local color = persistent_map.marker_colors[marker.color_index] or persistent_map.marker_colors[1]
			for stack_layer = 1, 5 do
				formspec[formspec_index] = string.format(
					"box[%.2f,%.2f;%.2f,%.2f;%s]",
					marker_gui_x - half_marker_size, marker_gui_y - half_marker_size,
					marker_scale_factor, marker_scale_factor, color.color
				)
				formspec_index = formspec_index + 1
			end
			
			local marker_name = marker.name or "Unnamed"
			if marker_name ~= "" and zoom_factor >= persistent_map.marker_name_min_zoom then 
				local text_scale = math.max(persistent_map.marker_name_scale, zoom_factor * persistent_map.marker_name_zoom_multiplier)
				local char_width = persistent_map.marker_name_char_width * text_scale
				local text_height = persistent_map.marker_name_text_height * text_scale
				
				local name_y = marker_gui_y - half_marker_size - (text_height + persistent_map.marker_name_padding)
				local text_width = string.len(marker_name) * char_width
				local name_x = marker_gui_x - (text_width * persistent_map.map_marker.text_center_factor)
				
				local marker_name_x_offset = persistent_map.marker_name_zoom_x_offsets[zoom_index] or 0.0
				name_x = name_x + marker_name_x_offset
				
				local font_sz = math.floor(text_scale * persistent_map.marker_name_font_multiplier)
				local safe_name = minetest.formspec_escape(marker_name)
				local offset = 0.05 
				
				local shadow_color = "#000000"
				formspec[formspec_index] = string.format("style[marker_name_sh1_%s;font_size=+%d;textcolor=%s]", marker_id, font_sz, shadow_color)
				formspec[formspec_index+1] = string.format("label[%.2f,%.2f;%s]", name_x - offset, name_y, safe_name)
				
				formspec[formspec_index+2] = string.format("style[marker_name_sh2_%s;font_size=+%d;textcolor=%s]", marker_id, font_sz, shadow_color)
				formspec[formspec_index+3] = string.format("label[%.2f,%.2f;%s]", name_x + offset, name_y, safe_name)
				
				formspec[formspec_index+4] = string.format("style[marker_name_sh3_%s;font_size=+%d;textcolor=%s]", marker_id, font_sz, shadow_color)
				formspec[formspec_index+5] = string.format("label[%.2f,%.2f;%s]", name_x, name_y - offset, safe_name)
				
				formspec[formspec_index+6] = string.format("style[marker_name_sh4_%s;font_size=+%d;textcolor=%s]", marker_id, font_sz, shadow_color)
				formspec[formspec_index+7] = string.format("label[%.2f,%.2f;%s]", name_x, name_y + offset, safe_name)
				
				formspec[formspec_index+8] = string.format("style[marker_name_w_%s;font_size=+%d;textcolor=#FFFFFF]", marker_id, font_sz)
				formspec[formspec_index+9] = string.format("label[%.2f,%.2f;%s]", name_x, name_y, safe_name)
				
				formspec_index = formspec_index + 10
			end
		end
	end
	
	-- =========================================================
	-- AVATAR DE NAVEGACIÓN: EL TRIÁNGULO PERCEPTUAL CALIBRADO
	-- Arquitectura: Cierre de Gestalt compacto con escalado híbrido.
	-- =========================================================
	local function render_tactical_avatar(p_pos, p_yaw, p_color, is_party, m_name)
		local marker_tile_x = math.floor(p_pos.x / persistent_map.tile_size)
		local marker_tile_z = math.floor(p_pos.z / persistent_map.tile_size)

		local t_off_x = marker_tile_x - view_center_x
		local t_off_z = marker_tile_z - view_center_z

		if math.abs(t_off_x) <= radius and math.abs(t_off_z) <= radius then
			local p_col = t_off_x + radius
			local p_row = radius - t_off_z
			local off_x, off_z = get_position_in_tile(p_pos)

			local marker_x = (p_col + off_x) * tile_display_size
			local marker_y = (p_row + (persistent_map.map_marker.position_flip_factor - off_z)) * tile_display_size

			-- =====================================================
			-- ESCALADO TÁCTICO ADAPTATIVO
			-- =====================================================
			local base_scale = is_party and (persistent_map.player_marker_scale * 0.82) or persistent_map.player_marker_scale

			-- Curva híbrida: crecimiento rápido inicial, desaceleración progresiva
			local zoom_response = math.pow(zoom_factor, 0.72)
			local dampening = 1 / (1 + math.log(zoom_factor + 1) * 0.28)
			
			local final_scale = base_scale * zoom_response * dampening

			-- =====================================================
			-- TAMAÑOS GEOMÉTRICOS (Refinación de Núcleo Doble)
			-- =====================================================
			-- Se estilizan las proporciones para un aspecto más afilado y preciso
			local main_size = math.max(0.18, final_scale * 0.20)
			local tip_size  = math.max(0.10, final_scale * 0.12) -- Punta más fina
			local mid_size  = math.max(0.06, final_scale * 0.08) -- Núcleo central reducido
			local wing_size = math.max(0.08, final_scale * 0.10)

			local half_main = main_size * 0.5
			local half_tip  = tip_size * 0.5
			local half_mid  = mid_size * 0.5
			local half_wing = wing_size * 0.5

			-- Trigonometría y Navegación
			local cos_a = math.cos(p_yaw)
			local sin_a = math.sin(p_yaw)

			-- =====================================================
			-- DISTANCIAS COMPACTADAS (Vectores Agudizados)
			-- =====================================================
			local front_dist = final_scale * 0.90 -- Proyectamos la punta un poco más
			local wing_dist  = final_scale * 0.45

			local tip_x = marker_x - sin_a * front_dist
			local tip_y = marker_y - cos_a * front_dist

			-- El núcleo se queda exactamente en el centro (marker_x, marker_y)
			
			local wing1_x = marker_x + cos_a * wing_dist
			local wing1_y = marker_y - sin_a * wing_dist

			local wing2_x = marker_x - cos_a * wing_dist
			local wing2_y = marker_y + sin_a * wing_dist

			-- =====================================================
			-- 1. RETÍCULA DE NAVEGACIÓN (Guía Visual Periférica)
			-- =====================================================
			local reticle_len = final_scale * 1.2
			local reticle_thick = math.max(0.02, final_scale * 0.03)
			local gap = final_scale * 0.6 -- Espacio vacío entre el avatar y la línea
			local reticle_color = "#FFFFFF88" -- Blanco semitransparente para no estorbar

			-- Línea Norte
			formspec[formspec_index] = string.format("box[%.2f,%.2f;%.2f,%.2f;%s]", marker_x - reticle_thick/2, marker_y - reticle_len - gap, reticle_thick, reticle_len, reticle_color)
			formspec_index = formspec_index + 1
			-- Línea Sur
			formspec[formspec_index] = string.format("box[%.2f,%.2f;%.2f,%.2f;%s]", marker_x - reticle_thick/2, marker_y + gap, reticle_thick, reticle_len, reticle_color)
			formspec_index = formspec_index + 1
			-- Línea Este
			formspec[formspec_index] = string.format("box[%.2f,%.2f;%.2f,%.2f;%s]", marker_x + gap, marker_y - reticle_thick/2, reticle_len, reticle_thick, reticle_color)
			formspec_index = formspec_index + 1
			-- Línea Oeste
			formspec[formspec_index] = string.format("box[%.2f,%.2f;%.2f,%.2f;%s]", marker_x - reticle_len - gap, marker_y - reticle_thick/2, reticle_len, reticle_thick, reticle_color)
			formspec_index = formspec_index + 1

			-- =====================================================
			-- 2. AVATAR PRINCIPAL (Sombra Expandida y Delineado)
			-- =====================================================
			local sh_exp = math.max(0.04, final_scale * 0.05)

			-- Sombra Central Expandida (Base de contraste suave)
			formspec[formspec_index] = string.format(
				"box[%.2f,%.2f;%.2f,%.2f;#000000BB]",
				marker_x - half_main - sh_exp/2, marker_y - half_main - sh_exp/2, main_size + sh_exp, main_size + sh_exp
			)
			formspec_index = formspec_index + 1

			-- Cuerpo Principal
			formspec[formspec_index] = string.format(
				"box[%.2f,%.2f;%.2f,%.2f;%s]",
				marker_x - half_main, marker_y - half_main, main_size, main_size, p_color
			)
			formspec_index = formspec_index + 1

			-- Sombra de Punta Frontal
			formspec[formspec_index] = string.format(
				"box[%.2f,%.2f;%.2f,%.2f;#000000BB]",
				tip_x - half_tip - sh_exp/2, tip_y - half_tip - sh_exp/2, tip_size + sh_exp, tip_size + sh_exp
			)
			formspec_index = formspec_index + 1

			-- Punta Frontal
			formspec[formspec_index] = string.format(
				"box[%.2f,%.2f;%.2f,%.2f;%s]",
				tip_x - half_tip, tip_y - half_tip, tip_size, tip_size, p_color
			)
			formspec_index = formspec_index + 1

			-- Ala Derecha
			formspec[formspec_index] = string.format(
				"box[%.2f,%.2f;%.2f,%.2f;%s]",
				wing1_x - half_wing, wing1_y - half_wing, wing_size, wing_size, p_color
			)
			formspec_index = formspec_index + 1

			-- Ala Izquierda
			formspec[formspec_index] = string.format(
				"box[%.2f,%.2f;%.2f,%.2f;%s]",
				wing2_x - half_wing, wing2_y - half_wing, wing_size, wing_size, p_color
			)
			formspec_index = formspec_index + 1

			-- =====================================================
			-- 3. NÚCLEO DE PRECISIÓN ABSOLUTA
			-- =====================================================
			local core_size = math.max(0.06, final_scale * 0.08)
			formspec[formspec_index] = string.format(
				"box[%.2f,%.2f;%.2f,%.2f;#FFFFFF]",
				marker_x - (core_size/2), marker_y - (core_size/2), core_size, core_size
			)
			formspec_index = formspec_index + 1

			-- Etiquetas de la Party
			if is_party and m_name and zoom_factor >= persistent_map.marker_name_min_zoom then
				local n_scale = math.max(persistent_map.marker_name_scale, zoom_factor * persistent_map.marker_name_zoom_multiplier)
				local n_char_w = persistent_map.marker_name_char_width * n_scale
				local n_text_h = persistent_map.marker_name_text_height * n_scale

				local name_y = marker_y - half_main - (n_text_h + persistent_map.marker_name_padding)
				local n_width = string.len(m_name) * n_char_w
				local name_x = marker_x - (n_width * persistent_map.map_marker.text_center_factor)

				name_x = name_x + (persistent_map.marker_name_zoom_x_offsets[zoom_index] or 0.0)

				formspec[formspec_index] = string.format(
					"style[party_member_%s;font_size=+%d]",
					m_name, math.floor(n_scale * persistent_map.marker_name_font_multiplier)
				)
				formspec_index = formspec_index + 1

				formspec[formspec_index] = string.format(
					"label[%.2f,%.2f;%s]",
					name_x, name_y, minetest.formspec_escape(m_name)
				)
				formspec_index = formspec_index + 1
			end
		end
	end

	-- 1. Renderizar Party (Para que queden visualmente debajo del jugador principal)
	if persistent_map.get_party_member_positions then
		local party_members = persistent_map.get_party_member_positions(player_name)
		for member_name, member_data in pairs(party_members) do
			render_tactical_avatar(member_data.pos, member_data.yaw, "#0080FF", true, member_name)
		end
	end

	-- 2. Renderizar Jugador Principal
	local avatar_color = "#FF3030"
	local mode_av = persistent_map.player_map_mode[player_name] or "standard"
	if mode_av == "relief" then
		avatar_color = "#101010"
	elseif mode_av == "cave" then
		avatar_color = "#00D8FF"
	end
	
	render_tactical_avatar(pos, player:get_look_horizontal(), avatar_color, false)

    -- Cierre del Contenedor de Scroll (Todo se dibuja y recorta correctamente ahora)
	formspec[formspec_index] = "scroll_container_end[]"
	formspec_index = formspec_index + 1
	
	-- PANELES LATERALES
	local left_panel_y = padding + header_height + persistent_map.ui.nav_panel_offset
	
	formspec[formspec_index] = string.format(
		"label[%.2f,%.2f;%s]",
		left_panel_x, left_panel_y, S("Navigation:")
	)
	formspec_index = formspec_index + 1
	
	local nav_start_y = left_panel_y + persistent_map.ui.nav_section_spacing
	local nav_center_x = left_panel_x + side_panel_width / 2
	
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;nav_north;%s]",
		nav_center_x - button_size / persistent_map.ui.half_divisor, nav_start_y, button_size, button_size, S("N ↑")
	))
	
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;nav_west;%s]",
		nav_center_x - button_size * persistent_map.ui.nav_button_multiplier, nav_start_y + button_size + persistent_map.ui.nav_button_spacing, button_size, button_size, S("W ←")
	))
	
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;nav_east;%s]",
		nav_center_x + persistent_map.ui.nav_button_spacing, nav_start_y + button_size + persistent_map.ui.nav_button_spacing, button_size, button_size, S("E →")
	))
	
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;nav_south;%s]",
		nav_center_x - button_size / persistent_map.ui.half_divisor, nav_start_y + button_size * persistent_map.ui.padding_multiplier + persistent_map.ui.nav_button_spacing * persistent_map.ui.padding_multiplier, button_size, button_size, S("S ↓")
	))
	
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;nav_center;%s]",
		left_panel_x, nav_start_y + button_size * 3 + persistent_map.ui.nav_center_button_offset, side_panel_width - persistent_map.ui.button_width_offset, button_size, S("Center on Player")
	))
	
	local zoom_y = nav_start_y + button_size * 4 + persistent_map.ui.zoom_section_offset
	table.insert(formspec, string.format(
		"label[%f,%f;%s]",
		left_panel_x, zoom_y, S("Zoom: @1x", zoom_factor)
	))
	
	local zoom_button_width = (side_panel_width - persistent_map.ui.nav_center_button_offset) / persistent_map.ui.half_divisor
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;zoom_out;%s]",
		left_panel_x, zoom_y + persistent_map.ui.zoom_button_spacing, zoom_button_width, button_size, S("Zoom Out (-)")
	))
	
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;zoom_in;%s]",
		left_panel_x + zoom_button_width + persistent_map.ui.zoom_button_spacing, zoom_y + persistent_map.ui.zoom_button_spacing, zoom_button_width, button_size, S("Zoom In (+)")
	))
	
	local mode = persistent_map.player_map_mode[player_name] or "standard"
    local mode_text = S("View Satellite") 
    if mode == "standard" then
        mode_text = S("View Relief")
    elseif mode == "relief" then
        mode_text = S("View Cave Map")
    end
	
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;toggle_map_mode;%s]",
		left_panel_x, zoom_y + button_size * 2, side_panel_width - persistent_map.ui.button_width_offset, button_size, mode_text
	))
    
    local grid_mode = persistent_map.player_show_grid[player_name] or false
    local grid_text = grid_mode and S("Hide Grid (Quadrants)") or S("Show Grid (Quadrants)")
    
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;toggle_grid;%s]",
		left_panel_x, zoom_y + button_size * 3.2, side_panel_width - persistent_map.ui.button_width_offset, button_size, grid_text
	))

    local unit_y = zoom_y + button_size * 4.5
    table.insert(formspec, string.format(
        "label[%f,%f;%s:]",
        left_panel_x, unit_y,
        S("Measurement Unit")
    ))
    
    local dropdown_idx = unidad == "Metros" and 1 or unidad == "Centimetros" and 2 or unidad == "Kilometros" and 3 or unidad == "Pulgadas" and 4 or unidad == "Pies" and 5 or unidad == "Yardas" and 6 or unidad == "Millas" and 7 or 1
    
    table.insert(formspec, string.format(
    "dropdown[%f,%f;%f,1.4;unidad_selector;Metros,Centimetros,Kilometros,Pulgadas,Pies,Yardas,Millas;%d]",
    left_panel_x, unit_y + 0.8, side_panel_width - 1.0, dropdown_idx
    ))
	
    -- PANEL DERECHO 
	local right_panel_y = padding + header_height + persistent_map.ui.nav_panel_offset
	
	table.insert(formspec, string.format(
		"label[%f,%f;%s]",
		right_panel_x, right_panel_y, S("Place Marker:")
	))
	
	local name_input_y = right_panel_y + persistent_map.ui.nav_section_spacing
	table.insert(formspec, string.format(
		"label[%f,%f;%s]",
		right_panel_x, name_input_y, S("Marker Name:")
	))
	
	table.insert(formspec, string.format(
		"field[%f,%f;%f,%f;marker_name;;]",
		right_panel_x, name_input_y + persistent_map.ui.marker_name_label_spacing, side_panel_width - persistent_map.ui.field_width_offset, persistent_map.ui.marker_name_field_height
	))
	
	local marker_start_y = name_input_y + persistent_map.ui.marker_colors_offset
	local colors_per_row = persistent_map.ui.colors_per_row
	local color_button_size = persistent_map.ui.color_button_size
	
	for i, color_info in ipairs(persistent_map.marker_colors) do
		local row = math.floor((i - 1) / colors_per_row)
		local col = (i - 1) % colors_per_row
		local btn_x = right_panel_x + col * (color_button_size + persistent_map.ui.color_button_spacing)
		local btn_y = marker_start_y + row * (color_button_size + persistent_map.ui.color_button_row_spacing)
		
		table.insert(formspec, string.format(
			"box[%f,%f;%f,%f;%s]",
			btn_x, btn_y, color_button_size, color_button_size, color_info.color
		))
		
		table.insert(formspec, string.format(
			"button[%f,%f;%f,%f;add_marker_%d;%s]",
			btn_x, btn_y, color_button_size, color_button_size, i, S(color_info.name)
		))
	end
	
	local manage_y = marker_start_y + math.ceil(#persistent_map.marker_colors / colors_per_row) * (color_button_size + persistent_map.ui.color_button_row_spacing) + persistent_map.ui.delete_buttons_offset
	
	table.insert(formspec, string.format(
		"button[%f,%f;%f,%f;manage_markers;%s]",
		right_panel_x, manage_y, side_panel_width - persistent_map.ui.button_width_offset, button_size, S("Manage Markers")
	))

    local target_label_y = manage_y + button_size + 0.8
    table.insert(formspec, string.format(
        "label[%f,%f;%s:]",
        right_panel_x, target_label_y,
        S("Track Marker")
    ))
    
    local target_opts_raw = {S("Closest")}
    local target_opts_escaped = {minetest.formspec_escape(S("Closest"))}
    local target_ids = {"closest"}
    local selected_target_idx = 1
    local target_id = persistent_map.active_target[player_name] or "closest"
    
    local opt_idx = 2
    for id, m in pairs(markers) do
        local safe_name = string.gsub(m.name or "Unnamed", ",", "") 
        local opt_name = string.format("%s (%d %d)", safe_name, math.floor(m.x), math.floor(m.z))
        
        table.insert(target_opts_raw, opt_name)
        table.insert(target_opts_escaped, minetest.formspec_escape(opt_name))
        table.insert(target_ids, id)
        
        if target_id == id then
            selected_target_idx = opt_idx
        end
        opt_idx = opt_idx + 1
    end
    
    player_data[player_name].target_dropdown_map = target_ids
    player_data[player_name].target_dropdown_opts = target_opts_raw
    
    table.insert(formspec, string.format(
        "dropdown[%f,%f;%f,1.4;target_selector;%s;%d]",
        right_panel_x, target_label_y + 0.6, side_panel_width - 1.0, 
        table.concat(target_opts_escaped, ","), selected_target_idx
    ))

    local profile_y = target_label_y + 2.5
    table.insert(formspec, string.format(
        "label[%f,%f;%s:]",
        right_panel_x, profile_y, S("Topographic Analysis")
    ))
    
    local half_btn = (side_panel_width - persistent_map.ui.button_width_offset) / 2 - 0.1
    table.insert(formspec, string.format(
        "button[%f,%f;%f,%f;perfil_x;%s]",
        right_panel_x, profile_y + 0.8, half_btn, button_size, S("Profile X (E-W)")
    ))
    table.insert(formspec, string.format(
        "button[%f,%f;%f,%f;perfil_z;%s]",
        right_panel_x + half_btn + 0.2, profile_y + 0.8, half_btn, button_size, S("Profile Z (N-S)")
    ))
	
	local total_discovered = 0
	for _ in pairs(tiles) do total_discovered = total_discovered + 1 end
	
	local marker_count = 0
	for _ in pairs(markers) do marker_count = marker_count + 1 end
    
    local marcador_cercano = S("None")
	local dist_min = math.huge
    local current_target = persistent_map.active_target[player_name] or "closest"
    
    if current_target == "closest" or not markers[current_target] then
        for _, m in pairs(markers) do
            local dx, dy, dz = m.x - pos.x, m.y - pos.y, m.z - pos.z
            local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
            if dist < dist_min then 
                dist_min = dist
                marcador_cercano = m.name 
            end
        end
    else
        local m = markers[current_target]
        local dx, dy, dz = m.x - pos.x, m.y - pos.y, m.z - pos.z
        dist_min = math.sqrt(dx*dx + dy*dy + dz*dz)
        marcador_cercano = m.name
    end
    
    local dist_texto = dist_min ~= math.huge and string.format("%.1f %s", convertir_distancia(dist_min, unidad)) or "N/A"
	
	local info_y = map_start_y + map_height + 0.5
	local col_left = map_x + 0.5
	local col_right = map_x + (map_width / 2) + 0.5
	
	table.insert(formspec, string.format(
		"box[%f,%f;%f,3.6;#1A1A1ACC]",
		map_x, info_y - 0.2, map_width, 2.5
	))
	
	table.insert(formspec, string.format(
		"label[%f,%f;%s: X=%d, Y=%d, Z=%d]",
		col_left, info_y,
		S("Coordinates"), math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)
	))
	
	table.insert(formspec, string.format(
		"label[%f,%f;%s: %s | %s: %s]",
		col_left, info_y + 1.2,
		S("Destination"), minetest.formspec_escape(marcador_cercano), S("Distance"), dist_texto
	))
	
	table.insert(formspec, string.format(
		"label[%f,%f;%s: %d, %d | %s: %d%%]",
		col_right, info_y,
		S("Quadrant"), center_tile_x, center_tile_z,
        S("Explored"), (total_discovered / persistent_map.total_world_tiles) * 100
	))
	
	table.insert(formspec, string.format(
		"label[%f,%f;%s: %d | %s: %d | %s: %dm]",
		col_right, info_y + 1.2,
		S("View"), discovered_count, S("Markers"), marker_count, S("Camera Alt"), altitud_camara
	))
	
	minetest.show_formspec(player_name, "persistent_map:map", table.concat(formspec))
end

minetest.register_chatcommand("map", {
    params = "",
    description = S("Abre la interfaz principal del Mapa Telemétrico Avanzado.\n") ..
                  S("Uso: /map\n") ..
                  S("Desde la interfaz puedes analizar topografía, gestionar rastreadores y ver relieves 3D."),
    func = function(name)
        map_view_offset[name] = {x = 0, z = 0}
        if not map_zoom_level[name] then
            map_zoom_level[name] = persistent_map.default_zoom_index
        end
        persistent_map.show_map(name)
        return true, S("Map opened")
    end,
})

-- =========================================================
-- COMANDO: VISIÓN NOCTURNA TÁCTICA
-- =========================================================
minetest.register_chatcommand("nv", {
    description = S("Activa/Desactiva la Visión Nocturna Táctica.\n") ..
                  S("Uso: /nv\n") ..
                  S("Emisor adaptativo que ilumina cuevas y zonas submarinas con coste cero."),
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false end
        
        local data = persistent_map.get_player_data(name)
        if not data then return false, S("Datos no inicializados.") end

        data.nv_active = not data.nv_active

        if data.nv_active then
            player:override_day_night_ratio(1.0)
            minetest.chat_send_player(name, minetest.colorize("#00FF88", S(">> Visión Nocturna: ACTIVADA")))
        else
            player:override_day_night_ratio(nil)
            -- Restaurar el bloque físico al apagar el sistema
            if data.nv_pos and data.nv_saved_node then
                local node = minetest.get_node(data.nv_pos)
                if node.name == "advanced_discovery_maps:nv_beacon" or node.name == "advanced_discovery_maps:nv_beacon_liquid" then
                    minetest.swap_node(data.nv_pos, data.nv_saved_node)
                end
                data.nv_pos = nil
                data.nv_saved_node = nil
            end
            minetest.chat_send_player(name, minetest.colorize("#FF8800", S(">> Visión Nocturna: DESACTIVADA")))
        end
        return true
    end,
})

-- =========================================================
-- COMANDO: CONTROL DE PROPULSIÓN (VUELO)
-- =========================================================
minetest.register_chatcommand("flyspeed", {
    params = "<velocidad>",
    description = S("Controla la velocidad de vuelo.\n") ..
                  S("Uso: /flyspeed <número>\n") ..
                  S("Nota: Solo se activa en el aire para no alterar la velocidad en tierra."),
    privs = { fly = true },
    func = function(name, param)
        local speed = tonumber(param)
        if speed and speed >= 0 then
            local data = persistent_map.get_player_data(name)
            if data then
                data.target_flyspeed = speed
                data.fly_state = nil -- Forzamos la actualización física en el próximo tick
                minetest.chat_send_player(name, minetest.colorize("#00FF88", S(">> Velocidad de vuelo establecida a @1", param)))
                return true
            end
        end
        return false, minetest.colorize("#ff0000", S("Velocidad inválida. Usa un número positivo."))
    end,
})

-- =========================================================
-- COMANDOS: CONTROL DE ATLETISMO (CARRERA Y SALTO)
-- =========================================================
minetest.register_chatcommand("runspeed", {
    params = "<velocidad>",
    description = S("Controla tu velocidad de carrera en tierra firme.\n") ..
                  S("Uso: /runspeed <número> (Ej. /runspeed 2)"),
    func = function(name, param)
        local speed = tonumber(param)
        if speed and speed >= 0 then
            local data = persistent_map.get_player_data(name)
            if data then
                data.target_runspeed = speed
                data.fly_state = nil -- Obliga al motor a actualizar las físicas en el próximo tick
                minetest.chat_send_player(name, minetest.colorize("#00FF88", S(">> Velocidad de carrera establecida a @1", param)))
                return true
            end
        end
        return false, minetest.colorize("#ff0000", S("Valor inválido. Usa un número positivo."))
    end,
})

minetest.register_chatcommand("jumpheight", {
    params = "<altura>",
    description = S("Controla la potencia de tus saltos.\n") ..
                  S("Uso: /jumpheight <número> (Ej. /jumpheight 1.5)"),
    func = function(name, param)
        local jump = tonumber(param)
        if jump and jump >= 0 then
            local data = persistent_map.get_player_data(name)
            if data then
                data.target_jump = jump
                data.fly_state = nil -- Obliga al motor a actualizar las físicas en el próximo tick
                minetest.chat_send_player(name, minetest.colorize("#00FF88", S(">> Altura de salto establecida a @1", param)))
                return true
            end
        end
        return false, minetest.colorize("#ff0000", S("Valor inválido. Usa un número positivo."))
    end,
})

-- =========================================================
-- COMANDO: INVOCAR VARITA DE EXCAVACIÓN
-- =========================================================
minetest.register_chatcommand("varita", {
    params = "",
    description = S("Añade la Varita de Excavación (Tuxmatic) a tu inventario.\nRequiere privilegio 'give'."),
    privs = { give = true }, -- Restringido a administradores para evitar abusos
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false end
        
        local inv = player:get_inventory()
        -- Verificamos que el servidor no intente forzar un ítem en un inventario lleno
        if inv:room_for_item("main", "advanced_discovery_maps:tuxmatic_wand") then
            inv:add_item("main", "advanced_discovery_maps:tuxmatic_wand")
            return true, minetest.colorize("#FF3030", S(">> Arsenal desplegado: Varita de Excavación recibida."))
        else
            return false, minetest.colorize("#ff0000", S("Error: Tu inventario está lleno."))
        end
    end,
})

-- =========================================================
-- COMANDO: MANUAL TÁCTICO (ÍNDICE CENTRALIZADO)
-- =========================================================
minetest.register_chatcommand("map_ayuda", {
    params = "",
    description = S("Muestra el directorio de todos los comandos y habilidades tácticas del mod."),
    func = function(name)
        local msg = "\n" .. 
            minetest.colorize("#00FF88", S("=== MANUAL TÁCTICO (ADVANCED DISCOVERY MAPS) ===")) .. "\n" ..
            minetest.colorize("#00D8FF", "/map") .. " - " .. S("Abre la interfaz del mapa topográfico.") .. "\n" ..
            minetest.colorize("#00D8FF", "/nv") .. " - " .. S("Activa/desactiva la visión nocturna (Coste Cero).") .. "\n" ..
            minetest.colorize("#00D8FF", "/flyspeed <num>") .. " - " .. S("Calibra la velocidad de vuelo en el aire.") .. "\n" ..
            minetest.colorize("#00D8FF", "/runspeed <num>") .. " - " .. S("Calibra la velocidad de carrera en tierra.") .. "\n" ..
            minetest.colorize("#00D8FF", "/jumpheight <num>") .. " - " .. S("Calibra la potencia y altura de salto.") .. "\n" ..
            minetest.colorize("#00D8FF", "/actualizar_mapa <radio>") .. " - " .. S("Fuerza un escaneo geológico manual.") .. "\n" ..
            minetest.colorize("#00D8FF", "/mapparty") .. " - " .. S("Gestiona tus grupos para compartir exploración.") .. "\n" ..
            minetest.colorize("#00D8FF", "/markers") .. " - " .. S("Abre el menú de gestión de rastreadores.") .. "\n\n" ..
            minetest.colorize("#FF3030", S("=== ARSENAL CLASIFICADO ===")) .. "\n" ..
            minetest.colorize("#FF3030", "/varita") .. " - " .. S("Invoca la Varita de Excavación (Requiere permisos).") .. "\n\n" ..
            minetest.colorize("#FFFF00", S("Nota: Para activar todos los privilegios en Luanti usa el comando /grant <tu_usuario> all o /grantme all"))
            
        return true, msg
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "persistent_map:profile" then
        local name = player:get_player_name()
        if fields.close_profile then
            minetest.close_formspec(name, "persistent_map:profile")
        elseif fields.back_to_map then
            persistent_map.show_map(name)
        elseif fields.prof_zoom_in or fields.prof_zoom_out then
            local data = persistent_map.get_player_data(name)
            if data and data.profile_view then
                if fields.prof_zoom_in then
                    data.profile_view.zoom = math.min(data.profile_view.zoom + 0.5, 4.0) -- Límite 400%
                else
                    data.profile_view.zoom = math.max(data.profile_view.zoom - 0.5, 1.0) -- Límite 100%
                end
                persistent_map.show_profile_gui(name)
            end
        end
        return
    end

    if formname ~= "persistent_map:map" then return end
	
	local name = player:get_player_name()
	local offset = map_view_offset[name] or {x = 0, z = 0}
	local updated = false
	
	if fields.unidad_selector and persistent_map.player_units[name] ~= fields.unidad_selector then
		persistent_map.player_units[name] = fields.unidad_selector
		updated = true
	end
    
    if fields.target_selector then
        local p_data = player_data[name]
        if p_data and p_data.target_dropdown_opts then
            for i, opt in ipairs(p_data.target_dropdown_opts) do
                if opt == fields.target_selector then
                    local new_target = p_data.target_dropdown_map[i]
                    if persistent_map.active_target[name] ~= new_target then
                        persistent_map.active_target[name] = new_target
                        updated = true
                    end
                    break
                end
            end
        end
    end
	
    if fields.perfil_x or fields.perfil_z then
        local tiempo_actual = os.time()
        
        -- Verificación del Escudo Termodinámico
        if cooldowns_perfil[name] and tiempo_actual < cooldowns_perfil[name] then
            local restante = cooldowns_perfil[name] - tiempo_actual
            minetest.chat_send_player(name, S("El escáner geológico se está recargando para proteger la memoria. Espera @1 segundos.", restante))
            return
        end
        
        -- Aplicar el enfriamiento de 8 segundos
        cooldowns_perfil[name] = tiempo_actual + TIEMPO_ENFRIAMIENTO_PERFIL
        
        local axis = fields.perfil_x and "x" or "z"
        local pos = player:get_pos()
        local fixed_coord = (axis == "x") and math.floor(pos.z) or math.floor(pos.x)
        minetest.chat_send_player(name, S("Iniciando escaneo topográfico transversal..."))
        minetest.after(0.1, function()
            persistent_map.generate_profile(name, axis, fixed_coord)
        end)
        return
    end

	if fields.nav_north then
		offset.z = offset.z + 1
		updated = true
	elseif fields.nav_south then
		offset.z = offset.z - 1
		updated = true
	elseif fields.nav_west then
		offset.x = offset.x - 1
		updated = true
	elseif fields.nav_east then
		offset.x = offset.x + 1
		updated = true
	elseif fields.nav_center then
		offset.x = 0
		offset.z = 0
		updated = true
	elseif fields.zoom_in then
		local current_zoom = map_zoom_level[name] or persistent_map.default_zoom_index
		if current_zoom < persistent_map.max_zoom_index then
			map_zoom_level[name] = current_zoom + 1
			updated = true
		end
	elseif fields.zoom_out then
		local current_zoom = map_zoom_level[name] or persistent_map.default_zoom_index
		if current_zoom > persistent_map.min_zoom_index then
			map_zoom_level[name] = current_zoom - 1
			updated = true
		end
	elseif fields.toggle_grid then
		persistent_map.player_show_grid[name] = not (persistent_map.player_show_grid[name] or false)
		updated = true
	elseif fields.toggle_map_mode then
		local current_mode = persistent_map.player_map_mode[name] or "standard"
        if current_mode == "standard" then
            persistent_map.player_map_mode[name] = "relief"
        elseif current_mode == "relief" then
            persistent_map.player_map_mode[name] = "cave"
        else
            persistent_map.player_map_mode[name] = "standard"
        end
		updated = true
	elseif fields.manage_markers then
		persistent_map.show_marker_gui(name)
		return
	else
		for i = 1, #persistent_map.marker_colors do
			if fields["add_marker_" .. i] then
				local pos = player:get_pos()
				local marker_name = fields.marker_name or ""
				if marker_name == "" then
					marker_name = string.format("Marker %d,%d", math.floor(pos.x), math.floor(pos.z))
				end
				local success, message = add_marker(name, pos, i, marker_name)
				minetest.chat_send_player(name, message)
				updated = true
				break
			end
		end
	end
	
	if not updated then
		for field, _ in pairs(fields) do
			local click_x, click_z = string.match(field, "^map_click_(%-?%d+)_(%-?%d+)$")
			if click_x and click_z then
				local target_x = tonumber(click_x)
				local target_z = tonumber(click_z)
				
				local player_obj = minetest.get_player_by_name(name)
				if player_obj then
					local p_pos = player_obj:get_pos()
					local center_tile_x = math.floor(p_pos.x / persistent_map.tile_size)
					local center_tile_z = math.floor(p_pos.z / persistent_map.tile_size)
					
					local zoom_index = map_zoom_level[name] or persistent_map.default_zoom_index
					local zoom_offset = persistent_map.zoom_offsets[zoom_index] or {x = 0, z = 0}
					
					offset.x = target_x - center_tile_x - zoom_offset.x
					offset.z = target_z - center_tile_z - zoom_offset.z
					updated = true
				end
				break
			end
		end
	end
	
	if updated then
		map_view_offset[name] = offset
		persistent_map.show_map(name)
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	local tiles = load_player_tiles(name)
	local markers = load_player_markers(name)
	
	player_data[name] = {
		discovered_tiles = tiles,
		markers = markers,
		last_tile_x = nil,
		last_tile_z = nil,
        -- Variables inyectadas para control físico:
        target_flyspeed = 1,
        target_runspeed = 1,
        target_jump = 1,
        fly_state = "ground",
	}
	
	local tile_count = 0
	for _ in pairs(tiles) do tile_count = tile_count + 1 end
	local marker_count = 0
	for _ in pairs(markers) do marker_count = marker_count + 1 end
	
	minetest.log("action", "[persistent_map] Player " .. name .. " joined with " .. tile_count .. " discovered tiles and " .. marker_count .. " markers")
	
	for tile_id, _ in pairs(tiles) do
		local version = persistent_map.tile_versions and persistent_map.tile_versions[tile_id] or 0
		local file_id = version > 0 and (tile_id .. "_v" .. version) or tile_id
		
		local filename_std = map_path .. file_id .. ".png"
		local filename_rel = map_path .. file_id .. "_relief.png"
		
		local file = io.open(filename_std, "r")
		if file then
			file:close()
			
			minetest.dynamic_add_media({
				filepath = filename_std,
				to_player = name,
			}, function(player_name)
				minetest.log("action", "[persistent_map] Reloaded standard tile " .. tile_id .. " for " .. player_name)
			end)
			
			local file_rel = io.open(filename_rel, "r")
			if file_rel then
			    file_rel:close()
			    minetest.dynamic_add_media({
			        filepath = filename_rel,
			        to_player = name,
			    }, function(player_name)
			        minetest.log("action", "[persistent_map] Reloaded relief tile " .. tile_id .. " for " .. player_name)
			    end)
			end
			
			local file_cave = io.open(map_path .. file_id .. "_cave.png", "r")
			if file_cave then
			    file_cave:close()
			    minetest.dynamic_add_media({
				filepath = map_path .. file_id .. "_cave.png",
				to_player = name,
			    }, function(player_name)
				minetest.log("action", "[persistent_map] Reloaded cave tile " .. tile_id .. " for " .. player_name)
			    end)
			end
			
		else
			minetest.log("warning", "[persistent_map] Tile file not found: " .. tile_id .. " for player " .. name)
		end
	end
	
	minetest.after(persistent_map.generation.initial_discovery_delay, function()
		local pos = player:get_pos()
		if pos then
			local tile_x, tile_z = pos_to_tile_coords(pos)
			local data = player_data[name]
			if data then
				local discovered = add_discovered_tile(name, tile_x, tile_z, function()
					minetest.chat_send_player(name, S("New area discovered!"))
				end)
				if discovered then
					data.last_tile_x = tile_x
					data.last_tile_z = tile_z
				end
			end
		end
	end)
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    player_data[name] = nil
    map_view_offset[name] = nil
    map_zoom_level[name] = nil
    
    -- Purga de Escudos para mantener el "Estado Cero" en memoria
    cooldowns_mapa[name] = nil
    cooldowns_perfil[name] = nil
    
    minetest.log("action", "[persistent_map] Player " .. name .. " left, data and cooldowns cleaned up")
end)

local scan_timer = 0
minetest.register_globalstep(function(dtime)
    scan_timer = scan_timer + dtime
    if scan_timer < persistent_map.scan_interval then return end
    scan_timer = 0
    
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local data = player_data[name]
        
        if not data then goto continue end
        
        local pos = player:get_pos()
        local tile_x, tile_z = pos_to_tile_coords(pos)
        
        -- 1. Lógica original de descubrimiento de mapas
        if data.last_tile_x ~= tile_x or data.last_tile_z ~= tile_z then
            local discovered = add_discovered_tile(name, tile_x, tile_z, function()
                minetest.chat_send_player(name, S("New area discovered!"))
            end)
            if discovered then
                data.last_tile_x = tile_x
                data.last_tile_z = tile_z
            end
        end

        -- 2. Lógica del Faro de Visión Nocturna Submarina y Subterránea
        if data.nv_active then
            local head_pos = vector.round(pos)
            head_pos.y = head_pos.y + 1 -- Posicionamos la luz exactamente en la cámara
            
            -- Solo actualizamos si el jugador cruzó a un nuevo bloque
            if not data.nv_pos or not vector.equals(data.nv_pos, head_pos) then
                
                -- A) Restaurar el bloque anterior silenciosamente
                if data.nv_pos and data.nv_saved_node then
                    local current_old = minetest.get_node(data.nv_pos)
                    if current_old.name == "advanced_discovery_maps:nv_beacon" or current_old.name == "advanced_discovery_maps:nv_beacon_liquid" then
                        minetest.swap_node(data.nv_pos, data.nv_saved_node)
                    end
                end
                
                -- B) Analizar y guardar el nuevo bloque
                local current_node = minetest.get_node(head_pos)
                local def = minetest.registered_nodes[current_node.name]
                
                -- Solo inyectamos luz si NO es roca sólida (evitamos asfixia)
                if def and not def.walkable then
                    data.nv_saved_node = current_node
                    data.nv_pos = head_pos
                    
                    -- Seleccionar el faro correcto (líquido o aire)
                    local is_liquid = def.liquidtype == "source" or def.liquidtype == "flowing"
                    local beacon_name = is_liquid and "advanced_discovery_maps:nv_beacon_liquid" or "advanced_discovery_maps:nv_beacon"
                    
                    -- swap_node cambia la RAM sin despertar gravedad o fluidos
                    minetest.swap_node(head_pos, {name = beacon_name, param2 = current_node.param2})
                else
                    data.nv_pos = nil
                    data.nv_saved_node = nil
                end
            end
        end

        -- 3. Lógica de Velocidad de Vuelo (Coste de RAM Cero)
        local target_speed = data.target_flyspeed
        -- Evaluamos solo si el jugador alteró su velocidad o reinició el comando
        if target_speed and target_speed ~= 1 or data.fly_state == nil then
            
            -- Reutilizamos el vector 'pos' modificando solo el eje Y matemáticamente
            local original_y = pos.y
            pos.y = math.floor(original_y)
            local node_at = minetest.get_node(pos).name
            
            pos.y = pos.y - 1
            local node_below = minetest.get_node(pos).name
            pos.y = original_y -- Restauramos el vector a su estado original
            
            local is_flying = (node_below == "air" and node_at == "air")
            
            -- Solo inyectamos físicas si el estado ha CAMBIADO
            if is_flying and data.fly_state ~= "flying" then
                player:set_physics_override({ speed = target_speed })
                data.fly_state = "flying"
            elseif not is_flying and data.fly_state ~= "ground" then
                player:set_physics_override({ speed = 1 })
                data.fly_state = "ground"
            end
        end
        
        ::continue::
    end
end)

minetest.register_craftitem("advanced_discovery_maps:map_book", {
	description = S("Map Book") .. "\n" .. S("Right-click to open the persistent map"),
	inventory_image = "default_book.png^[colorize:#8B4513:120",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		if user and user:is_player() then
			local player_name = user:get_player_name()
			map_view_offset[player_name] = {x = 0, z = 0}
			if not map_zoom_level[player_name] then
				map_zoom_level[player_name] = persistent_map.default_zoom_index
			end
			persistent_map.show_map(player_name)
		end
		return itemstack
	end,
})

minetest.register_alias("discovery_maps_optimizado:map_book", "advanced_discovery_maps:map_book")

minetest.register_craft({
	output = "advanced_discovery_maps:map_book",
	recipe = {
		{"default:paper", "default:paper", "default:paper"},
		{"default:paper", "default:book", "default:paper"},
		{"default:paper", "default:paper", "default:paper"}
	}
})

minetest.register_craft({
	output = "advanced_discovery_maps:map_book",
	recipe = {
		{"mcl_core:paper", "mcl_core:paper", "mcl_core:paper"},
		{"mcl_core:paper", "mcl_books:writable_book", "mcl_core:paper"},
		{"mcl_core:paper", "mcl_core:paper", "mcl_core:paper"}
	}
})

minetest.register_on_newplayer(function(player)
	local inv = player:get_inventory()
	if inv:room_for_item("main", "advanced_discovery_maps:map_book") then
		inv:add_item("main", "advanced_discovery_maps:map_book")
		minetest.chat_send_player(player:get_player_name(),
			S("Welcome! You've been given a Map Book. left-click it to explore the world!"))
	end
end)

dofile(modpath .. "/marker-gui.lua")
dofile(modpath .. "/marker-share.lua")
dofile(modpath .. "/map-party.lua")
dofile(modpath .. "/map-party-gui.lua")

-- =========================================================
-- SISTEMA DE VERSIONADO Y ACTUALIZACIÓN (CACHE BUSTING)
-- =========================================================
persistent_map.tile_versions = {}
local versions_data = persistent_map.storage:get_string("tile_versions")
if versions_data ~= "" then
    persistent_map.tile_versions = minetest.deserialize(versions_data) or {}
end

function persistent_map.save_versions()
    persistent_map.storage:set_string("tile_versions", minetest.serialize(persistent_map.tile_versions))
end

-- =========================================================
-- SISTEMA DE ACTUALIZACIÓN POR ÁREA (COLA ASÍNCRONA BLINDADA)
-- =========================================================
minetest.register_chatcommand("actualizar_mapa", {
    params = "[radio]",
    description = S("Fuerza la actualización topográfica del mapa en tu posición actual.\n") ..
                  S("Uso: /actualizar_mapa [radio]\n") ..
                  S("Ejemplo: '/actualizar_mapa 1' actualiza 3x3 cuadrantes.\n") ..
                  S("Nota: Operación de alto coste de memoria. El radio máximo permitido es 3."),
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false end

        -- Verificación del Escudo Termodinámico
        local tiempo_actual = os.time()
        if cooldowns_mapa[name] and tiempo_actual < cooldowns_mapa[name] then
            local restante = cooldowns_mapa[name] - tiempo_actual
            return false, S("El motor topográfico asíncrono se está enfriando. Espera @1 segundos.", restante)
        end

        local radio = tonumber(param) or 0
        if radio > 3 then
            return false, S("Radio denegado. El máximo permitido es 3 (49 cuadrantes) para evitar el colapso del disco.")
        end
        
        -- Cálculo matemático del cooldown: Tiempo base + penalización por área solicitada
        cooldowns_mapa[name] = tiempo_actual + TIEMPO_ENFRIAMIENTO_MAPA + (radio * 5)

        local pos = player:get_pos()
        local center_tile_x = math.floor(pos.x / persistent_map.tile_size)
        local center_tile_z = math.floor(pos.z / persistent_map.tile_size)

        local player_data_entry = persistent_map.get_player_data(name)
        if not player_data_entry then return false end
        local discovered = player_data_entry.discovered_tiles

        local cola_cuadrantes = {}
        for dx = -radio, radio do
            for dz = -radio, radio do
                local t_x = center_tile_x + dx
                local t_z = center_tile_z + dz
                local base_id = string.format("tile_%d_%d", t_x, t_z)

                if discovered[base_id] then
                    table.insert(cola_cuadrantes, {x = t_x, z = t_z, id = base_id})
                end
            end
        end

        if #cola_cuadrantes == 0 then
            -- Revertimos el enfriamiento si no hubo trabajo de cálculo real
            cooldowns_mapa[name] = 0
            return true, S("No hay cuadrantes descubiertos en este radio para actualizar.")
        end

        minetest.chat_send_player(name, S("Iniciando escaneo topográfico de @1 cuadrante(s). Puedes seguir jugando, te notificaré al terminar...", #cola_cuadrantes))

        local indice_actual = 1
        local function procesar_siguiente()
            if indice_actual > #cola_cuadrantes then
                minetest.chat_send_player(name, S("¡Topografía actualizada con éxito! Cierra y reabre el mapa para ver los cambios."))
                return
            end

            local cuadrante = cola_cuadrantes[indice_actual]
            persistent_map.tile_versions[cuadrante.id] = (persistent_map.tile_versions[cuadrante.id] or 0) + 1
            persistent_map.save_versions()

            generate_tile(cuadrante.x, cuadrante.z, function()
                indice_actual = indice_actual + 1
                minetest.after(0.2, procesar_siguiente)
            end)
        end

        procesar_siguiente()
        return true
    end,
})

-- =========================================================
-- SISTEMA DE ACTUALIZACIÓN PEREZOSA (LAZY TRACKER)
-- =========================================================
local dirty_tiles = {}
local TIEMPO_DE_ESPERA = 15

local function marcar_cuadrante_sucio(pos)
    local tile_x = math.floor(pos.x / persistent_map.tile_size)
    local tile_z = math.floor(pos.z / persistent_map.tile_size)
    local tile_id = string.format("tile_%d_%d", tile_x, tile_z)
    
    dirty_tiles[tile_id] = {
        tiempo = os.time() + TIEMPO_DE_ESPERA,
        x = tile_x,
        z = tile_z
    }
end

minetest.register_on_placenode(function(pos) marcar_cuadrante_sucio(pos) end)
minetest.register_on_dignode(function(pos) marcar_cuadrante_sucio(pos) end)



-- =========================================================
-- SISTEMA DE ACTUALIZACIÓN PEREZOSA (LAZY TRACKER) Y MOTOR DE VUELO
-- =========================================================
local dirty_tiles = {}
local TIEMPO_DE_ESPERA = 15

local function marcar_cuadrante_sucio(pos)
    local tile_x = math.floor(pos.x / persistent_map.tile_size)
    local tile_z = math.floor(pos.z / persistent_map.tile_size)
    local tile_id = string.format("tile_%d_%d", tile_x, tile_z)
    
    dirty_tiles[tile_id] = {
        tiempo = os.time() + TIEMPO_DE_ESPERA,
        x = tile_x,
        z = tile_z
    }
end

minetest.register_on_placenode(function(pos) marcar_cuadrante_sucio(pos) end)
minetest.register_on_dignode(function(pos) marcar_cuadrante_sucio(pos) end)

local motor_timer = 0
minetest.register_globalstep(function(dtime)
    motor_timer = motor_timer + dtime
    if motor_timer < 0.25 then return end -- Ejecuta ambos sistemas 4 veces por segundo
    motor_timer = 0
    
    -- 1. Vigía de Azulejos Sucios (Mapas)
    local tiempo_actual = os.time()
    for base_id, datos in pairs(dirty_tiles) do
        if tiempo_actual >= datos.tiempo then
            persistent_map.tile_versions[base_id] = (persistent_map.tile_versions[base_id] or 0) + 1
            persistent_map.save_versions()
            generate_tile(datos.x, datos.z)
            dirty_tiles[base_id] = nil
        end
    end
    
    -- 2. Motor de Seguimiento Físico (Vuelo, Carrera y Salto integrados)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local data = persistent_map.get_player_data(name)
        
        if data then
            local t_fly = data.target_flyspeed
            local t_run = data.target_runspeed or 1
            local t_jump = data.target_jump or 1
            
            -- Evaluamos si se han alterado las físicas o si se reinició un comando
            if t_fly and (t_fly ~= 1 or t_run ~= 1 or t_jump ~= 1 or data.fly_state == nil) then
                local pos = player:get_pos()
                local original_y = pos.y
                
                pos.y = math.floor(original_y)
                local node_at = minetest.get_node(pos).name
                
                pos.y = pos.y - 1
                local node_below = minetest.get_node(pos).name
                pos.y = original_y
                
                local is_flying = (node_below == "air" and node_at == "air")
                
                if is_flying and data.fly_state ~= "flying" then
                    -- Inyectamos velocidad de vuelo y salto simultáneamente
                    player:set_physics_override({ speed = t_fly, jump = t_jump })
                    data.fly_state = "flying"
                elseif not is_flying and data.fly_state ~= "ground" then
                    -- Al tocar el suelo, pasamos de t_fly a t_run
                    player:set_physics_override({ speed = t_run, jump = t_jump })
                    data.fly_state = "ground"
                end
            end
        end
    end

end)

-- =========================================================
-- ALGORITMO TUXMATIC: EXCAVACIÓN ASÍNCRONA ESTRATIFICADA
-- =========================================================
local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")

-- Motor 1: Excavación Recursiva por Capas (Para radios > 20)
local function tuxmatic_async_layer(pos, radius, current_y, player_name)
    -- Condición de salida: Hemos rebanado toda la esfera hasta la base
    if current_y < -radius then
        minetest.chat_send_player(player_name, minetest.colorize("#00FF88", S(">> Excavación Asíncrona completada.")))
        return
    end

    local r_sq = radius * radius
    local y_sq = current_y * current_y
    local layer_r = math.ceil(math.sqrt(r_sq - y_sq))

    -- Definimos estrictamente el área de esta única rebanada (1 bloque de altura)
    local minp = vector.new(pos.x - layer_r, pos.y + current_y, pos.z - layer_r)
    local maxp = vector.new(pos.x + layer_r, pos.y + current_y, pos.z + layer_r)

    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local data = vm:get_data()
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

    local modificado = false
    for z = -layer_r, layer_r do
        for x = -layer_r, layer_r do
            if x*x + y_sq + z*z <= r_sq then
                local vi = area:index(pos.x + x, pos.y + current_y, pos.z + z)
                if data[vi] ~= c_ignore and data[vi] ~= c_air then
                    data[vi] = c_air 
                    modificado = true
                end
            end
        end
    end

    if modificado then
        vm:set_data(data)
        vm:write_to_map()
        vm:update_map()
        vm:update_liquids()
    end

    -- Efecto visual por capa procesada (Sensación de rayo orbital)
    if current_y % 3 == 0 then
        minetest.add_particlespawner({
            amount = 15, time = 0.2,
            minpos = minp, maxpos = maxp,
            minvel = {x=-2, y=2, z=-2}, maxvel = {x=2, y=8, z=2},
            minexptime = 1, maxexptime = 2,
            minsize = 15, maxsize = 30,
            texture = "tnt_smoke.png",
        })
    end

    -- El motor cede el control al procesador durante 0.15s antes de la siguiente capa
    minetest.after(0.15, function()
        tuxmatic_async_layer(pos, radius, current_y - 1, player_name)
    end)
end

-- Motor 2: Excavación Sincrónica Instantánea (Para radios <= 20)
local function tuxmatic_sync_boom(pos, radius)
    local r = radius
    local minp = vector.new(pos.x - r, pos.y - r, pos.z - r)
    local maxp = vector.new(pos.x + r, pos.y + r, pos.z + r)

    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local data = vm:get_data()
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

    for z = -r, r do
        for y = -r, r do
            for x = -r, r do
                if x*x + y*y + z*z <= r*r then
                    local vi = area:index(pos.x + x, pos.y + y, pos.z + z)
                    if data[vi] ~= c_ignore then
                        data[vi] = c_air 
                    end
                end
            end
        end
    end

    vm:set_data(data)
    vm:write_to_map()
    vm:update_map()
    vm:update_liquids()

    minetest.add_particlespawner({
        amount = r * 5, time = 0.5,
        minpos = minp, maxpos = maxp,
        minvel = {x=-5, y=0, z=-5}, maxvel = {x=5, y=5, z=5},
        minexptime = 1, maxexptime = 2,
        minsize = 10, maxsize = 25,
        texture = "tnt_smoke.png",
    })
end

-- Enrutador de Destrucción
local function tuxmatic_boom(pos, radius, player_name)
    local tiempo_actual = os.time()
    
    if cooldowns_perfil[player_name] and tiempo_actual < cooldowns_perfil[player_name] then
        local restante = cooldowns_perfil[player_name] - tiempo_actual
        minetest.chat_send_player(player_name, minetest.colorize("#ff0000", S("La varita se está enfriando. Espera @1 segundos.", restante)))
        return
    end

    -- Tiempo de enfriamiento dinámico: Escala según la ambición del radio
    local cooldown = radius <= 20 and 3 or math.ceil(radius * 0.4)
    cooldowns_perfil[player_name] = tiempo_actual + cooldown

    local r = math.min(math.max(radius, 1), 100) 

    minetest.sound_play("tnt_explode", {pos = pos, gain = 2.0, max_hear_distance = 128}, true)

    if r <= 20 then
        tuxmatic_sync_boom(pos, r)
    else
        minetest.chat_send_player(player_name, minetest.colorize("#00D8FF", S(">> Iniciando Excavación Asíncrona (Radio @1). Descendiendo...", r)))
        tuxmatic_async_layer(pos, r, r, player_name) -- Comienza a destruir desde el techo de la esfera
    end
end

-- =========================================================
-- HERRAMIENTA: VARITA DE EXCAVACIÓN TÁCTICA CON INTERFAZ
-- =========================================================
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "advanced_discovery_maps:wand_gui" then return end
    
    local item = player:get_wielded_item()
    if item:get_name() ~= "advanced_discovery_maps:tuxmatic_wand" then return end
    
    if fields.radius then
        local new_radius = tonumber(fields.radius)
        if new_radius then
            new_radius = math.min(math.max(new_radius, 1), 100)
            local meta = item:get_meta()
            meta:set_int("radius", new_radius)
            player:set_wielded_item(item)
            minetest.chat_send_player(player:get_player_name(), minetest.colorize("#00FF88", S(">> Radio de excavación ajustado a @1 bloques.", new_radius)))
        end
    end
end)

local function open_wand_gui(itemstack, user, pointed_thing)
    local meta = itemstack:get_meta()
    local current_radius = meta:get_int("radius")
    if current_radius == 0 then current_radius = 5 end
    
    local formspec = "size[4.5,3.5]" ..
                     "bgcolor[#000000CC;true]" ..
                     "label[0.5,0.5;" .. S("Calibrar Varita Tuxmatic") .. "]" ..
                     "field[1,1.8;3,1;radius;" .. S("Radio de Destrucción (1-100)") .. ";" .. current_radius .. "]" ..
                     "button[1.2,2.6;2,1;save;" .. S("Guardar") .. "]"
                     
    minetest.show_formspec(user:get_player_name(), "advanced_discovery_maps:wand_gui", formspec)
    return itemstack
end

minetest.register_tool("advanced_discovery_maps:tuxmatic_wand", {
    description = S("Varita de Excavación (Tuxmatic)\nClic Izq: Destruye geología (Hasta R=100).\nClic Der: Configura el radio."),
    inventory_image = "default_stick.png^[colorize:#FF3030:120",
    range = 25,
    groups = {not_in_creative_inventory = 0},
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "node" then
            local meta = itemstack:get_meta()
            local radius = meta:get_int("radius")
            if radius == 0 then radius = 5 end
            
            tuxmatic_boom(pointed_thing.under, radius, user:get_player_name()) 
        end
    end,
    on_place = open_wand_gui,
    on_secondary_use = open_wand_gui,
})
