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

local nativeLocations = {
    ["base:torso1"] = { id = "Torso1" },
    ["base:legs1"] = { id = "Legs1" },
}
local exclusivityCalls = {}

ResourceLocation = {
    of = function(value)
        local raw = tostring(value or "")
        if not string.find(raw, ":", 1, true) then
            raw = "base:" .. raw
        end
        return { id = string.lower(raw) }
    end,
}
ItemBodyLocation = {
    get = function(resource)
        return nativeLocations[resource and resource.id]
    end,
}
BodyLocations = {
    getGroup = function()
        return {
            isExclusive = function(_, first, second)
                exclusivityCalls[#exclusivityCalls + 1] = {
                    first = first,
                    second = second,
                }
                T.equal(type(first), "table",
                    "appearance exclusivity received a non-native first slot")
                T.equal(type(second), "table",
                    "appearance exclusivity received a non-native second slot")
                return false
            end,
        }
    end,
}

PNC = {
    Core = { DeepCopy = deepCopy },
    Identity = {},
    Equipment = {
        CreateItem = function(fullType)
            local locations = {
                ["Base.Shirt"] = "Torso",
                ["Base.ShirtNative"] = "Torso1",
                ["Base.TrousersNative"] = "Legs1",
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
T.equal(Appearance.Normalize({
    outfit = { mode = "item", id = "Police" },
}).outfit.id, "Police", "canonical outfit normalizes to a named preset")

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
        }
    end,
}
T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity_Profile.lua")
PNC.Identity.GetCoreArchetypePlan = function(record)
    return {
        archetypeID = record.archetypeID,
        appearance = namedWithExactSlot,
        appearanceItems = { "Base.Hat" },
        spawnOutfit = { male = "Police", female = "Police" },
    }
end
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

local cyclicRecord = {
    id = "npc_cyclic_runtime",
    displayName = "Cyclic Runtime",
    isFemale = false,
    archetypeID = "General",
    identitySeed = 2,
    identity = { survivor = {} },
    runtime = {
        localNavigation = { provider = "engine_path" },
    },
}
cyclicRecord.runtime.localNavigation.record = cyclicRecord
local cyclicAppearance = PNC.Identity.RollAppearance(cyclicRecord)
T.truthy(cyclicAppearance, "cyclic live record appearance resolved")
T.equal(cyclicRecord.runtime.localNavigation.record, cyclicRecord,
    "appearance resolution preserved live navigation back-reference")

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

local legacyAliases = Appearance.Normalize({
    outfit = { mode = "none" },
    slots = {
        Torso = {
            mode = "item",
            type = "Base.ShirtNative",
            wornSlot = "Torso_Upper",
        },
        Legs = {
            mode = "item",
            type = "Base.TrousersNative",
            wornSlot = "Legs",
        },
    },
})
T.truthy(Appearance.Validate(legacyAliases),
    "legacy aliases validate through native item metadata")
T.equal(#exclusivityCalls, 1,
    "legacy aliases did not perform one native exclusivity check")

local unresolvedAlias = Appearance.Normalize({
    outfit = { mode = "none" },
    slots = {
        Unknown = {
            mode = "item",
            type = "Base.UnknownClothing",
            wornSlot = "Torso_Upper",
        },
        Legs = {
            mode = "item",
            type = "Base.TrousersNative",
            wornSlot = "Legs",
        },
    },
})
local callsBeforeUnresolved = #exclusivityCalls
T.truthy(Appearance.Validate(unresolvedAlias),
    "unresolved aliases fail safely without native slot validation")
T.equal(#exclusivityCalls, callsBeforeUnresolved,
    "unresolved alias crossed the native exclusivity boundary")
T.equal(Appearance.Signature(normalized), Appearance.Signature(normalized),
    "appearance signature is stable")
T.finish("pnc_unique_npc_appearance_smoke")
