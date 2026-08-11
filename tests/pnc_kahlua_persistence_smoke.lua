local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"

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
                equipmentSpawnMode = definition.equipmentSpawnMode,
                equipmentPoolID = definition.equipmentPoolID,
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

PNC.NeedsDefinitions = {}
dofile(ROOT .. "Needs/PNC_PlayerNeedsModel.lua")

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
    faction = "colonist",
    x = 1,
    y = 2,
    z = 0,
    anchorX = 1,
    anchorY = 2,
    anchorZ = 0,
    health = {
        current = 90,
        max = 100,
        state = "normal",
        body = {
            parts = {
                ForeArm_L = { current = 76, max = 100 },
                Head = { current = 88.75, max = 100 },
            },
            wounds = {
                ForeArm_L = {
                    partId = "ForeArm_L",
                    type = "bite",
                    severity = 12,
                    bleedingRate = 0.085,
                    bandaged = true,
                    bandagedAt = 900,
                    healAtWorldHour = 20,
                },
            },
            infection = {
                active = true,
                fatal = false,
                sourcePart = "ForeArm_L",
                infectedAtWorldHour = 10,
                fatalAtWorldHour = 58,
                progress = 0.5,
                stage = "nauseous",
                fever = 11.1,
                temperatureC = 37.4,
                lastUpdatedWorldHour = 34,
            },
            bleedingRate = 0,
            openWoundCount = 0,
            bandagedWoundCount = 1,
            lastBleedAt = 900,
        },
    },
    weaponMode = "melee",
    equipmentSpawnMode = "ranged",
    equipmentPoolID = "Default",
    equipment = { worn = {}, attached = {} },
    progression = { skillLevels = { Strength = 5 }, skillXP = {} },
    persistedInventory = { revision = 0 },
    liveBodyInstanceID = 9191,
    liveBodyOnlineID = 91,
    runtime = {
        bodyLease = "lease-persisted",
    },
    generation = { source = "WORLD_POPULATION_DIRECTOR",
        generationId = "POP_GROUP_0000042", sectorId = "psector_1_2",
        createdAt = 34, seed = 42 },
    vanillaTraits = { "Base.HighThirst", "Overweight" },
    vanillaTraitsAuthored = true,
}

local payload = PNC.Persistence.SerializeRecord(record)
assert(payload, "serialization failed without next()")
assert(payload.progression.skillLevelDeltas.Strength == 3, "legacy skill delta conversion failed")
assert(payload.health.body.wounds.ForeArm_L, "body wound was not serialized")
assert(payload.health.body.infection.active == true, "infection was not serialized")
assert(payload.health.body.infection.stage == "nauseous", "infection stage was not serialized")
assert(payload.health.body.parts.ForeArm_L == 76,
    "body-part health was not compacted")
assert(payload.health.lastDamageAt == nil,
    "transient damage timestamp was persisted")
assert(payload.equipmentSpawnMode == "ranged", "equipment spawn override was not serialized")
assert(payload.equipmentPoolID == "Default", "equipment pool was not serialized")
assert(payload.bodyHint.instanceID == 9191, "live body instance hint was not serialized")
assert(payload.bodyHint.lease == "lease-persisted", "live body lease hint was not serialized")
assert(payload.generation.generationId == "POP_GROUP_0000042",
    "population provenance was not serialized")
assert(payload.vanillaTraits.highthirst == true,
    "vanilla physiological trait was not serialized")
assert(payload.vanillaTraits.overweight == true,
    "vanilla weight trait was not serialized")
assert(payload.vanillaTraitsAuthored == true,
    "authored trait source was not serialized")

local restored = PNC.Persistence.DeserializeRecord(payload, record.id)
assert(restored, "deserialization failed without next()")
assert(restored.progression.skillLevelDeltas.Strength == 3, "deserialized skill delta changed")
assert(restored.health.body.wounds.ForeArm_L.type == "bite", "body wound did not round trip")
assert(restored.health.body.infection.sourcePart == "ForeArm_L", "infection did not round trip")
assert(restored.health.body.infection.progress == 0.5, "infection progress did not round trip")
assert(restored.health.body.infection.stage == "nauseous", "infection stage did not round trip")
assert(restored.health.body.infection.temperatureC == 37.4, "infection fever did not round trip")
assert(restored.health.body.parts.ForeArm_L.current == 76, "body-part health did not round trip")
assert(restored.health.body.lastBleedAt == 0, "wall clock bleed timestamp was persisted")
assert(restored.equipmentSpawnMode == "ranged", "equipment spawn override did not round trip")
assert(restored.equipmentPoolID == "Default", "equipment pool did not round trip")
assert(restored.runtime.startupBodyHint.instanceID == "9191",
    "startup body instance hint did not round trip")
assert(restored.runtime.startupBodyHint.lease == "lease-persisted",
    "startup body lease hint did not round trip")
assert(restored.generation.generationId == "POP_GROUP_0000042",
    "population provenance did not round trip")
assert(restored.vanillaTraits.highthirst == true,
    "vanilla physiological trait did not round trip")
assert(restored.vanillaTraits.overweight == true,
    "vanilla weight trait did not round trip")
assert(restored.vanillaTraitsAuthored == true,
    "authored trait source did not round trip")

next = originalNext
print("pnc_kahlua_persistence_smoke: ok")
