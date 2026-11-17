local root = assert(arg[1], "usage: texlua tests/test_adm_p5c_runtime.lua .")
local nodes={}
local records={}
local tick, callbacks, pending=0,{},{}
local chat,tool,priv,lbm,leave,shutdown={},nil,nil,nil,nil,nil
local enabled=true
local function k(p)return p.x..","..p.y..","..p.z end
local function node(p)return nodes[k(p)] or {name="air",param2=0} end
local function set(p,n)nodes[k(p)]={name=n.name,param2=n.param2 or 0}end
local player={pos={x=0,y=0,z=0},ratio=nil,radius=2}
function player:get_pos()return self.pos end
function player:get_player_name()return "singleplayer" end
function player:override_day_night_ratio(x)self.ratio=x end
function player:get_day_night_ratio()return self.ratio end
function player:is_player()return true end
local stack={}
local meta={}
function meta:get_int()return player.radius end
function meta:set_int(_,v)player.radius=v end
function stack:get_meta()return meta end
function stack:get_name()return "advanced_discovery_maps:tuxmatic_wand" end
function player:get_wielded_item()return stack end
function player:set_wielded_item()end
local world={protected={["1,0,0"]=true}, metadata={["-1,0,0"]=true}}
local core={
    registered_nodes={air={walkable=false,liquidtype="none"},
        water={walkable=false,liquidtype="source"},stone={walkable=true,diggable=true}},
    get_current_modname=function()return "advanced_discovery_maps" end,
    get_translator=function()return function(s)return s end end,
    get_mod_storage=function()return {get_string=function(_,key)return records[key] or "" end,
                               set_string=function(_,key,s)records[key]=s end}end,
    serialize=function(v) records._state=v;return "mock-state" end,
    deserialize=function(s) return s=="mock-state" and records._state or nil end,
    register_lbm=function(d)lbm=d end,
    register_chatcommand=function(name,d)chat[name]=d end,
    register_privilege=function(name,d)assert(name=="adm_excavate");priv=d end,
    check_player_privs=function()return enabled end,
    register_tool=function(name,d)assert(name=="advanced_discovery_maps:tuxmatic_wand");tool=d end,
    register_on_player_receive_fields=function()end,
    register_on_leaveplayer=function(fn)leave=fn end,
    register_on_shutdown=function(fn)shutdown=fn end,
    register_globalstep=function(fn)callbacks[#callbacks+1]=fn end,
    get_player_by_name=function(name)if name=="singleplayer" then return player end end,
    get_node_or_nil=function(p)return node(p)end,
    get_node=function(p)return node(p)end,
    swap_node=function(p,n)set(p,n);return true end,
    is_protected=function(p)return world.protected[k(p)] or false end,
    get_meta=function(p) return {to_table=function()
      return world.metadata[k(p)] and {fields={owner="test"}} or {fields={},inventory={}} end} end,
    get_content_id=function(name) return name=="air" and 0 or 1 end,
    get_name_from_content_id=function(id) return ({[0]="air",[1]="ignore",[2]="stone"})[id] end,
    settings={get_bool=function(_,key,d)return d end, get=function(_,key)return nil end},
    show_formspec=function()end,
    formspec_escape=function(s)return s end,
    chat_send_player=function()end,
    log=function(_,msg)error("Lua mod log: "..tostring(msg))end,
    add_particlespawner=function()end,
    after=function(_,cb)pending[#pending+1]=cb end,
    get_voxel_manip=function()
       local vm={}
       local minp,maxp
       function vm:read_from_map(a,b)minp=a;maxp=b;return a,b end
       function vm:get_data(buf)
         local n=1
         for z=minp.z,maxp.z do for y=minp.y,maxp.y do for x=minp.x,maxp.x do
             local p={x=x,y=y,z=z}
             buf[n]=node(p).name=="stone" and 2 or 0;n=n+1
         end end end
         return buf
       end
       function vm:set_data(d)
         local n=1
         for z=minp.z,maxp.z do for y=minp.y,maxp.y do for x=minp.x,maxp.x do
           local p={x=x,y=y,z=z}
           set(p,{name=d[n]==2 and "stone" or "air"});n=n+1
         end end end
       end
       function vm:write_to_map()end
       function vm:update_liquids()end
       return vm
    end,
}
_G.minetest=core
_G.VoxelArea={new=function(_,args)
   return {index=function(_,x,y,z)
       return ((z-args.MinEdge.z)*(args.MaxEdge.y-args.MinEdge.y+1)+(y-args.MinEdge.y))*(args.MaxEdge.x-args.MinEdge.x+1)+(x-args.MinEdge.x)+1
   end}
end}
assert(loadfile(root.."/adm_funciones_restauradas.lua"))()
assert(chat.nv and chat.adm_wand_cancel and tool and lbm and leave and shutdown)
local function step(dt)
   for _,cb in ipairs(callbacks)do cb(dt)end
   local todo=pending;pending={};for _,cb in ipairs(todo)do cb()end
end
step(0.01) -- completar recuperacion al inicio ANTES de entrar al mundo
assert(chat.nv.func("singleplayer"))
step(0.3)
assert(node({x=0,y=1,z=0}).name=="advanced_discovery_maps:nv_beacon","cueva no se ilumina")
assert(player.ratio==1)
chat.nv.func("singleplayer")
assert(node({x=0,y=1,z=0}).name=="air","aire no se restauro")
set({x=0,y=1,z=0},{name="water"})
chat.nv.func("singleplayer")
step(0.3)
assert(node({x=0,y=1,z=0}).name=="advanced_discovery_maps:nv_beacon_liquid","agua no iluminada")
-- Simular carga de mapblock tras reinicio: LBM restaura el agua original.
lbm.action({x=0,y=1,z=0},node({x=0,y=1,z=0}))
assert(node({x=0,y=1,z=0}).name=="water","LBM no restauro agua")
chat.nv.func("singleplayer")
for x=-2,2 do for z=-2,2 do for y=-2,2 do
  if x*x+y*y+z*z<=4 then set({x=x,y=y,z=z},{name="stone"}) end
end end end
-- Proteccion y nodo con metadatos deben permanecer intactos.
enabled=false
assert(tool.on_use(stack,player,{type="node",under={x=0,y=0,z=0}})==stack)
assert(#pending==0,"no se nego acceso sin privilegio")
enabled=true
assert(tool.on_use(stack,player,{type="node",under={x=0,y=0,z=0}})==stack)
local it=0
while #pending>0 and it<80 do step(0.02);it=it+1 end
assert(it<80,"la excavacion no termina")
assert(node({x=1,y=0,z=0}).name=="stone","bloque protegido modificado")
assert(node({x=-1,y=0,z=0}).name=="stone","metadatos modificados")
assert(node({x=0,y=0,z=0}).name=="air","no excava roca")
-- Cancelacion activa
assert(tool.on_use(stack,player,{type="node",under={x=0,y=0,z=0}})==stack)
assert(chat.adm_wand_cancel.func("singleplayer"))
leave(player)
shutdown()
print("OK P5C-R: cuevas, agua, LBM tras fallo, permisos, proteccion, inventarios y excavacion")
