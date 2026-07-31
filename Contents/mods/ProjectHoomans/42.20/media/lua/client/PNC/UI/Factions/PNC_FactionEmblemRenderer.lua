-- Client-only renderer for layered persistent faction emblems.

PNC = PNC or {}
PNC.FactionEmblemRenderer =
    PNC.FactionEmblemRenderer or {}

local Renderer = PNC.FactionEmblemRenderer
local Emblems = PNC.FactionEmblems

Renderer.TextureCache = Renderer.TextureCache or {}

function Renderer.ResolveTexture(symbolID)
    local path = Emblems.GetTexturePath(symbolID)
    if not path then return nil end
    if Renderer.TextureCache[symbolID] == nil then
        Renderer.TextureCache[symbolID] =
            getTexture and getTexture(path) or false
    end
    local texture = Renderer.TextureCache[symbolID]
    return texture ~= false and texture or nil
end

function Renderer.Draw(target, emblem, x, y, size, options)
    if not target or type(emblem) ~= "table" then return false end
    options = type(options) == "table" and options or {}
    size = math.max(8, tonumber(size) or 24)
    local background = Emblems.GetColor(
        emblem.backgroundColorID
    )
    local alpha = tonumber(options.alpha) or 0.96
    if target.drawRect then
        target:drawRect(
            x,
            y,
            size,
            size,
            alpha,
            background.r,
            background.g,
            background.b
        )
    end
    if target.drawRectBorder and options.border ~= false then
        target:drawRectBorder(
            x,
            y,
            size,
            size,
            math.min(1, alpha + 0.04),
            0.05,
            0.05,
            0.05
        )
    end
    local index
    for index = 1, math.min(
        #(emblem.layers or {}),
        Emblems.MAX_LAYERS
    ) do
        local layer = emblem.layers[index]
        local texture = Renderer.ResolveTexture(
            layer and layer.symbolID
        )
        local color = Emblems.GetColor(
            layer and layer.colorID
        )
        local layerSize = size
            * math.max(
                0.2,
                math.min(1, tonumber(layer and layer.scale) or 0.75)
            )
        local offsetX = size
            * math.max(
                -0.35,
                math.min(0.35, tonumber(
                    layer and layer.offsetX
                ) or 0)
            )
        local offsetY = size
            * math.max(
                -0.35,
                math.min(0.35, tonumber(
                    layer and layer.offsetY
                ) or 0)
            )
        if texture and target.drawTextureScaledAspect then
            target:drawTextureScaledAspect(
                texture,
                x + (size - layerSize) / 2 + offsetX,
                y + (size - layerSize) / 2 + offsetY,
                layerSize,
                layerSize,
                alpha,
                color.r,
                color.g,
                color.b
            )
        end
    end
    return true
end

return Renderer
