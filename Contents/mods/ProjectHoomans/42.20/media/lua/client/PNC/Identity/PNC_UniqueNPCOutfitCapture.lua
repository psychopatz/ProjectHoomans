-- Native outfit capture shared by preview materialization and authored choices.
-- Descriptors use the unregistered constructor; no world NPC is created.
PNC = PNC or {}
PNC.UniqueNPCOutfitCapture = PNC.UniqueNPCOutfitCapture or {}
local Capture = PNC.UniqueNPCOutfitCapture
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, child in pairs(value) do out[key] = copy(child) end
    return out
end

-- Capture one selected native preset once. The unregistered descriptor is
-- preview-only; exact visual state then travels through ordinary slot specs.
function Capture.Capture(id, female)
    if not SurvivorDesc or not SurvivorDesc.new or not PNC.Inventory or not PNC.Inventory.CaptureNativeItem then return nil, "outfit_unavailable" end
    local descriptor = SurvivorDesc.new(false)
    descriptor:setFemale(female == true)
    descriptor:dressInNamedOutfit(id)
    local worn = descriptor:getWornItems()
    local slots, count = {}, 0
    for index = 0, worn:size() - 1 do
        local native = worn:getItemByIndex(index)
        local location = worn:getLocation(native)
        local spec = PNC.Inventory.CaptureNativeItem(native)
        -- Bags remain inventory-owned. Browsing clothing never replaces gear.
        if spec and location and not spec.maxWeight then
            local key = tostring(location)
            PNC.Identity.Appearance.CaptureSlot(slots, key, { mode = "item", type = spec.type, wornSlot = key, itemState = copy(spec.itemState) })
            count = count + 1
        end
    end
    if count == 0 then return nil, "outfit_unavailable" end
    return slots
end

return Capture
