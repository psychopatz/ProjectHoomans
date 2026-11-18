-- Prepare a compatible generated wardrobe before creating inventory items.
-- Native WornItems evicts exclusive garments; doing so here keeps UI, stored
-- inventory and the portrait in agreement. Later outfit entries win.
require 'PNC/Core/Identity/PNC_Identity_Appearance'
local Prepared = {}
function Prepared.Build(template)
    local appearance = template.appearance or {}
    local types, specs = appearance.outfitItems or {}, appearance.outfitItemSpecs or {}
    local output = {}
    for index = 1, math.max(#types, #specs) do
        local source = type(specs[index]) == 'table' and specs[index] or {}
        local fullType = source.type or types[index]
        if not fullType then break end
        local location = source.wornSlot
        if PNC.Equipment and PNC.Equipment.CreateItem then
            local native = PNC.Equipment.CreateItem(fullType)
            if type(native) == 'table' and native[1] and not native.getBodyLocation then native = native[1] end
            if native and native.getBodyLocation then location = native:getBodyLocation() or location end
        end
        location = location and tostring(location) or nil
        if location == '' then location = nil end
        if location then
            for previous = #output, 1, -1 do
                local worn = output[previous].wornSlot
                if worn and (worn == location or PNC.Identity.Appearance.AreExclusive(location, worn)
                    or PNC.Identity.Appearance.AreExclusive(worn, location)) then table.remove(output, previous) end
            end
        end
        output[#output + 1] = { type = fullType, wornSlot = location, itemState = source.itemState, legacyIndex = index }
    end
    return output
end
return Prepared
