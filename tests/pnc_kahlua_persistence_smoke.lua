local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function deepCopy(value)
    local output
    local key
    local item
    if type(value) ~= "table" then
        return value
    end
    output = {}
    for key, item in pairs(value) do
        output[key] = deepCopy(item)
    end
    return output
end

PNC = {
    Const = {
        PERSISTENCE_VERSION = 5,
        DEFAULT_HP_MAX = 100,
        ROAM_DEFAULT_RADIUS = 10,
        ROAM_TARGET_RADIUS = 2,
        ROAM_REACHED_DISTANCE = 0.75,
        ROAM_PAUSE_MIN_MS = 500,
        ROAM_PAUSE_MAX_MS = 1000,
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
    },
    Core = {
        DeepCopy = deepCopy,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
        Now = function() return 1000 end,
    },
    Identity = {
        NormalizeSeed = function(seed) return tonumber(seed) or 1 end,
        ApplyRecordIdentity = function(record, definition)
            record.identity = deepCopy(definition.identity or {})
            record.identitySeed = definition.identitySeed
            record.archetypeID = definition.archetypeID
            record.name = definition.displayName or definition.name
            record.isFemale = definition.isFemale == true
        end,
    },
    Skills = {
        GetBaseLevel = function(_, skillID)
            return skillID == "Strength" and 2 or 0
        end,
    },
    Types = {
        NewRecord = function(definition)
            return {
                id = tostring(definition.id),
                x = definition.x or 0,
                y = definition.y or 0,
                z = definition.z or 0,
                anchorX = definition.anchorX or definition.x or 0,
                anchorY = definition.anchorY or definition.y or 0,
                anchorZ = definition.anchorZ or definition.z or 0,
                ownerUsername = definition.ownerUsername,
                weaponMode = definition.weaponMode or "melee",
                patrolPoints = {},
                equipment = definition.equipment or { worn = {}, attached = {} },
                health = { current = 100, max = 100, state = "normal" },
                recruited = definition.recruited == true,
                persist = definition.persist ~= false,
                alive = true,
            }
        end,
    },
}

local originalNext = next
next = nil
dofile(ROOT .. "Persistence/PNC_Persistence.lua")

local record = {
    id = "npc_kahlua",
    persist = true,
    recordRevision = 3,
    identitySeed = 42,
    identity = { seed = 42, displayName = "Kahlua Test", survivor = {} },
    name = "Kahlua Test",
    faction = "companion",
    x = 1,
    y = 2,
    z = 0,
    anchorX = 1,
    anchorY = 2,
    anchorZ = 0,
    health = { current = 90, max = 100, state = "normal" },
    weaponMode = "melee",
    equipment = { worn = {}, attached = {} },
    progression = { skillLevels = { Strength = 5 }, skillXP = {} },
    persistedInventory = { revision = 0 },
}

local payload = PNC.Persistence.SerializeRecord(record)
assert(payload, "serialization failed without next()")
assert(payload.progression.skillLevelDeltas.Strength == 3, "legacy skill delta conversion failed")

local restored = PNC.Persistence.DeserializeRecord(payload, record.id)
assert(restored, "deserialization failed without next()")
assert(restored.progression.skillLevelDeltas.Strength == 3, "deserialized skill delta changed")

next = originalNext
print("pnc_kahlua_persistence_smoke: ok")
