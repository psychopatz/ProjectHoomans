-- Reuse the real deterministic inventory bootstrap and its Kahlua checks.
dofile("tests/pnc_seed_delta_smoke.lua")

local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function approximateBytes(value, seen)
    local kind = type(value)
    local total = 0
    if kind == "nil" then return 0 end
    if kind == "boolean" then return 1 end
    if kind == "number" then return #tostring(value) end
    if kind == "string" then return #value end
    if kind ~= "table" then return 0 end
    seen = seen or {}
    if seen[value] then error("persistence payload contains a cycle") end
    seen[value] = true
    for key, item in pairs(value) do
        total = total + approximateBytes(key, seen)
            + approximateBytes(item, seen) + 2
    end
    seen[value] = nil
    return total
end

PNC.Const.PERSISTENCE_VERSION = 10
PNC.Const.DEFAULT_HP_MAX = 100
PNC.Const.ROAM_DEFAULT_RADIUS = 6
PNC.Const.ROAM_TARGET_RADIUS = 12
PNC.Const.ROAM_REACHED_DISTANCE = 1
PNC.Const.ROAM_PAUSE_MIN_MS = 2500
PNC.Const.ROAM_PAUSE_MAX_MS = 7000
PNC.Const.PRESENCE_ABSTRACT = "abstract"
PNC.Const.PRESENCE_CORPSE = "corpse"
PNC.Const.ORDER_PATROL = "patrol"
PNC.Const.ORDER_TRAVEL = "travel"
PNC.Const.TRAVEL_SCHEMA_VERSION = 1
PNC.Const.TRAVEL_ROUTE_MAX_POINTS = 128
PNC.Const.TRAVEL_METADATA_MAX_DEPTH = 3
PNC.Const.TRAVEL_METADATA_MAX_ENTRIES = 64
PNC.Const.TRAVEL_SPEED_WALK_TILES_PER_HOUR = 300
PNC.Const.TRAVEL_SPEED_RUN_TILES_PER_HOUR = 480
PNC.Const.TRAVEL_SPEED_VEHICLE_TILES_PER_HOUR = 1500
PNC.Const.TRAVEL_ARRIVAL_RADIUS = 1
PNC.Const.MAP_PRESENTATION_MAX_KNOWN_PLAYERS = 64
PNC.Const.MAP_PRESENTATION_ROLE_MAX_LENGTH = 32
PNC.Const.MAP_PRESENTATION_ICON_MAX_LENGTH = 64

PNC.Core.Clamp = function(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end
PNC.Core.Now = function() return 1000 end
PNC.Identity.ApplyRecordIdentity = function(record, definition)
    record.identity = PNC.Core.DeepCopy(definition.identity or record.identity or {})
    record.identitySeed = definition.identitySeed or record.identitySeed
    record.archetypeID = definition.archetypeID or record.archetypeID
    record.name = definition.displayName or definition.name or record.name
end
PNC.Types = {
    NewRecord = function(definition)
        return {
            id = tostring(definition.id),
            name = definition.displayName or definition.name,
            faction = definition.faction or "neutral",
            x = definition.x or 0,
            y = definition.y or 0,
            z = definition.z or 0,
            anchorX = definition.anchorX or definition.x or 0,
            anchorY = definition.anchorY or definition.y or 0,
            anchorZ = definition.anchorZ or definition.z or 0,
            ownerUsername = definition.ownerUsername,
            identitySeed = definition.identitySeed,
            archetypeID = definition.archetypeID,
            weaponMode = definition.weaponMode or "melee",
            attackType = definition.attackType or "auto",
            equipmentPoolID = definition.equipmentPoolID or "Default",
            equipment = definition.equipment or {
                worn = {},
                attached = {},
            },
            patrolPoints = {},
            health = {
                current = 100,
                max = 100,
                state = "normal",
                body = { wounds = {}, parts = {} },
            },
            persist = definition.persist ~= false,
            alive = true,
            runtime = {},
            mapPresentation = PNC.MapPresentation
                and PNC.MapPresentation.Normalize(definition.mapPresentation)
                or nil,
        }
    end,
}

dofile(ROOT .. "Map/PNC_MapPresentation.lua")
dofile(ROOT .. "Travel/PNC_Travel_Route.lua")
dofile(ROOT .. "Travel/PNC_Travel_Providers.lua")
dofile(ROOT .. "Travel/PNC_Travel_Model.lua")

dofile(ROOT .. "Persistence/PNC_Persistence.lua")

local records = {}
local payloads = {}
local totalBytes = 0
local partIDs = {
    "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin",
    "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R",
    "Hand_L", "Hand_R", "UpperLeg_L", "UpperLeg_R",
    "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R",
}

for npcIndex = 1, 100 do
    local id = "scale_npc_" .. tostring(npcIndex)
    local record = {
        id = id,
        name = "Scale NPC " .. tostring(npcIndex),
        identitySeed = 1000 + npcIndex,
        identity = {
            seed = 1000 + npcIndex,
            displayName = "Scale NPC " .. tostring(npcIndex),
            survivor = {},
        },
        archetypeID = "Test",
        faction = "neutral",
        x = npcIndex,
        y = npcIndex * 2,
        z = 0,
        anchorX = npcIndex,
        anchorY = npcIndex * 2,
        anchorZ = 0,
        weaponMode = "melee",
        attackType = "auto",
        equipmentPoolID = "Default",
        equipment = { worn = {}, attached = {} },
        progression = {
            skillLevelDeltas = {},
            skillXP = {},
        },
        health = {
            current = 90,
            max = 100,
            state = "normal",
            body = {
                wounds = {
                    Head = {
                        partId = "Head",
                        type = "scratch",
                        severity = 4,
                        damage = 4,
                        bleedingRate = 0.018,
                    },
                },
                parts = {},
            },
        },
        persist = true,
        alive = true,
        recruited = false,
        runtime = {},
        mapPresentation = {
            visibility = "known",
            knownBy = { scale_player = true },
            roleTag = "trader",
            iconID = "trader",
        },
    }
    for partIndex = 1, #partIDs do
        record.health.body.parts[partIDs[partIndex]] = {
            current = partIDs[partIndex] == "Head" and 70 or 92,
            max = 100,
        }
    end
    PNC.Inventory.CreateFromTemplate(record)
    record.travel = PNC.Travel.Model.New(record, {
        journeyId = "journey:scale:" .. tostring(npcIndex),
        ownerMod = "ScaleFixture",
        ownerRef = "mission:" .. tostring(npcIndex),
        destination = {
            x = npcIndex + 300,
            y = npcIndex * 2,
            z = 0,
        },
        durationWorldHours = 1,
        metadata = { purpose = "scale_test" },
    }, 10)
    local acquired = {}
    for itemIndex = 1, 40 do
        acquired[itemIndex] = {
            type = itemIndex % 2 == 0
                and "Base.Bandage" or "Base.CustomLoot",
            stack = 1,
            itemState = {
                quality = itemIndex % 5,
                modData = {
                    source = "scale",
                    serial = itemIndex,
                },
            },
        }
    end
    assert(PNC.Inventory.AddItems(
        record,
        acquired,
        "root",
        "scale_fixture"
    ))
    records[id] = record
    payloads[id] = PNC.Persistence.SerializeRecord(record)
    totalBytes = totalBytes + approximateBytes(payloads[id])
end

assertEqual(PNC.Core.TableSize and PNC.Core.TableSize(payloads) or 100, 100,
    "scale payload count")
local sample = payloads.scale_npc_1
assertEqual(sample.schemaVersion, 10, "scale schema version")
assertEqual(sample.inventory.maxWeight, nil, "derived max weight persisted")
assertEqual(sample.inventory.cachedWeight, nil, "derived used weight persisted")
assertEqual(#sample.inventory.delta.added, 40, "acquired item delta count")
assertEqual(sample.health.body.partBase, 92, "body-part baseline")
assertEqual(sample.health.body.parts.Head, 70, "body-part override")
assertEqual(sample.runtime, nil, "runtime state leaked into save")
assertEqual(sample.travel.ownerMod, "ScaleFixture", "travel owner persisted")
assertEqual(sample.travel.route.points[2].x, 301, "travel route persisted")
assert(totalBytes < 5 * 1024 * 1024,
    "100-NPC fixture exceeded the 5 MiB compact-save budget: "
        .. tostring(totalBytes))

local restored = PNC.Persistence.DeserializeRecord(sample, "scale_npc_1")
assertEqual(restored.health.body.parts.Head.current, 70,
    "compact health override round trip")
assertEqual(restored.health.body.parts.Neck.current, 92,
    "compact health baseline round trip")
assertEqual(restored.travel.journeyId, "journey:scale:1",
    "journey id round trip")
assertEqual(restored.orderSpec.kind, "travel",
    "active journey order round trip")
assertEqual(restored.mapPresentation.roleTag, "trader",
    "map role round trip")
assertEqual(restored.mapPresentation.knownBy.scale_player, true,
    "map knowledge round trip")

local legacyPayload = PNC.Core.DeepCopy(sample)
legacyPayload.schemaVersion = 9
legacyPayload.inventory.maxWeight = 999
legacyPayload.inventory.cachedWeight = 888
local legacyRecord = PNC.Persistence.DeserializeRecord(
    legacyPayload,
    "scale_npc_1"
)
assertEqual(legacyRecord.inventory, nil, "legacy inventory hydrated during load")
local migratedPayload = PNC.Persistence.SerializeRecord(legacyRecord)
assertEqual(migratedPayload.schemaVersion, 10, "lazy migration schema")
assertEqual(migratedPayload.inventory.maxWeight, nil,
    "legacy derived max weight survived migration")
assertEqual(migratedPayload.inventory.cachedWeight, nil,
    "legacy derived used weight survived migration")

print("pnc_persistence_scale_smoke: ok bytes=" .. tostring(totalBytes))
