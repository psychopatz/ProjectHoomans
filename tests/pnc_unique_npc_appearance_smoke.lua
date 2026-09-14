local T = require "tests/support/test"

local function deepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[deepCopy(key, seen)] = deepCopy(child, seen)
    end
    return output
end

PNC = {
    Core = { DeepCopy = deepCopy },
    Identity = {},
    Equipment = {
        CreateItem = function(fullType)
            local locations = {
                ["Base.Shirt"] = "Torso",
                ["Base.Hat"] = "Hat",
                ["Base.Glasses"] = "Eyes",
            }
            return {
                getBodyLocation = function()
                    return locations[fullType]
                end,
            }
        end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity_Appearance.lua")

local Appearance = PNC.Identity.Appearance
local normalized = Appearance.Normalize({
    outfit = { mode = "none" },
    slots = {
        Torso = {
            mode = "item",
            type = "Base.Shirt",
            wornSlot = "Torso",
            itemState = { visualTextureChoice = 3 },
        },
        Hat = { mode = "none" },
    },
})
T.equal(normalized.outfit.mode, "none", "none outfit is explicit")
T.equal(normalized.slots.Torso.itemState.visualTextureChoice, 3,
    "appearance preserves item visual state")
T.equal(Appearance.Normalize({ outfit = "Police" }).outfit.id, "Police",
    "legacy string outfit normalizes to a named preset")

local resolved = Appearance.Resolve({ appearance = normalized }, {
    "Base.Shirt", "Base.Hat", "Base.Glasses",
})
T.equal(#resolved.itemSpecs, 1, "none removes inherited clothing")
T.equal(resolved.itemSpecs[1].type, "Base.Shirt",
    "selected clothing survives resolution")
T.equal(resolved.itemSpecs[1].itemState.visualTextureChoice, 3,
    "selected visual metadata reaches inventory template")

local namedWithExactSlot = Appearance.Normalize({
    outfit = { mode = "item", id = "CostumeFrogman" },
    slots = {
        Torso = {
            mode = "item",
            type = "Base.Shirt",
            wornSlot = "Torso",
        },
    },
})
T.truthy(Appearance.HasExplicitSlots(namedWithExactSlot),
    "exact clothing slots are authoritative")
local namedResolved = Appearance.Resolve({ appearance = namedWithExactSlot }, {
    "Base.Hat",
})
T.equal(#namedResolved.itemSpecs, 1,
    "named outfit does not add archetype clothing to exact slots")
T.equal(namedResolved.itemSpecs[1].type, "Base.Shirt",
    "exact clothing remains the only resolved slot item")

PNC.Identity.Index = function() return 1 end
PNC.Identity.NormalizeSeed = function(value) return tonumber(value) or 1 end
PNC.Identity.ResolveArchetypeID = function(source)
    return source and source.archetypeID or "General"
end
PNC.Identity.ApplyRecordIdentity = function(record)
    record.identity = record.identity or { survivor = {} }
    record.identity.survivor = record.identity.survivor or {}
    record.identity.displayName = record.displayName
    record.identity.isFemale = record.isFemale == true
    record.identitySeed = tonumber(record.identitySeed) or 1
    record.archetypeID = record.archetypeID or "General"
    return record
end
PNC.Archetypes = {
    Get = function(id)
        return {
            id = tostring(id or "General"),
            label = "General",
            looks = {
                male = { "Base.Hat" },
                female = { "Base.Hat" },
                spawnOutfit = { male = "Police", female = "Police" },
            },
        }
    end,
}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity_Profile.lua")
local rolledExact = PNC.Identity.RollAppearance({
    id = "npc_exact",
    displayName = "Exact Person",
    isFemale = false,
    archetypeID = "General",
    identitySeed = 1,
    identity = { survivor = {} },
    appearance = namedWithExactSlot,
})
T.equal(rolledExact.outfit, nil,
    "exact appearance suppresses named outfit at runtime")

local random = Appearance.Resolve({
    appearance = Appearance.Normalize({ outfit = { mode = "random" } }),
}, {
    {
        type = "Base.Shirt",
        wornSlot = "Torso",
        itemState = { visualTextureChoice = 7 },
    },
})
T.equal(random.itemSpecs[1].itemState.visualTextureChoice, 7,
    "random policy can reuse captured runtime metadata")
T.truthy(Appearance.Validate(normalized),
    "non-conflicting appearance validates")
T.equal(Appearance.Signature(normalized), Appearance.Signature(normalized),
    "appearance signature is stable")
T.finish("pnc_unique_npc_appearance_smoke")
