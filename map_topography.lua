-- Advanced Discovery Maps P7-B1: topografia sombreada opcional.
-- Sin lecturas de VoxelManip, sin estado global, compatible con Lua 5.1.
-- El mapa clasico permanece intocable; los nuevos PNG usan sufijo _topo1.
local floor, min, max = math.floor, math.min, math.max
local char = string.char

local land_palette = {
    {-192, 56, 66, 77},
    {0,    88, 129, 98},
    {40,  146, 174, 103},
    {90,  207, 197, 130},
    {180, 171, 125, 85},
    {300, 222, 222, 208},
    {500, 244, 246, 247},
}

local function bound(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

local function land_base(height)
    local first = land_palette[1]
    if height <= first[1] then return first[2],first[3],first[4] end
    for i = 2, #land_palette do
        local high = land_palette[i]
        if height <= high[1] then
            local low = land_palette[i-1]
            local t = (height-low[1])/(high[1]-low[1])
            return floor(low[2]+(high[2]-low[2])*t+.5),
                floor(low[3]+(high[3]-low[3])*t+.5),
                floor(low[4]+(high[4]-low[4])*t+.5)
        end
    end
    local last=land_palette[#land_palette]
    return last[2],last[3],last[4]
end

-- Crea un renderizador por cuadrante. El cache se descarta al terminar.
local function new_renderer(interval)
    interval = tonumber(interval) or 25
    interval = bound(floor(interval), 5, 100)
    local palette_cache = {}
    local function shade(height, north, west, water, depth, lava, valid)
        if valid == false then return char(55,63,70,255) end
        height = floor(tonumber(height) or 0)
        local r,g,b
        if water then
            depth = bound(tonumber(depth) or 0, 0, 80)
            local t = bound(depth / 48, 0, 1)
            r = floor(48-38*t+.5)
            g = floor(185-126*t+.5)
            b = floor(205-86*t+.5)
        elseif lava then
            r,g,b = 241,100,36
        else
            local c = palette_cache[height]
            if not c then
                local cr,cg,cb = land_base(height)
                c = {cr,cg,cb}
                palette_cache[height] = c
            end
            r,g,b=c[1],c[2],c[3]
        end

        -- Luz del noroeste: pendientes suaves, sin trigonometria por pixel.
        if north ~= nil and west ~= nil then
            local dn = bound(height-north, -18, 18)
            local dw = bound(height-west, -18, 18)
            local illumination = bound(1 + (dw + dn)*0.017, 0.72, 1.23)
            r,g,b = r*illumination, g*illumination, b*illumination
            if not water and not lava then
                -- Las curvas se dibujan cuando cruzan un intervalo entre celdas.
                local band = floor(height/interval)
                if band ~= floor(north/interval) or band ~= floor(west/interval) then
                    local major = floor(height/100) ~= floor(north/100)
                        or floor(height/100) ~= floor(west/100)
                    local strength = major and 0.59 or 0.78
                    r,g,b = r*strength,g*strength,b*strength
                end
            elseif water then
                local band = floor(bound(depth or 0, 0, 80)/10)
                -- La batimetria completa sera una capa separada en P7-C.
                if band > 0 and band % 2 == 0 then
                    r,g,b = r*0.98,g*0.98,b*0.98
                end
            end
        end
        return char(bound(floor(r+.5),0,255),bound(floor(g+.5),0,255),
                    bound(floor(b+.5),0,255),255)
    end
    return shade
end

return {new_renderer=new_renderer}
