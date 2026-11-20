-- Later outfit entries win conflicting slots. The displaced items stay loose.
local Appearance = require 'PNC/Core/Identity/PNC_Identity_Appearance'
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
                if worn and Appearance.WornSlotsConflict(location, worn) then
                    output[previous].wornSlot = nil
                end
            end
        end
        output[#output + 1] = { type = fullType, wornSlot = location, itemState = source.itemState, legacyIndex = index }
    end
    return output
end
return Prepared
