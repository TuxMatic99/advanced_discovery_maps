-- P7B independent test, reads renderer from root.
local root = arg[1] or '.'
local m = assert(loadfile(root..'/map_topography.lua'))()
local render=m.new_renderer(25)
local function different(a,b)assert(a~=b)end
assert(#render(55,53,52,false,0,false,true)==4)
different(render(5,5,5,false,0,false,true),render(200,200,200,false,0,false,true))
different(render(20,20,20,true,3,false,true),render(20,20,20,true,55,false,true))
different(render(20,20,20,false,0,true,true),render(20,20,20,true,10,false,true))
different(render(27,27,27,false,0,false,true),render(27,20,20,false,0,false,true))
assert(render(15,0,0,false,0,false,false)==string.char(55,63,70,255))
print('OK P7-B1: altura, sombras, curvas, agua, lava, valores ausentes')
