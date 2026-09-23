-- Map Party System for Persistent Map Mod
-- Allows multiple players to create map parties and automatically share discovered tiles
-- All players in a party collectively discover and update each other's tiles

local S = minetest.get_translator(minetest.get_current_modname())

-- Map party storage
local map_parties = {}
local player_parties = {} -- Maps player_name -> party_name

-- Load map parties from storage
local function load_map_parties()
    local storage = persistent_map.storage
    if not storage then
        return
    end
    
    local data = storage:get_string("map_parties")
    if data ~= "" then
        map_parties = minetest.deserialize(data) or {}
    end
    
    -- Rebuild player_parties lookup tablemap-party.lua
    player_parties = {}
    for party_name, party_data in pairs(map_parties) do
        for _, player_name in ipairs(party_data.members) do
            player_parties[player_name] = party_name
        end
    end
end

-- Save map parties to storage
local function save_map_parties()
    local storage = persistent_map.storage
    if not storage then
        return false
    end
    
    storage:set_string("map_parties", minetest.serialize(map_parties))
    return true
end

-- Check if a party exists
local function party_exists(party_name)
    return map_parties[party_name] ~= nil
end

-- Check if a player is in a party
local function get_player_party(player_name)
    return player_parties[player_name]
end

-- Check if a player is the owner of a party
local function is_party_owner(player_name, party_name)
    local party = map_parties[party_name]
    return party and party.owner == player_name
end

-- Add a player to a party
local function add_player_to_party(party_name, player_name)
    local party = map_parties[party_name]
    if not party then
        return false, "Party does not exist"
    end
    
    -- Check if player is already in this party
    for _, member in ipairs(party.members) do
        if member == player_name then
            return false, "Player is already in this party"
        end
    end
    
    -- Check if player is in another party
    if player_parties[player_name] then
        return false, "Player is already in party '" .. player_parties[player_name] .. "'"
    end
    
    -- Add player to party
    table.insert(party.members, player_name)
    player_parties[player_name] = party_name
    
    save_map_parties()
    return true, "Player added to party successfully"
end

-- Remove a player from a party
local function remove_player_from_party(party_name, player_name)
    local party = map_parties[party_name]
    if not party then
        return false, "Party does not exist"
    end
    
    -- Find and remove player from members list
    for i, member in ipairs(party.members) do
        if member == player_name then
            table.remove(party.members, i)
            player_parties[player_name] = nil
            
            -- If this was the owner and there are other members, transfer ownership
            if party.owner == player_name and #party.members > 0 then
                party.owner = party.members[1]
            end
            
            -- If no members left, delete the party
            if #party.members == 0 then
                map_parties[party_name] = nil
            end
            
            save_map_parties()
            return true, "Player removed from party successfully"
        end
    end
    
    return false, "Player is not in this party"
end

-- Check if tile exists on disk
local function tile_exists(tile_id)
    local filename = persistent_map.map_path .. tile_id .. ".png"
    local file = io.open(filename, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Share a tile with all party members (Seguridad de Recursión Añadida)
local function share_tile_with_party(sender_name, tile_x, tile_z, callback)
    local party_name = get_player_party(sender_name)
    if not party_name then return false, "You are not in a party" end
    
    local party = map_parties[party_name]
    if not party then return false, "Party data not found" end
    
    local sender_data = persistent_map.get_player_data(sender_name)
    if not sender_data then return false, "Sender data not found" end
    
    local tile_id = string.format("tile_%d_%d", tile_x, tile_z)
    if not sender_data.discovered_tiles[tile_id] then return false, "Tile not discovered by sender" end
    
    -- Algoritmo de reintento con límite de seguridad (Abortar tras 20 intentos = 10 segundos)
    local function attempt_share(intentos)
        intentos = intentos or 0
        
        if not tile_exists(tile_id) then
            if intentos > 20 then
                minetest.log("warning", "[map-party] Abortando sincronización de " .. tile_id .. " por tiempo de espera agotado.")
                return -- Corta la recursión y libera el procesador
            end
            -- Si no existe aún, reintentar sumando 1 al contador
            minetest.after(0.5, function() attempt_share(intentos + 1) end)
            return
        end
        
        local storage = persistent_map.storage
        if not storage then
            if callback then callback(false, "Storage not initialized") end
            return
        end
        
        local shared_count = 0
        local map_path = persistent_map.map_path
        
        -- (El resto del código de esta función se mantiene igual, iterando sobre los miembros de la party)
        for _, member_name in ipairs(party.members) do
            if member_name ~= sender_name then
                local member_data = storage:get_string("player_" .. member_name)
                local member_tiles = {}
                if member_data ~= "" then member_tiles = minetest.deserialize(member_data) or {} end
                
                if not member_tiles[tile_id] then
                    member_tiles[tile_id] = {x = tile_x, z = tile_z}
                    storage:set_string("player_" .. member_name, minetest.serialize(member_tiles))
                    shared_count = shared_count + 1
                    
                    local member_player = minetest.get_player_by_name(member_name)
                    if member_player then
                        local member_player_data = persistent_map.get_player_data(member_name)
                        if member_player_data then
                            member_player_data.discovered_tiles[tile_id] = {x = tile_x, z = tile_z}
                        end
                        minetest.after(0.1, function()
                            local filename = map_path .. tile_id .. ".png"
                            minetest.dynamic_add_media({filepath = filename, to_player = member_name}, function(player_name)
                                minetest.chat_send_player(member_name, S("Party member @1 discovered a new area at (@2, @3)!", sender_name, tile_x, tile_z))
                            end)
                        end)
                    end
                end
            end
        end
        if callback then callback(true, shared_count) end
    end
    
    minetest.after(0.2, function() attempt_share(0) end)
    return true, 0
end

-- Hook into the tile discovery system to automatically share with party members
local original_add_discovered_tile = nil

-- Override the tile discovery function to add party sharing
local function hook_tile_discovery()
    -- We need to hook into the globalstep function that calls add_discovered_tile
    -- Since we can't directly modify the original function, we'll use a different approach
    -- by monitoring player positions and sharing tiles when they're discovered
end

-- Get tile coordinates from player position
local function pos_to_tile_coords(pos)
    return math.floor(pos.x / persistent_map.tile_size),
           math.floor(pos.z / persistent_map.tile_size)
end

-- Get positions of all online party members (excluding the requesting player)
function persistent_map.get_party_member_positions(player_name)
    local party_name = get_player_party(player_name)
    if not party_name then
        return {}
    end
    
    local party = map_parties[party_name]
    if not party then
        return {}
    end
    
    local member_positions = {}
    for _, member_name in ipairs(party.members) do
        if member_name ~= player_name then
            local member_player = minetest.get_player_by_name(member_name)
            if member_player then
                local pos = member_player:get_pos()
                local yaw = member_player:get_look_horizontal()
                member_positions[member_name] = {
                    pos = pos,
                    yaw = yaw,
                    name = member_name
                }
            end
        end
    end
    
    return member_positions
end

-- Monitor player movement and auto-share newly discovered tiles (Optimizacion de Recolector de Basura)
local party_scan_timer = 0
minetest.register_globalstep(function(dtime)
    party_scan_timer = party_scan_timer + dtime
    if party_scan_timer < persistent_map.scan_interval then return end
    party_scan_timer = 0
    
    -- Localizando funciones en el ámbito (scope) para acelerar la lectura en milisegundos
    local get_connected = minetest.get_connected_players
    local get_party = get_player_party
    local get_data = persistent_map.get_player_data
    
    for _, player in ipairs(get_connected()) do
        local name = player:get_player_name()
        local party_name = get_party(name)
        
        if party_name then
            local player_data = get_data(name)
            if player_data then
                local pos = player:get_pos()
                local tile_x, tile_z = pos_to_tile_coords(pos)
                
                -- EVITAMOS concatenar strings a menos que las coordenadas numéricas cambien
                if player_data.last_shared_x ~= tile_x or player_data.last_shared_z ~= tile_z then
                    local tile_id = "tile_" .. tile_x .. "_" .. tile_z
                    
                    if player_data.discovered_tiles[tile_id] then
                        -- Actualizamos el caché numérico inmediatamente
                        player_data.last_shared_x = tile_x
                        player_data.last_shared_z = tile_z
                        
                        share_tile_with_party(name, tile_x, tile_z, function(success, shared_count)
                            if success and shared_count > 0 then
                                player_data.last_shared_tile = tile_id
                            end
                        end)
                    end
                end
            end
        end
    end
end)
-- Chat command to create a new map party
-- Chat command to create a new map party
minetest.register_chatcommand("mapparty", {
    params = "<acción> [argumentos]",
    description = S("Sistema Telemétrico de Mapeo en Grupo.\n") ..
                  S("Permite compartir el mapa de forma automática con aliados.\n") ..
                  S("---------- COMANDOS DISPONIBLES ----------\n") ..
                  S("/mapparty create <nombre_party> [jugador1]... - Crea un grupo.\n") ..
                  S("/mapparty add <party> <jugador> - Añade a un aliado.\n") ..
                  S("/mapparty remove <party> <jugador> - Expulsa a un miembro.\n") ..
                  S("/mapparty leave - Abandona tu grupo actual.\n") ..
                  S("/mapparty list - Muestra todos los grupos creados.\n") ..
                  S("/mapparty info [party] - Detalles de un grupo específico.\n") ..
                  S("/mapparty delete <party> - Elimina el grupo (solo el dueño)."),
    
    func = function(name, param)
        local parts = param:split(" ")
-- ... (el resto de tu lógica para analizar 'parts' se mantiene intacto)
        if #parts == 0 or parts[1] == "" then
            return false, S("Usage: /mapparty <create|add|remove|delete|list|info|leave> [arguments]")
        end
        
        local action = parts[1]:lower()
        
        if action == "create" then
            if #parts < 2 then
                return false, S("Usage: /mapparty create <party_name> [player1] [player2] ...")
            end
            
            local party_name = parts[2]
            
            -- Check if party already exists
            if party_exists(party_name) then
                return false, S("Party '@1' already exists", party_name)
            end
            
            -- Check if player is already in a party
            if get_player_party(name) then
                return false, S("You are already in party '@1'. Leave it first.", get_player_party(name))
            end
            
            -- Create new party
            map_parties[party_name] = {
                owner = name,
                members = {name},
                created = os.time()
            }
            player_parties[name] = party_name
            
            -- Add additional players if specified
            local added_players = {}
            for i = 3, #parts do
                local player_name = parts[i]
                if minetest.player_exists(player_name) then
                    if not get_player_party(player_name) then
                        table.insert(map_parties[party_name].members, player_name)
                        player_parties[player_name] = party_name
                        table.insert(added_players, player_name)
                        
                        -- Notify the added player if they're online
                        if minetest.get_player_by_name(player_name) then
                            minetest.chat_send_player(player_name, 
                                S("You have been added to map party '@1' by @2", party_name, name))
                        end
                    else
                        minetest.chat_send_player(name, 
                            S("Player @1 is already in another party", player_name))
                    end
                else
                    minetest.chat_send_player(name, 
                        S("Player @1 does not exist", player_name))
                end
            end
            
            save_map_parties()
            
            local message = S("Map party '@1' created successfully", party_name)
            if #added_players > 0 then
                message = message .. S(" with members: @1", table.concat(added_players, ", "))
            end
            return true, message
            
        elseif action == "add" then
            if #parts ~= 3 then
                return false, S("Usage: /mapparty add <party_name> <player>")
            end
            
            local party_name = parts[2]
            local player_name = parts[3]
            
            -- Check if party exists
            if not party_exists(party_name) then
                return false, S("Party '@1' does not exist", party_name)
            end
            
            -- Check if caller is the party owner
            if not is_party_owner(name, party_name) then
                return false, S("Only the party owner can add players")
            end
            
            -- Check if target player exists
            if not minetest.player_exists(player_name) then
                return false, S("Player '@1' does not exist", player_name)
            end
            
            local success, message = add_player_to_party(party_name, player_name)
            if success then
                -- Notify the added player if they're online
                if minetest.get_player_by_name(player_name) then
                    minetest.chat_send_player(player_name, 
                        S("You have been added to map party '@1' by @2", party_name, name))
                end
            end
            return success, message
            
        elseif action == "remove" then
            if #parts ~= 3 then
                return false, S("Usage: /mapparty remove <party_name> <player>")
            end
            
            local party_name = parts[2]
            local player_name = parts[3]
            
            -- Check if party exists
            if not party_exists(party_name) then
                return false, S("Party '@1' does not exist", party_name)
            end
            
            -- Check if caller is the party owner or removing themselves
            if not is_party_owner(name, party_name) and name ~= player_name then
                return false, S("Only the party owner can remove other players")
            end
            
            local success, message = remove_player_from_party(party_name, player_name)
            if success then
                -- Notify the removed player if they're online
                if minetest.get_player_by_name(player_name) and player_name ~= name then
                    minetest.chat_send_player(player_name, 
                        S("You have been removed from map party '@1'", party_name))
                end
            end
            return success, message
            
        elseif action == "delete" then
            if #parts ~= 2 then
                return false, S("Usage: /mapparty delete <party_name>")
            end
            
            local party_name = parts[2]
            
            -- Check if party exists
            if not party_exists(party_name) then
                return false, S("Party '@1' does not exist", party_name)
            end
            
            -- Check if caller is the party owner
            if not is_party_owner(name, party_name) then
                return false, S("Only the party owner can delete the party")
            end
            
            local party = map_parties[party_name]
            
            -- Notify all members
            for _, member_name in ipairs(party.members) do
                player_parties[member_name] = nil
                if minetest.get_player_by_name(member_name) and member_name ~= name then
                    minetest.chat_send_player(member_name, 
                        S("Map party '@1' has been deleted by @2", party_name, name))
                end
            end
            
            -- Delete the party
            map_parties[party_name] = nil
            save_map_parties()
            
            return true, S("Map party '@1' deleted successfully", party_name)
            
        elseif action == "leave" then
            local party_name = get_player_party(name)
            if not party_name then
                return false, S("You are not in any party")
            end
            
            local success, message = remove_player_from_party(party_name, name)
            return success, message
            
        elseif action == "list" then
            if next(map_parties) == nil then
                return true, S("No map parties exist")
            end
            
            local party_list = {}
            for party_name, party_data in pairs(map_parties) do
                table.insert(party_list, string.format("%s (%d members, owner: %s)", 
                    party_name, #party_data.members, party_data.owner))
            end
            
            return true, S("Map parties:\n@1", table.concat(party_list, "\n"))
            
        elseif action == "info" then
            local party_name = parts[2] or get_player_party(name)
            
            if not party_name then
                return false, S("Usage: /mapparty info <party_name> or join a party first")
            end
            
            if not party_exists(party_name) then
                return false, S("Party '@1' does not exist", party_name)
            end
            
            local party = map_parties[party_name]
            local info = S("Party '@1':\n", party_name) ..
                        S("Owner: @1\n", party.owner) ..
                        S("Members (@1): @2\n", #party.members, table.concat(party.members, ", ")) ..
                        S("Created: @1", os.date("%Y-%m-%d %H:%M:%S", party.created))
            
            return true, info
            
        else
            return false, S("Unknown action '@1'. Use create, add, remove, delete, list, info, or leave", action)
        end
    end,
})

-- Initialize the system when the mod loads
minetest.register_on_mods_loaded(function()
    load_map_parties()
    minetest.log("action", "[persistent_map] Map party system loaded with " .. 
                 table.maxn(map_parties) .. " parties")
end)

-- Clean up when players leave
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    -- Note: We don't automatically remove players from parties when they leave
    -- This allows offline players to remain in parties and receive shared tiles
end)

minetest.log("action", "[persistent_map] Map party system loaded successfully")