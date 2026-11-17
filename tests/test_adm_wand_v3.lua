-- Prueba realista de la esfera TNT: materiales, callbacks, limites y proteccion.
local root = assert(arg[1], "uso: texlua tests/test_adm_wand_v3.lua .")
local defs = {}
local id_to_name, name_to_id = {}, {}
local function define(id,name,def)
    id_to_name[id] = name; name_to_id[name] = id; defs[name] = def or {}
end
local default_dig = function() return true end
define(0,"air", {walkable=false})
define(1,"ignore", {diggable=false})
define(2,"stone", {walkable=true, on_dig=default_dig})
define(3,"dirt", {walkable=true})
define(4,"sand", {walkable=true})
define(5,"wood", {walkable=true})
define(6,"leaves", {walkable=false})
define(7,"grass", {walkable=false})
define(8,"flower", {walkable=false})
define(9,"glass", {walkable=true})
define(10,"chest", {walkable=true, on_construct=function() end})
define(11,"unbreakable", {walkable=true,diggable=false})
local special_destroyed, blasted = 0, 0
define(12,"special", {walkable=true, on_destruct=function() special_destroyed=special_destroyed+1 end})
define(13,"blastnode", {walkable=true, on_blast=function(p,intensity)
    assert(intensity == 1.0); blasted=blasted+1
    -- Se define mas abajo, cuando existe 'set'.
    _G.__test_set(p,"air")
end})
define(14,"water", {walkable=false, liquidtype="source"})
local nodes, metadata, protected = {}, {}, {}
local function key(p) return p.x..","..p.y..","..p.z end
local function get(p) return nodes[key(p)] or "air" end
local function set(p,name) nodes[key(p)] = name end
_G.__test_set=set
local meta_store={}
local callbacks, pending, chats, logs = {}, {}, {}, {}
local tool, fields, lbm, shutdown, leave
local stack, player={}, {pos={x=0,y=0,z=0},ratio=nil,radius=3}
local itemmeta = {get_int=function()return player.radius end,set_int=function(_,_,x)player.radius=x end}
function stack:get_meta()return itemmeta end
function stack:get_name()return "advanced_discovery_maps:tuxmatic_wand" end
function player:get_player_name()return "singleplayer" end
function player:get_wielded_item()return stack end
function player:set_wielded_item()end
function player:get_pos()return self.pos end
function player:is_player()return true end
function player:override_day_night_ratio(r)self.ratio=r end
function player:get_day_night_ratio()return self.ratio end
local core={
    registered_nodes=defs, nodedef_default={on_dig=default_dig}, node_dig=default_dig,
    get_current_modname=function()return "advanced_discovery_maps" end,
    get_translator=function()return function(s)return s end end,
    get_mod_storage=function()return {
      get_string=function(_,k)return meta_store[k] or "" end,
      set_string=function(_,k,v)meta_store[k]=v end,
    }end,
    serialize=function(x)meta_store.__value=x;return "value" end,
    deserialize=function(v)return v=="value" and meta_store.__value or nil end,
    register_lbm=function(x)lbm=x end,
    register_chatcommand=function(n,x)chats[n]=x end,
    register_privilege=function()end,
    register_tool=function(_,x)tool=x end,
    register_globalstep=function(f)callbacks[#callbacks+1]=f end,
    register_on_leaveplayer=function(f)leave=f end,
    register_on_shutdown=function(f)shutdown=f end,
    register_on_player_receive_fields=function(f)fields=f end,
    check_player_privs=function()return true end,
    get_player_by_name=function(n)if n=="singleplayer" then return player end end,
    get_node_or_nil=function(p)return {name=get(p)}end,
    get_node=function(p)return {name=get(p)}end,
    swap_node=function(p,n)set(p,n.name);return true end,
    remove_node=function(p)
       local def=defs[get(p)]
       if def and def.on_destruct then def.on_destruct(p)end
       set(p,"air");return true
    end,
    is_protected=function(p)return protected[key(p)] or false end,
    get_meta=function(p)return {to_table=function()
        if metadata[key(p)] then return {fields={owner="player"},inventory={main={"important item"}}} end
        return {fields={},inventory={}}
    end}end,
    find_nodes_with_meta=function(minp,maxp)
        local a={}
        for z=minp.z,maxp.z do for y=minp.y,maxp.y do for x=minp.x,maxp.x do
          local p={x=x,y=y,z=z}
          if metadata[key(p)] then a[#a+1]=p end
        end end end
        return a
    end,
    get_content_id=function(n)return name_to_id[n] end,
    get_name_from_content_id=function(id)return id_to_name[id] end,
    settings={get=function()return nil end,get_bool=function(_,_,default)return default end},
    formspec_escape=function(s)return s end, show_formspec=function()end,
    chat_send_player=function(_,s)chats[#chats+1]=s end,
    log=function(level,msg) logs[#logs+1]=level..":"..msg end,
    after=function(_,cb)pending[#pending+1]=cb end,
    add_particlespawner=function()end,
    get_voxel_manip=function()
       local vm,minp,maxp={},nil,nil
       function vm:read_from_map(a,b)minp=a;maxp=b;return a,b end
       function vm:get_data(buf)
         local n=1
         for z=minp.z,maxp.z do for y=minp.y,maxp.y do for x=minp.x,maxp.x do
             buf[n]=name_to_id[get({x=x,y=y,z=z})];n=n+1
         end end end
         return buf
       end
       function vm:set_data(buf)
         local n=1
         for z=minp.z,maxp.z do for y=minp.y,maxp.y do for x=minp.x,maxp.x do
             set({x=x,y=y,z=z},assert(id_to_name[buf[n]]));n=n+1
         end end end
       end
       function vm:write_to_map()end
       function vm:update_liquids()end
       return vm
    end,
}
_G.minetest=core
_G.VoxelArea={new=function(_,opts)
  return {index=function(_,x,y,z)
    local xmin,ymin,zmin=opts.MinEdge.x,opts.MinEdge.y,opts.MinEdge.z
    local nx=opts.MaxEdge.x-xmin+1;local ny=opts.MaxEdge.y-ymin+1
    return (z-zmin)*nx*ny+(y-ymin)*nx+(x-xmin)+1
  end}
end}
assert(loadfile(root.."/adm_funciones_restauradas.lua"))()
local function step()
  local old=pending;pending={}
  for _,f in ipairs(old)do f()end
end
local cases={
 {x=0,y=0,z=0,name="stone"},
 {x=0,y=1,z=0,name="wood"},
 {x=0,y=-1,z=0,name="sand"},
 {x=0,y=0,z=1,name="leaves"},
 {x=0,y=0,z=-1,name="grass"},
 {x=-1,y=1,z=0,name="flower"},
 {x=1,y=1,z=0,name="glass"},
 {x=-1,y=-1,z=0,name="dirt"},
 {x=0,y=1,z=1,name="special"},
 {x=0,y=1,z=-1,name="blastnode"},
 {x=0,y=-1,z=1,name="water"},
}
for _,p in ipairs(cases)do set(p,p.name)end
local protected_p={x=2,y=0,z=0};set(protected_p,"wood");protected[key(protected_p)]=true
local metadata_p={x=-2,y=0,z=0};set(metadata_p,"chest");metadata[key(metadata_p)]=true
local solid_p={x=0,y=-2,z=0};set(solid_p,"unbreakable")
local outside_p={x=4,y=0,z=0};set(outside_p,"wood")
fields(player,"advanced_discovery_maps:wand_gui",{save=true,radius="3"})
assert(player.radius==3)
assert(tool.on_use(stack,player,{type="node",under={x=0,y=0,z=0}})==stack)
local count=0
while #pending>0 and count<200 do step();count=count+1 end
assert(count<200,"excavacion no termina")
for _,p in ipairs(cases)do assert(get(p)=="air",p.name.." no fue destruido")end
assert(special_destroyed==1,"no se ejecuto on_destruct")
assert(blasted==1,"no se ejecuto on_blast")
assert(get(protected_p)=="wood","destruyo madera protegida")
assert(get(metadata_p)=="chest","destruyo cofre con inventario")
assert(get(solid_p)=="unbreakable","destruyo nodo indestructible")
assert(get(outside_p)=="wood","destruyo fuera del radio")
assert(chats.adm_wand_status and chats.adm_wand_cancel and lbm and shutdown and leave)
print("OK P5C-V3: roca, tierra, arena, madera, hojas, hierbas, flores, cristal, agua y callbacks TNT; protecciones intactas")
