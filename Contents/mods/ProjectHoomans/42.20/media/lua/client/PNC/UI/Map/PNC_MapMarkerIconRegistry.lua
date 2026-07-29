-- Client-side marker icon registry. Gameplay systems store only an icon ID;
-- presentation mods decide whether that ID is a glyph or a texture.

PNC = PNC or {}
PNC.MapMarkerIcons = PNC.MapMarkerIcons or {}

local Icons = PNC.MapMarkerIcons

Icons.Definitions = Icons.Definitions or {}

function Icons.Register(iconID, definition)
    iconID = tostring(iconID or "")
    if iconID == "" or type(definition) ~= "table" then return false end
    Icons.Definitions[iconID] = {
        id = iconID,
        glyph = definition.glyph and tostring(definition.glyph) or nil,
        texturePath = definition.texturePath
            and tostring(definition.texturePath) or nil,
        texture = definition.texture,
        size = math.max(6, tonumber(definition.size) or 10),
        color = type(definition.color) == "table"
            and {
                r = tonumber(definition.color.r) or 1,
                g = tonumber(definition.color.g) or 1,
                b = tonumber(definition.color.b) or 1,
                a = tonumber(definition.color.a) or 1,
            }
            or nil,
    }
    return true
end

function Icons.Unregister(iconID)
    iconID = tostring(iconID or "")
    if iconID == "" or Icons.Definitions[iconID] == nil then return false end
    Icons.Definitions[iconID] = nil
    return true
end

function Icons.Resolve(iconID)
    local definition = Icons.Definitions[tostring(iconID or "")]
    if not definition then return nil end
    if not definition.texture
        and definition.texturePath
        and getTexture
    then
        definition.texture = getTexture(definition.texturePath)
    end
    return definition
end

Icons.Register("trader", {
    glyph = "T",
    size = 10,
})
Icons.Register("quest_giver", {
    glyph = "!",
    size = 11,
})
Icons.Register("guard", {
    glyph = "G",
    size = 10,
})
Icons.Register("worker", {
    glyph = "W",
    size = 10,
})

return Icons
