-- P7-B1: prueba ejecutable del motor, transferencia solo bajo demanda y renderer.
-- Uso: texlua tests/test_adm_p7b1.lua .
local root = assert(arg[1], "Falta ruta del repositorio")
local topo = assert(loadfile(root .. '/map_topography.lua'))()
local make = topo.new_renderer(25)
local function diff(a,b) assert(a ~= b, 'Colores debian variar') end
assert(#make(60,55,55,false,0,false,true)==4)
diff(make(10,10,10,false,0,false,true),make(300,300,300,false,0,false,true))
diff(make(10,10,10,true,5,false,true),make(10,10,10,true,42,false,true))
diff(make(10,10,10,true,5,false,true),make(10,10,10,false,0,true,true))
diff(make(52,52,52,false,0,false,true),make(52,22,22,false,0,false,true))
diff(make(50,50,50,false,0,false,true),make(50,24,24,false,0,false,true))
assert(make(20,0,0,false,0,false,false) == string.char(55,63,70,255))

local names={ [0]='air',[1]='ignore',[2]='default:stone',[3]='default:leaves',
    [4]='default:water_source',[5]='default:lava_source' }
local ids={}
for id,n in pairs(names) do ids[n]=id end
local defs={
 ['default:stone']={groups={cracky=1}},
 ['default:leaves']={groups={leaves=1}},
 ['default:water_source']={groups={water=1},drawtype='liquid'},
 ['default:lava_source']={groups={lava=1},drawtype='liquid'},
}
local outputs, reads={},{count=0}
_G.vector={new=function(x,y,z)return{x=x,y=y,z=z}end}
_G.VoxelArea={}
function VoxelArea:new(t)
    local nx=t.MaxEdge.x-t.MinEdge.x+1
    local ny=t.MaxEdge.y-t.MinEdge.y+1
    return setmetatable({xmin=t.MinEdge.x,ymin=t.MinEdge.y,zmin=t.MinEdge.z,
        ystride=nx,zstride=nx*ny}, {__index={
        index=function(self,x,y,z)
            return (z-self.zmin)*self.zstride+(y-self.ymin)*self.ystride+(x-self.xmin)+1
        end}})
end
local settings={
    get=function(_,key)
        if key=='adm_scan_mode' then return 'balanced' end
        if key=='adm_stripe_rows' then return '16' end
        if key=='adm_topo_contour_interval' then return '25' end
        return nil
    end,
    get_bool=function(_,key,default)
        if key=='adm_profile_tiles' then return false end
        if key=='adm_lazy_media' then return true end
        return default
    end,
}
local function voxel_id(x,y,z)
    local h=5+((x+3*z)%8)
    if y>h+1 then return 0 end
    if y==h+1 and (x+z)%3==0 then return 3 end
    if y>h then return 0 end
    if (x+z)%5==0 and y>h-4 then return 4 end
    if (x+z)%9==0 and y>h-2 then return 5 end
    if y<h-7 and y>h-11 then return 0 end
    return 2
end
_G.minetest={
    settings=settings,registered_nodes=defs,
    get_us_time=function() return 100000 end,
    get_content_id=function(n) return assert(ids[n]) end,
    get_name_from_content_id=function(id)return assert(names[id])end,
    get_voxel_manip=function()
        local vm={}
        function vm:read_from_map(p1,p2)
            self.low=p1;self.high=p2;reads.count=reads.count+1;return p1,p2
        end
        function vm:get_data(buffer)
            local i=0
            for z=self.low.z,self.high.z do
                for y=self.low.y,self.high.y do
                    for x=self.low.x,self.high.x do
                        i=i+1;buffer[i]=voxel_id(x,y,z)
                    end
                end
            end
            return buffer
        end
        function vm:close()end
        return vm
    end,
    after=function(delay,cb) if delay<50 then cb() end end,
    safe_file_write=function(path,data) outputs[path]=data;return true end,
    encode_png=function(w,h,bytes)
        assert(#bytes==w*h*4, 'PNG RGBA incompleto')
        return bytes
    end,
    log=function()end,
    dynamic_add_media=function()end,
}
local P={
    topo_enabled=true,topo_renderer=topo, tile_size=8,
    min_height=-40,max_height=64,cave_scan_depth=32,cave_min_height=3,
    tile_versions={},map_path='mem/',generation={default_color_r=100,
    default_color_g=100,default_color_b=100,alpha_value=255},
}
local base_name=function(x,z)return 'tile_'..x..'_'..z end
local exists=function(name)return outputs['mem/'..name..'.png']~=nil end
local renderer=assert(loadfile(root..'/map_engine_progressive.lua'))()(P,
    base_name,exists,function(n)
        if n=='default:water_source' then return{20,100,205}end
        if n=='default:lava_source' then return{235,80,20}end
        if n=='default:leaves' then return{20,150,25}end
        return {100,105,111}
    end,'mem/')
local called=0
renderer(0,0,function()called=called+1 end)
assert(called==1,'No finalizo el cuadrante clasico')
assert(outputs['mem/tile_0_0.png'] and outputs['mem/tile_0_0_relief.png']
  and outputs['mem/tile_0_0_cave.png'],'Falta alguna capa clasica')
assert(outputs['mem/tile_0_0_topo1.png']==nil,'Generacion no era lazy')
local old_std=outputs['mem/tile_0_0.png']
local old_rel=outputs['mem/tile_0_0_relief.png']
local old_cave=outputs['mem/tile_0_0_cave.png']
local read_before=reads.count
assert(P.request_topo_tile(0,0),'No se solicito topografia')
assert(outputs['mem/tile_0_0_topo1.png'],'No se genero la cuarta capa')
assert(reads.count>read_before,'No se realizo la generacion bajo demanda')
assert(outputs['mem/tile_0_0.png']==old_std and
       outputs['mem/tile_0_0_relief.png']==old_rel and
       outputs['mem/tile_0_0_cave.png']==old_cave,'Se sobrescribieron capas clasicas')
local read_after=reads.count
assert(P.request_topo_tile(0,0),'No se reconocio topo existente')
assert(reads.count==read_after,'La capa se recalculo innecesariamente')
print('OK P7-B1: 4a capa bajo demanda; 3 capas intactas; PNG cacheado; batimetria ligera; sombra y contornos')
