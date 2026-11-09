-- ADM-FASE3-GENERATED: algoritmo conservado, lectura por franjas.
-- Generado desde el init.lua local; no copiar a mano el motor original.
return function(persistent_map, get_tile_id, tile_exists, get_node_color, map_path)
    local queue = {}
    local pending = {}
    local queue_busy = false
    local function start_next_job()
        if queue_busy or #queue == 0 then return end
        local job = table.remove(queue, 1)
        queue_busy = true
        job()
    end
local function generate_tile(tile_x, tile_z, callback)
    local base_id = get_tile_id(tile_x, tile_z)
    local version = persistent_map.tile_versions and persistent_map.tile_versions[base_id] or 0
    local tile_id = version > 0 and (base_id .. "_v" .. version) or base_id

    if pending[tile_id] then
        if callback then
            pending[tile_id][#pending[tile_id] + 1] = callback
        end
        return base_id
    end

    if tile_exists(tile_id) then
        if callback then callback(base_id) end
        return base_id
    end

    -- ADM-FASE2-SCAN-BOUNDS: modo configurable, sin alterar el modo original.
    -- full: rango completo original; balanced/light: superficies y cuevas cercanas.
    -- La lectura acotada es aproximada fuera del intervalo elegido.
    local scan_mode = minetest.settings:get("adm_scan_mode") or "full"
    local scan_bottom = persistent_map.min_height
    local scan_top = persistent_map.max_height
    if scan_mode == "balanced" then
        scan_bottom = math.max(scan_bottom, -192)
        scan_top = math.min(scan_top, 320)
    elseif scan_mode == "light" then
        scan_bottom = math.max(scan_bottom, -128)
        scan_top = math.min(scan_top, 192)
    else
        scan_mode = "full"
    end

    local minp = vector.new(tile_x * persistent_map.tile_size, scan_bottom, tile_z * persistent_map.tile_size)
    local maxp = vector.new((tile_x + 1) * persistent_map.tile_size - 1, scan_top, (tile_z + 1) * persistent_map.tile_size - 1)

    pending[tile_id] = callback and {callback} or {}
    local function execute_job()
    minetest.after(0.05, function()
        local adm_profile = minetest.settings:get_bool("adm_profile_tiles", false)
        local adm_t0 = adm_profile and minetest.get_us_time()
        local adm_read_us, adm_pixel_us, adm_peak_us, adm_stripes = 0, 0, 0, 0
        local adm_data_buffer = {}
        local stripe_rows = tonumber(minetest.settings:get("adm_stripe_rows")) or 16
        -- Las franjas son multiplos de mapblock (16) para evitar lecturas duplicadas.
        stripe_rows = stripe_rows >= 32 and 32 or 16

        local c_air = minetest.get_content_id("air")
        local c_ignore = minetest.get_content_id("ignore")

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

        -- El bucle de filas original se conserva: solo cambia la adquisicion de datos.
        local row_start = 0
        local function process_next_stripe()
            local stripe_t0 = minetest.get_us_time()
            local row_last = math.min(tile_size - 1, row_start + stripe_rows - 1)
            local z_top, z_bottom = max_z - row_start, max_z - row_last
            local vm = minetest.get_voxel_manip()
            local emin, emax = vm:read_from_map(
                {x = min_x, y = min_y, z = z_bottom},
                {x = min_x + tile_size - 1, y = max_y, z = z_top})
            vm:get_data(adm_data_buffer)
            if vm.close then vm:close() end
            local data = adm_data_buffer
            local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
            local y_stride = area.ystride
            local stripe_tread = minetest.get_us_time()
            adm_read_us = adm_read_us + stripe_tread - stripe_t0
            for img_y = row_start, row_last do
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
            local stripe_tdone = minetest.get_us_time()
            adm_stripes = adm_stripes + 1
            adm_pixel_us = adm_pixel_us + stripe_tdone - stripe_tread
            adm_peak_us = math.max(adm_peak_us, stripe_tdone - stripe_t0)
            row_start = row_last + 1
            if row_start < tile_size then
                minetest.after(0.025, process_next_stripe)
                return
            end
            -- Finalizacion: solo cuando todas las filas estan completas.
        local adm_t_pixels = adm_profile and minetest.get_us_time()

        local filename_std = persistent_map.map_path .. tile_id .. ".png"
        local filename_rel = persistent_map.map_path .. tile_id .. "_relief.png"
        local filename_cave = persistent_map.map_path .. tile_id .. "_cave.png"

        local png_std = minetest.encode_png(persistent_map.tile_size, persistent_map.tile_size, table.concat(pixels_std))
        local png_rel = minetest.encode_png(persistent_map.tile_size, persistent_map.tile_size, table.concat(pixels_rel))
        local png_cave = minetest.encode_png(persistent_map.tile_size, persistent_map.tile_size, table.concat(pixels_cave))

        minetest.safe_file_write(filename_std, png_std)
        minetest.safe_file_write(filename_rel, png_rel)
        minetest.safe_file_write(filename_cave, png_cave)

        if adm_profile then
            local done_us = minetest.get_us_time()
            minetest.log("action", string.format(
                "[ADM-PERF3] %s modo=%s franjas=%d lectura=%.1fms " ..
                "pixeles=%.1fms png+disco=%.1fms pico_franja=%.1fms pared=%.1fms",
                tile_id, scan_mode, adm_stripes, adm_read_us / 1000,
                adm_pixel_us / 1000, (done_us - adm_t_pixels) / 1000,
                adm_peak_us / 1000, (done_us - adm_t0) / 1000))
        end
        -- Liberar el turno de trabajo al terminar los PNG. Los envios son asincronos.
        queue_busy = false
        minetest.after(0.025, start_next_job)

        minetest.dynamic_add_media({filepath = filename_std}, function()
            minetest.dynamic_add_media({filepath = filename_rel}, function()
                minetest.dynamic_add_media({filepath = filename_cave}, function()
                    local listeners = pending[tile_id] or {}
                    pending[tile_id] = nil
                    for _, listener in ipairs(listeners) do
                        local ok, err = pcall(listener, base_id)
                        if not ok then minetest.log("error", "[ADM] Callback: " .. tostring(err)) end
                    end
                end)
            end)
        end)
        end -- process_next_stripe
        process_next_stripe()
    end) -- minetest.after
    end -- execute_job
    queue[#queue + 1] = execute_job
    start_next_job()
    return base_id
end
return generate_tile
end
