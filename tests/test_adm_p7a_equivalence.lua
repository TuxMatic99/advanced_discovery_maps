-- P7A: comparación exacta de las tres imágenes generadas por motor original/optimizado.
-- Uso: texlua tests/test_adm_p7a_equivalence.lua ORIGINAL.lua ACTUAL.lua
-- No utiliza el juego ni altera mapas; simula únicamente lecturas y PNG en memoria.
local old_path, new_path = arg[1], arg[2]
assert(old_path and new_path, "Se requieren los dos archivos del motor")
local unpack = table.unpack or unpack

local names = {
    [0] = "air", [1] = "ignore", [2] = "default:stone", [3] = "default:dirt",
    [4] = "default:water_source", [5] = "default:leaves", [6] = "flowers:rose",
    [7] = "default:glass", [8] = "default:lava_source", [9] = "default:sand",
    [10] = "default:tree"
}
local ids = {}
for id, name in pairs(names) do ids[name] = id end
local def = {
    ["default:stone"] = {groups={cracky=1}},
    ["default:dirt"] = {groups={crumbly=1}},
    ["default:water_source"] = {groups={water=3}, drawtype="liquid"},
    ["default:leaves"] = {groups={leaves=1}, drawtype="allfaces_optional"},
    ["flowers:rose"] = {groups={flora=1}, walkable=false},
    ["default:glass"] = {groups={cracky=1}},
    ["default:lava_source"] = {groups={lava=3}, drawtype="liquid"},
    ["default:sand"] = {groups={crumbly=1}},
    ["default:tree"] = {groups={tree=1}, walkable=true},
}
local color = {
    ["default:stone"] = {105,107,115}, ["default:dirt"]={110,70,30},
    ["default:water_source"]={30,100,210}, ["default:leaves"]={22,130,29},
    ["flowers:rose"]={180,50,62}, ["default:glass"]={190,210,225},
    ["default:lava_source"]={240,70,10}, ["default:sand"]={205,190,110},
    ["default:tree"]={110,70,35}, ["air"]={0,0,0}
}
local function get_node_color(name) return color[name] or {80,90,100} end

-- Terreno variado con vegetación sobre roca, lago, lava, túneles y desniveles.
local function node_at(x,y,z,variant)
    local m = (x * 7 + z * 11 + variant * 5) % 9
    local top = 34 + ((x * 3 + z * 5 + variant) % 19) - 9
    local water = ((x + z + variant) % 7 == 0)
    if y > top then
        if y == top + 1 and m == 1 then return 5 end
        if y == top + 2 and m == 1 then return 5 end
        if y == top + 1 and m == 2 then return 6 end
        if y == top + 1 and m == 3 then return 10 end
        return 0
    end
    if water and y > top - 5 then return 4 end
    if m == 8 and y > top - 2 then return 8 end
    if y > top - 2 then return (m == 4) and 9 or 3 end
    if y < top - 7 and y > top - 12 and (x + z) % 3 ~= 1 then return 0 end
    if y < top - 17 and y > top - 23 and (x - z) % 2 == 0 then return 0 end
    return (x * 3 + y * 5 + z + variant) % 13 == 0 and 7 or 2
end

local function simulated_engine(path, mode, variant, side, stripe)
    local outputs, lookups = {}, 0
    local tick = 0
    _G.vector = {new=function(x,y,z) return {x=x,y=y,z=z} end}
    _G.VoxelArea = {}
    function VoxelArea:new(t)
        local nx = t.MaxEdge.x-t.MinEdge.x+1
        local ny = t.MaxEdge.y-t.MinEdge.y+1
        return setmetatable({xmin=t.MinEdge.x,ymin=t.MinEdge.y,zmin=t.MinEdge.z,
            xstride=1,ystride=nx,zstride=nx*ny}, {__index={
                index=function(self,x,y,z)
                    return (z-self.zmin)*self.zstride + (y-self.ymin)*self.ystride + (x-self.xmin)+1
                end
            }})
    end
    local settings={
        get=function(_,name)
            if name=="adm_scan_mode" then return mode end
            if name=="adm_stripe_rows" then return tostring(stripe) end
            return nil
        end,
        get_bool=function(_,name,default)
            if name=="adm_profile_tiles" then return false end
            if name=="adm_lazy_media" then return true end
            return default
        end
    }
    _G.minetest={
        settings=settings, registered_nodes=def,
        get_us_time=function() tick=tick+1000; return tick end,
        get_content_id=function(name) return assert(ids[name],name) end,
        get_name_from_content_id=function(id) lookups=lookups+1; return assert(names[id],"id "..tostring(id)) end,
        get_voxel_manip=function()
            local vm={}
            function vm:read_from_map(p1,p2)
                self.min=p1; self.max=p2
                return p1,p2
            end
            function vm:get_data(buffer)
                local index=0
                for z=self.min.z,self.max.z do
                    for y=self.min.y,self.max.y do
                        for x=self.min.x,self.max.x do
                            index=index+1
                            buffer[index] = node_at(x,y,z,variant)
                        end
                    end
                end
                return buffer
            end
            function vm:close() end
            return vm
        end,
        after=function(_,func) func() end,
        encode_png=function(w,h,bytes) assert(#bytes == w*h*4, "Tamaño RGBA incorrecto") return bytes end,
        safe_file_write=function(path,contents) outputs[path]=contents; return true end,
        log=function() end,
        dynamic_add_media=function() end
    }
    local P={
        tile_size=side, min_height=-40,max_height=64,cave_scan_depth=64,cave_min_height=4,
        tile_versions={}, map_path="test/", generation={default_color_r=100,default_color_g=100,
            default_color_b=100,alpha_value=255},
    }
    local engine=assert(loadfile(path))()(P,
        function(x,z) return "tile_"..x.."_"..z end,
        function(_) return false end,
        get_node_color,"test/")
    local callback_count=0
    engine(0,0,function() callback_count=callback_count+1 end)
    assert(callback_count==1,"Se perdió la notificación de cuadrante terminado")
    assert(outputs["test/tile_0_0.png"],"No se generó natural")
    assert(outputs["test/tile_0_0_relief.png"],"No se generó relieve")
    assert(outputs["test/tile_0_0_cave.png"],"No se generó cueva")
    return outputs, lookups
end

local scenarios = {
    {"balanced",1,8,16},
    {"light",2,17,16},
    {"full",3,24,32},
    {"balanced",4,33,16},
}
local total_saved=0
for _,s in ipairs(scenarios) do
    local mode, variant, side, stripe=unpack(s)
    local a, ac = simulated_engine(old_path,mode,variant,side,stripe)
    local b, bc = simulated_engine(new_path,mode,variant,side,stripe)
    for path,png in pairs(a) do
        assert(b[path]==png, "P7A cambió píxeles en "..mode..", "..path)
    end
    assert(bc<=ac,"P7A aumentó las consultas de nombre Content ID")
    total_saved=total_saved+ac-bc
    io.write(string.format("OK %-8s tile=%d franjas=%d: PNG idénticos; consultas CID %d -> %d\n",
        mode,side,stripe,ac,bc))
end
assert(total_saved>0,"La caché no ahorró consultas en los escenarios de ensayo")
print("OK P7A: identidad píxel a píxel en natural, relieve y caverna; menos consultas de nodos")
