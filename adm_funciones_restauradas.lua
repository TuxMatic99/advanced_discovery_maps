-- Advanced Discovery Maps P5C-R: faro nocturno recuperable y varita por franjas.
-- Compatible con sintaxis Lua 5.1. No altera el motor cartografico.
local core = minetest
local S = core.get_translator and core.get_translator(core.get_current_modname()) or function(s) return s end
local storage = core.get_mod_storage()
local BEACON_AIR = "advanced_discovery_maps:nv_beacon"
local BEACON_WATER = "advanced_discovery_maps:nv_beacon_liquid"
local nv_active = {}
local records = core.deserialize(storage:get_string("adm_nv_journal_v1")) or {}
if type(records) ~= "table" then records = {} end
local function save_records()
    storage:set_string("adm_nv_journal_v1", core.serialize(records))
end
local function key_for(p)
    return string.format("%d,%d,%d",p.x,p.y,p.z)
end
local function is_beacon(node)
    return node and (node.name == BEACON_AIR or node.name == BEACON_WATER)
end
local function restore_key(key)
    local rec = records[key]
    if not rec then return true end
    local now_node = core.get_node_or_nil(rec.pos)
    if not now_node then return false end -- El mapblock se restaurara al cargar mediante LBM.
    if is_beacon(now_node) and rec.original and rec.original.name then
        core.swap_node(rec.pos, rec.original)
    end
    records[key] = nil
    save_records()
    return true
end
local function stop_nv(name, player)
    local state = nv_active[name]
    if not state then return end
    nv_active[name] = nil
    if state.key then restore_key(state.key) end
    if player and player.override_day_night_ratio then
        player:override_day_night_ratio(state.previous_ratio)
    end
end
local function restore_legacy_beacon(pos, node)
    -- Los faros creados antes de P5C-R no tienen un registro del nodo original.
    -- Air se puede restaurar. En agua solo se infiere si hay una fuente vecina.
    if node.name == BEACON_AIR then
        core.swap_node(pos,{name="air"})
        return true
    end
    for _, d in ipairs({{1,0,0},{-1,0,0},{0,0,1},{0,0,-1},{0,1,0},{0,-1,0}}) do
        local near = core.get_node_or_nil({x=pos.x+d[1],y=pos.y+d[2],z=pos.z+d[3]})
        local def = near and core.registered_nodes[near.name]
        if def and def.liquidtype == "source" then
            core.swap_node(pos,{name=near.name,param2=near.param2 or 0})
            return true
        end
    end
    core.log("warning", "[ADM P5C-R] Faro submarino heredado sin agua vecina; requiere inspeccion en " .. key_for(pos))
    return false
end
core.register_lbm({
    label="ADM: restaurar faros tras reinicios",
    name="advanced_discovery_maps:recover_night_beacons_v1",
    nodenames={BEACON_AIR, BEACON_WATER},
    run_at_every_load=true,
    action=function(pos,node)
        local key=key_for(pos)
        if records[key] then restore_key(key)
        else restore_legacy_beacon(pos,node) end
    end,
})
core.register_chatcommand("nv", {
    description=S("Night vision for caves and underwater depths. Toggle with /nv"),
    func=function(name)
        local player=core.get_player_by_name(name)
        if not player then return false,S("Player not found") end
        if nv_active[name] then
            stop_nv(name,player)
            return true,S("Cave and underwater night vision disabled")
        end
        local old = player.get_day_night_ratio and player:get_day_night_ratio() or nil
        nv_active[name]={previous_ratio=old}
        if player.override_day_night_ratio then player:override_day_night_ratio(1) end
        return true,S("Cave and underwater night vision enabled")
    end,
})
local nv_elapsed=0
core.register_globalstep(function(dt)
    if not next(nv_active) then return end
    nv_elapsed=nv_elapsed+dt
    if nv_elapsed<0.20 then return end
    nv_elapsed=0
    for name,state in pairs(nv_active) do
        local player=core.get_player_by_name(name)
        if not player then stop_nv(name,nil)
        else
            local pos=player:get_pos()
            if pos then
                local head={x=math.floor(pos.x+0.5),y=math.floor(pos.y+1.5),z=math.floor(pos.z+0.5)}
                local key=key_for(head)
                if state.key~=key then
                    if state.key then restore_key(state.key);state.key=nil end
                    local node=core.get_node_or_nil(head)
                    local def=node and core.registered_nodes[node.name]
                    local liquid=def and (def.liquidtype=="source" or def.liquidtype=="flowing")
                    -- No sustituir modulos, inventarios, plantas, ni suelo protegido.
                    if node and (node.name=="air" or liquid)
                            and not core.is_protected(head,name)
                            and not records[key] then
                        local beacon=liquid and BEACON_WATER or BEACON_AIR
                        records[key]={pos=head,original={name=node.name,param1=node.param1,param2=node.param2},owner=name}
                        save_records() -- registrar ANTES de mutar: recuperacion tras fallo
                        local ok=core.swap_node(head,{name=beacon,param2=node.param2 or 0})
                        if ok==false then
                            records[key]=nil;save_records()
                        else state.key=key end
                    end
                end
            end
        end
    end
end)

local active_wands={}
local active_count=0
local WAND_LIMIT=2
local MAX_RADIUS=100
-- Franjas pequenas: una computadora lenta puede reducir las filas por paso.
local MAX_ROWS=math.max(1,math.min(16,
    math.floor(tonumber(core.settings:get("adm_wand_rows_per_step")) or 8)))
-- Franja corta por turno. En PCs lentos, reducir filas por paso.
local TICK=math.max(0,math.min(0.10, tonumber(core.settings:get("adm_wand_step_delay")) or 0.005))
local AIR_ID=core.get_content_id("air")
local IGNORE_ID=core.get_content_id("ignore")
core.register_privilege("adm_excavate",{
    description="Use the Advanced Discovery Maps geological excavation wand",
    give_to_singleplayer=true,give_to_admin=true,
})
local function can_excavate(name)
    return core.check_player_privs(name,{adm_excavate=true})
end
local function inform(name,msg)
    if core.get_player_by_name(name) then core.chat_send_player(name,msg) end
end
local function finish_job(job,cancelled)
    if not active_wands[job.name] or active_wands[job.name]~=job then return end
    active_wands[job.name]=nil
    active_count=math.max(0,active_count-1)
    if cancelled then
        inform(job.name,S("Excavation stopped"))
    elseif job.removed==0 then
        inform(job.name,S("Excavation complete: no removable nodes (check target and privilege)"))
    else
        inform(job.name,string.format("%s: %d %s, %d %s",S("Excavation complete"),job.removed,
            S("nodes removed"),job.protected,S("protected nodes skipped")))
    end
end
local function node_has_data(p)
    local meta=core.get_meta(p):to_table()
    if not meta then return false end
    for _,v in pairs(meta.fields or {}) do if v~=nil and v~="" then return true end end
    for _,items in pairs(meta.inventory or {}) do
        for _,stack in ipairs(items) do if stack and stack~="" then return true end end
    end
    return false
end
-- on_dig tiene un valor predeterminado incluso en piedras normales.
-- Rechazar TODAS las funciones on_dig hacia que la varita no excavara nada.
-- TNT-compatible: voxeles comunes en bloque, callbacks especiales por separado.
-- No clasificar por walkable: hojas, hierbas, flores y plantas tambien explotan.
local node_cache = {}
local default_dig = core.nodedef_default and core.nodedef_default.on_dig
local function node_policy(id)
    local cached = node_cache[id]
    if cached then return cached end
    local nodename = core.get_name_from_content_id(id)
    local def = nodename and core.registered_nodes[nodename]
    if not def or def.diggable == false or
            (def.groups and ((def.groups.unbreakable or 0) > 0 or
             (def.groups.immortal or 0) > 0)) then
        cached = {mode = "skip"}
    elseif def.on_blast then
        -- Respetar el protocolo TNT del nodo: puede activar comportamiento propio.
        cached = {mode = "blast", def = def, name = nodename}
    elseif def.on_destruct or def.after_destruct or def.on_timer or
           def.on_construct or def.can_dig or def.after_dig_node or
           def.preserve_metadata or
           (def.on_dig and def.on_dig ~= default_dig and def.on_dig ~= core.node_dig) then
        -- Nodos con comportamiento propio: eliminacion con callbacks de Luanti.
        cached = {mode = "remove", def = def, name = nodename}
    else
        -- Bloques ordinarios de cualquier material, incluso walkable=false.
        cached = {mode = "bulk", def = def, name = nodename}
    end
    node_cache[id] = cached
    return cached
end

local function metadata_index(minp, maxp, area)
    -- Evitar consultas individuales get_meta por millones de nodos.
    if not core.find_nodes_with_meta then return nil end
    local ok, found = pcall(core.find_nodes_with_meta, minp, maxp)
    if not ok or type(found) ~= "table" then return nil end
    local lookup = {}
    for _, pos in ipairs(found) do
        lookup[area:index(pos.x, pos.y, pos.z)] = true
    end
    return lookup
end

local function run_special(job, candidate)
    local pos = candidate.pos
    if core.is_protected(pos, job.name) then
        job.protected = job.protected + 1
        return
    end
    -- Verificar de nuevo despues del VoxelManip: otro mod pudo cambiar el nodo.
    local current = core.get_node_or_nil(pos)
    if not current or current.name ~= candidate.policy.name or node_has_data(pos) then return end
    local def = candidate.policy.def
    if def.can_dig then
        local player = core.get_player_by_name(job.name)
        local ok, allowed = pcall(def.can_dig, pos, player)
        if not ok or not allowed then return end
    end
    local success
    if candidate.policy.mode == "blast" then
        success = pcall(def.on_blast, pos, 1.0)
    else
        success = pcall(core.remove_node, pos)
    end
    if not success then
        core.log("warning", "[ADM] Excepcion en callback de explosion en " .. key_for(pos))
    else
        local after = core.get_node_or_nil(pos)
        if after and after.name ~= current.name then job.removed = job.removed + 1 end
    end
end
local function advance(job)
    if active_wands[job.name]~=job then return end
    if not core.get_player_by_name(job.name) or not can_excavate(job.name) then
        finish_job(job,true); return
    end
    if job.dy < -job.radius then finish_job(job,false); return end
    local r=job.radius
    local dy=job.dy
    local horizontal=math.floor(math.sqrt(r*r-dy*dy))
    local z0=job.z
    local z1=math.min(z0+MAX_ROWS-1,horizontal)
    local ymin=job.pos.y+dy
    local minp={x=job.pos.x-horizontal,y=ymin,z=job.pos.z+z0}
    local maxp={x=job.pos.x+horizontal,y=ymin,z=job.pos.z+z1}
    local vm=core.get_voxel_manip()
    local emin,emax=vm:read_from_map(minp,maxp)
    local data=vm:get_data(job.buffer)
    local area=VoxelArea:new({MinEdge=emin,MaxEdge=emax})
    local changed = false
    local special = {}
    local meta_lookup = metadata_index(minp, maxp, area)
    -- Una sola tabla mutable para los candidatos de la ruta rapida.
    local p = {x = 0, y = ymin, z = 0}
    for dz = z0, z1 do
        p.z = job.pos.z + dz
        local dxmax = math.floor(math.sqrt(r*r - dy*dy - dz*dz))
        for dx = -dxmax, dxmax do
            p.x = job.pos.x + dx
            local index = area:index(p.x, p.y, p.z)
            local id = data[index]
            if id and id ~= IGNORE_ID and id ~= AIR_ID then
                local policy = node_policy(id)
                if policy.mode ~= "skip" then
                    if core.is_protected(p, job.name) then
                        job.protected = job.protected + 1
                    elseif not (meta_lookup and meta_lookup[index]) and
                           (meta_lookup or not node_has_data(p)) then
                        if policy.mode == "bulk" then
                            data[index] = AIR_ID
                            job.removed = job.removed + 1
                            changed = true
                        else
                            special[#special+1] = {
                                pos = {x=p.x, y=p.y, z=p.z}, policy = policy,
                            }
                        end
                    end
                end
            end
        end
    end
    if changed then
        vm:set_data(data)
        vm:write_to_map()
        if vm.update_liquids and core.settings:get_bool("adm_wand_update_liquids", true) then
            vm:update_liquids()
        end
    end
    -- La ruta compatible se ejecuta despues del bloque de VoxelManip
    -- para que los callbacks no se sobrescriban con una copia antigua.
    for _, candidate in ipairs(special) do run_special(job, candidate) end
    job.z=z1+1
    if job.z>horizontal then
        job.dy=job.dy-1
        if job.dy>=-r then
            job.z=-math.floor(math.sqrt(r*r-job.dy*job.dy))
        end
        if core.settings:get_bool("adm_wand_particles",true) and job.dy%8==0 then
            core.add_particlespawner({amount=8,time=0.15,minpos=minp,maxpos=maxp,
                minvel={x=-1,y=1,z=-1},maxvel={x=1,y=3,z=1},
                minexptime=0.2,maxexptime=0.5,minsize=3,maxsize=6,
                texture="adm_wand_spark.png"})
        end
    end
    if job.dy < -r then finish_job(job,false)
    else core.after(TICK,function()
        local ok,err=pcall(advance,job)
        if not ok then core.log("error","[ADM P5C-R] varita: "..tostring(err));finish_job(job,true) end
    end) end
end
local function start_wand(player,pointed_thing,radius)
    local name=player:get_player_name()
    if not can_excavate(name) then
        inform(name,S("You need the adm_excavate privilege to use this wand"))
        return false
    end
    if active_wands[name] then inform(name,S("Excavation already running. Use /adm_wand_cancel"));return false end
    if active_count>=WAND_LIMIT then inform(name,S("Excavation queue full; try again later"));return false end
    if not pointed_thing or pointed_thing.type~="node" then
        inform(name,S("Apunta a un bloque solido y usa la varita con clic izquierdo"))
        return false
    end
    local src=pointed_thing.under
    local pos={x=math.floor(src.x+0.5),y=math.floor(src.y+0.5),z=math.floor(src.z+0.5)}
    if core.is_protected(pos,name) then inform(name,S("Target area is protected"));return false end
    radius=math.min(MAX_RADIUS,math.max(1,math.floor(radius or 5)))
    if core.sound_play then
        core.sound_play("tnt_explode",{pos=pos,gain=0.7,max_hear_distance=40},true)
    end
    local job={name=name,pos=pos,radius=radius,dy=radius,z=0,
        removed=0,protected=0,buffer={}}
    active_wands[name]=job
    active_count=active_count+1
    inform(name,string.format("%s: %d",S("Excavation started. Radius"),radius))
    core.after(TICK,function()
        local ok,err=pcall(advance,job)
        if not ok then core.log("error","[ADM P5C-R] varita: "..tostring(err));finish_job(job,true) end
    end)
    return true
end
core.register_chatcommand("adm_wand_status",{
    description=S("Mostrar radio, permiso y actividad de la varita"),
    func=function(name)
        local player=core.get_player_by_name(name)
        if not player then return false,S("Jugador no disponible") end
        local item=player:get_wielded_item()
        local holding=item and item:get_name()=="advanced_discovery_maps:tuxmatic_wand"
        local radius=holding and item:get_meta():get_int("radius") or 0
        if radius<1 then radius=5 end
        local job=active_wands[name]
        return true,string.format("Tuxmatic: radio=%d, permiso=%s, trabajo=%s, extraidos=%d",
            radius,can_excavate(name) and "si" or "no",
            job and "activo" or "inactivo",job and job.removed or 0)
    end,
})
core.register_chatcommand("adm_wand_cancel",{
    description=S("Cancel your current excavation operation"),
    func=function(name)
        local job=active_wands[name]
        if not job then return false,S("No active excavation") end
        finish_job(job,true)
        return true,S("Excavation cancelled")
    end,
})
local function gui(itemstack,user)
    if not user or not user:is_player() then return itemstack end
    local radius=itemstack:get_meta():get_int("radius")
    if radius<1 then radius=5 end
    local form="size[7,3.3]label[0.3,0.3;"..core.formspec_escape(S("Excavation radius (1-100)")).."]" ..
      "field[0.4,1.15;3.3,0.8;radius;;"..radius.."]button[3.9,1.15;2.5,0.8;save;"..core.formspec_escape(S("Save")).."]" ..
      "label[0.3,2.25;"..core.formspec_escape(S("Protected nodes and inventories are preserved")).."]"
    core.show_formspec(user:get_player_name(),"advanced_discovery_maps:wand_gui",form)
    return itemstack
end
core.register_on_player_receive_fields(function(player,formname,fields)
    if formname~="advanced_discovery_maps:wand_gui" then return end
    if not fields.save then return end
    local stack=player:get_wielded_item()
    if stack:get_name()~="advanced_discovery_maps:tuxmatic_wand" then return end
    local radius=tonumber(fields.radius)
    if not radius or radius~=math.floor(radius) or radius<1 or radius>100 then
        inform(player:get_player_name(),S("Radius must be an integer from 1 to 100"));return
    end
    stack:get_meta():set_int("radius",radius)
    player:set_wielded_item(stack)
    inform(player:get_player_name(),S("Excavation radius saved"))
end)
core.register_tool("advanced_discovery_maps:tuxmatic_wand",{
    description=S("Tuxmatic geological excavation wand (radius 1-100)"),
    inventory_image="default_stick.png^[colorize:#FF3030:120",
    range=25,
    groups={not_in_creative_inventory=0},
    on_use=function(itemstack,user,pointed_thing)
        if user and user:is_player() then
            local radius=itemstack:get_meta():get_int("radius")
            if radius<1 then radius=5 end
            start_wand(user,pointed_thing,radius)
        end
        return itemstack
    end,
    on_place=gui,on_secondary_use=gui,
})
core.register_on_leaveplayer(function(player)
    local name=player:get_player_name()
    stop_nv(name,player)
    if active_wands[name] then finish_job(active_wands[name],true) end
end)
core.register_on_shutdown(function()
    for name,state in pairs(nv_active) do
        stop_nv(name,core.get_player_by_name(name))
    end
    for _,job in pairs(active_wands) do finish_job(job,true) end
end)
-- Recuperar los beacons de sesiones terminadas que siguen en mapblocks cargados.
-- Los que aun no estan cargados seran tratados por el LBM.
core.after(0,function()
    local keys={}
    for key in pairs(records) do keys[#keys+1]=key end
    for _,key in ipairs(keys) do restore_key(key) end
end)
