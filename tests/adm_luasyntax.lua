local root = arg[1] or '.'
local paths = {'init.lua', 'map_engine_progressive.lua', 'map_ui_modern.lua',
    'map_walk.lua','map_media.lua','biome_sensor.lua',
    'map-party.lua','map-party-gui.lua','marker-gui.lua','marker-share.lua',
    'nodecolors.lua','cave-profile.lua'}
for _,p in ipairs(paths) do
    local f,err=loadfile(root..'/'..p)
    assert(f, p..': '..tostring(err))
end
print('OK: sintaxis de '..#paths..' modulos Lua')
