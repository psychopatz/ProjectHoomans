local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Networking/PNC_Network.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local players = {}
for i = 1, 16 do
    local x = i <= 8 and 0 or 100
    players[i] = {
        getUsername = function() return "player_" .. tostring(i) end,
        getOnlineID = function() return i end,
        getAccessLevel = function() return "" end,
        getX = function() return x end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
end

local sent = {}
sendServerCommand = function(player, module, command, payload)
    sent[#sent + 1] = { player = player, module = module, command = command, payload = payload }
end
isServer = function() return true end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_ROSTER_SYNC_BEGIN = "RosterSyncBegin",
        CMD_ROSTER_SYNC_CHUNK = "RosterSyncChunk",
        CMD_ROSTER_SYNC_END = "RosterSyncEnd",
        CMD_ROSTER_DELTA = "RosterDelta",
        CMD_SYNC_RECORD = "SyncRecord",
        CMD_REMOVE_RECORD = "RemoveRecord",
        CMD_REMOVE_BODY = "RemoveBody",
        CMD_CHARACTER_PAYLOAD = "CharacterPayload",
        CMD_INVENTORY_DELTA = "InventoryDelta",
        CMD_FIREARM_SHOT = "FirearmShot",
        ROSTER_CHUNK_SIZE = 50,
        ROSTER_DELTA_INTERVAL_MS = 10000,
        INTEREST_REFRESH_MS = 1000,
        INTEREST_ENTER_DISTANCE = 48,
        INTEREST_LEAVE_DISTANCE = 56,
        CHARACTER_DETAIL_DISTANCE = 5,
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
        MELEE_RANGE = 1.3,
        RANGED_MIN_STANDOFF = 2.2,
        RANGED_PREFERRED_MIN_DISTANCE = 5,
        RANGED_RANGE = 8.5,
        COMBAT_PRESSURE_RADIUS = 3,
        COMBAT_HORDE_RADIUS = 5.5,
        COMBAT_DEBUG_CONE_RADIUS = 8.5,
        COMBAT_DEBUG_CONE_HALF_ANGLE_DEGREES = 55,
    },
    Core = {
        Now = function() return 2000 end,
        IsAuthority = function() return true end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = PNC.Core.DeepCopy(item) end
            return output
        end,
        ForEachPlayer = function(callback)
            for i = 1, #players do callback(players[i]) end
        end,
    },
    Identity = {
        GetCharacterSummary = function(record)
            return {
                displayName = record.name,
                archetypeID = "Foreman",
                archetypeLabel = "Foreman",
                identitySeed = record.identitySeed,
                isFemale = false,
                survivor = {},
            }
        end,
        BuildPortraitSummary = function(record)
            return {
                identitySeed = record.identitySeed,
                isFemale = false,
                faceOnly = true,
                appearance = { hairModel = "Short" },
                equipment = { worn = { Hat = "Base.Hat_HardHat" } },
            }
        end,
    },
    Equipment = { Describe = function() return { combatModeResolved = "melee", weaponStatus = "ready" } end },
    Inventory = {
        BuildSummaryPayload = function() return { revision = 0, itemCount = 3 } end,
        BuildFullPayload = function() return { summary = { revision = 0 }, items = {}, containers = {} } end,
        BuildDeltaPayload = function() return nil end,
    },
    Skills = {
        BuildSnapshot = function(record)
            assertEqual(type(record), "table", "skills snapshot received non-record")
            return {}
        end,
    },
    Stamina = {
        BuildSnapshot = function(record)
            assertEqual(type(record), "table", "stamina snapshot received non-record")
            return { current = 100, max = 100, state = "fresh" }
        end,
    },
    VisualProfiles = { RollAppearance = function() return {} end },
    MotionHints = {},
    Health = { CanRevive = function() return false end },
    Travel = {
        Model = {
            BuildSummary = function(journey, includeRoute)
                if not journey then return nil end
                return {
                    journeyId = journey.journeyId,
                    state = journey.state,
                    revision = journey.revision,
                    route = includeRoute ~= false and {
                        points = PNC.Core.DeepCopy(journey.route.points),
                    } or nil,
                }
            end,
        },
    },
    MapPresentation = {
        BuildSummary = function(value)
            return PNC.Core.DeepCopy(value or {
                visibility = "all",
                knownBy = {},
                revision = 0,
            })
        end,
    },
}

local nearbyRecord = {
    id = "npc_near",
    name = "Nearby",
    identitySeed = 123,
    faction = "colonist",
    presenceState = "live",
    alive = true,
    recruited = false,
    persist = true,
    x = 1,
    y = 0,
    z = 0,
    health = { current = 100, max = 100, state = "normal" },
    equipment = { worn = {}, attached = {} },
    runtime = {},
    presenceRevision = 1,
    travel = {
        journeyId = "journey:network",
        state = "en_route",
        revision = 1,
        route = {
            points = {
                { x = 1, y = 0, z = 0 },
                { x = 101, y = 0, z = 0 },
            },
        },
    },
    mapPresentation = {
        visibility = "known",
        knownBy = { player_1 = true },
        roleTag = "trader",
        iconID = "trader",
        revision = 2,
    },
}

PNC.SpatialIndex = {
    QueryNPCs = function() return { nearbyRecord } end,
}
local activeDeathMarker
PNC.Registry = {
    Get = function() return nearbyRecord end,
    GetDeathMarker = function(id)
        if activeDeathMarker
            and tostring(activeDeathMarker.id) == tostring(id)
        then
            return activeDeathMarker
        end
        return nil
    end,
}

dofile(FILE)

nearbyRecord.ownerUsername = "player_1"
assertEqual(
    PNC.Network.BuildRosterSnapshot(nearbyRecord).ownerUsername,
    "player_1",
    "roster snapshot owner identity"
)
assertEqual(
    PNC.Network.BuildSnapshot(nearbyRecord).ownerUsername,
    "player_1",
    "detailed snapshot owner identity"
)
assertEqual(
    #PNC.Network.BuildRosterSnapshot(nearbyRecord).travel.route.points,
    2,
    "initial roster omitted travel route"
)
assertEqual(
    PNC.Network.BuildPresenceDelta(nearbyRecord).travel.route,
    nil,
    "high-frequency presence delta repeated travel route"
)
assertEqual(
    PNC.Network.BuildRosterSnapshot(nearbyRecord).mapPresentation.roleTag,
    "trader",
    "roster omitted map presentation"
)
assertEqual(
    PNC.Network.BuildRosterSnapshot(nearbyRecord)
        .portrait.equipment.worn.Hat,
    "Base.Hat_HardHat",
    "roster omitted compact portrait metadata"
)
assertEqual(
    PNC.Network.BuildPresenceDelta(nearbyRecord).mapPresentation,
    nil,
    "high-frequency presence delta repeated map presentation"
)
nearbyRecord.ownerUsername = nil

local deathSnapshot = PNC.Network.BuildDeathMarkerSnapshot({
    id = "dead_colonist",
    name = "Dead Colonist",
    x = 12,
    y = 34,
    z = 0,
    corpseToken = "corpse:12",
    colonist = true,
    infected = false,
    portrait = {
        identitySeed = 88,
        faceOnly = true,
        appearance = { hairModel = "Short" },
        equipment = { worn = {} },
    },
})
assertEqual(deathSnapshot.deathMarker, true, "death marker roster flag")
assertEqual(deathSnapshot.colonist, true, "death marker colonist flag")
assertEqual(deathSnapshot.presenceState, "corpse",
    "death marker roster presence")
assertEqual(deathSnapshot.inventory, nil,
    "death marker snapshot leaked heavyweight inventory")
assertEqual(deathSnapshot.portrait.identitySeed, 88,
    "death marker snapshot omitted compact portrait")

assertEqual(PNC.Network.BuildSnapshot(nearbyRecord).attackMode, false, "idle snapshot attack mode")
nearbyRecord.runtime.target = {
    kind = "zombie",
    zombieId = "z1",
    x = 4,
    y = 0,
    z = 0,
    distSq = 9,
    visible = true,
}
nearbyRecord.runtime.combatTactical = {
    decision = "melee_pressure_retreat",
    pressure = 4,
    visiblePressure = 3,
    horde = 7,
    visibleHorde = 5,
    pressureTolerance = 2,
}
nearbyRecord.runtime.combatRetreat = {
    phase = "retreat",
    reason = "melee_pressure_retreat",
    goalX = -2,
    goalY = 0,
    goalZ = 0,
    goalMode = "run",
    lockUntil = 2300,
}
local combatSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
assertEqual(combatSnapshot.attackMode, true, "combat snapshot attack mode")
assertEqual(
    combatSnapshot.combatDebugState.decision,
    "melee_pressure_retreat",
    "combat tactical decision snapshot"
)
assertEqual(
    combatSnapshot.combatDebugState.visiblePressureCount,
    3,
    "combat visible pressure snapshot"
)
assertEqual(
    combatSnapshot.combatDebugState.target.x,
    4,
    "combat target position snapshot"
)
assertEqual(
    combatSnapshot.combatDebugState.tacticalMove.x,
    -2,
    "combat movement goal snapshot"
)
assertEqual(
    combatSnapshot.combatDebugState.coneHalfAngleDegrees,
    55,
    "combat cone snapshot"
)
nearbyRecord.runtime.combatDebugReplicatedAt = nil
local combatDelta = PNC.Network.BuildPresenceDelta(nearbyRecord)
assertEqual(combatDelta.attackMode, true, "combat delta attack mode")
assertEqual(
    combatDelta.combatDebugState.decision,
    "melee_pressure_retreat",
    "combat decision presence delta"
)
assertEqual(
    PNC.Network.BuildPresenceDelta(nearbyRecord).combatDebugState,
    nil,
    "combat debug presence delta throttle"
)
nearbyRecord.runtime.target = nil
nearbyRecord.runtime.combatTactical = nil
nearbyRecord.runtime.combatRetreat = nil
local idleCombatDelta = PNC.Network.BuildPresenceDelta(nearbyRecord)
assertEqual(
    idleCombatDelta.combatDebugState.target,
    nil,
    "combat debug sends terminal idle transition"
)
assertEqual(
    PNC.Network.BuildPresenceDelta(nearbyRecord).combatDebugState,
    nil,
    "idle combat debug does not repeat"
)

nearbyRecord.runtime.bandageCompletionRevision = 3
nearbyRecord.runtime.bandageCompletionAt = 1999
nearbyRecord.runtime.bandageCompletionPartId = "ForeArm_L"
local bandageSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
assertEqual(bandageSnapshot.bandageFeedback.revision, 3,
    "bandage completion revision snapshot")
assertEqual(bandageSnapshot.bandageFeedback.partId, "ForeArm_L",
    "bandage completion part snapshot")
assertEqual(bandageSnapshot.bandageFeedback.sound, "PNC_BandageComplete",
    "bandage completion sound snapshot")
assertEqual(
    PNC.Network.BuildPresenceDelta(nearbyRecord).bandageFeedback.revision,
    3,
    "bandage completion presence delta"
)
nearbyRecord.runtime.bandageCompletionRevision = nil
nearbyRecord.runtime.bandageCompletionAt = nil
nearbyRecord.runtime.bandageCompletionPartId = nil

nearbyRecord.runtime.vehiclePassenger = {
    active = true,
    vehicleId = "vehicle:7",
    seat = 1,
    ownerOnlineID = 42,
    boardedAt = 1500,
}
local passengerSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
assertEqual(passengerSnapshot.aiState, "VehiclePassenger", "vehicle passenger AI state")
assertEqual(passengerSnapshot.vehiclePassenger.seat, 1, "vehicle seat snapshot")
assertEqual(
    PNC.Network.BuildPresenceDelta(nearbyRecord).vehiclePassenger.vehicleId,
    "vehicle:7",
    "vehicle passenger delta"
)
nearbyRecord.runtime.vehiclePassenger = nil

local roster = {}
for i = 1, 500 do
    roster[i] = { id = "npc_" .. tostring(i), displayName = "NPC " .. tostring(i) }
end
PNC.Network.BroadcastFullSync(players[1], roster)
assertEqual(#sent, 12, "500-record roster packet count")
assertEqual(sent[1].command, "RosterSyncBegin", "roster begin")
assertEqual(sent[12].command, "RosterSyncEnd", "roster end")
for i = 2, 11 do
    assertEqual(#sent[i].payload.snapshots, 50, "roster chunk size")
    assertEqual(sent[i].payload.snapshots[1].inventory, nil, "roster leaked inventory")
end

sent = {}
PNC.Network.RefreshInterestSets(2000)
assertEqual(#sent, 8, "interest-enter recipient count")
sent = {}
PNC.Network.BroadcastRecord(nearbyRecord, "tick")
assertEqual(#sent, 8, "targeted live snapshot recipient count")
assertEqual(sent[1].payload.snapshot.skillLevels, nil, "tick snapshot leaked detailed skills")

nearbyRecord.x = 100
sent = {}
PNC.Network.RefreshInterestSets(4000)
assertEqual(#sent, 16, "interest enter/exit transition count")
sent = {}
PNC.Network.BroadcastRecord(nearbyRecord, "tick")
assertEqual(#sent, 8, "interest recipients did not switch")

nearbyRecord.ownerUsername = "player_16"
nearbyRecord.x = 1
assertEqual(PNC.Network.CanViewCharacter(players[1], nearbyRecord), true, "nearby detail access")
assertEqual(PNC.Network.CanViewCharacter(players[16], nearbyRecord), true, "owner detail access")
nearbyRecord.ownerUsername = nil
assertEqual(PNC.Network.CanViewCharacter(players[16], nearbyRecord), false, "remote detail rejection")

-- Removal deltas carry only an id. The old `true and nil or snapshot()` idiom
-- evaluated snapshot() anyway and sent that id string through stamina/skills.
sent = {}
PNC.Network.BroadcastRemoval("npc_removed", "range_exit")
assertEqual(PNC.Network.FlushRosterDeltas(6000, true), 1, "removal roster delta count")
assertEqual(#sent, 16, "removal roster delta recipients")
assertEqual(sent[1].command, "RosterDelta", "removal roster delta command")
assertEqual(sent[1].payload.entries[1].id, "npc_removed", "removal roster id")
assertEqual(sent[1].payload.entries[1].removed, true, "removal roster marker")
assertEqual(sent[1].payload.entries[1].snapshot, nil, "removal roster leaked snapshot")
assertEqual(PNC.Network.QueueRosterDelta("npc_invalid", false, "invalid"), false, "non-removal accepted id-only record")

activeDeathMarker = {
    id = nearbyRecord.id,
    name = "Nearby Corpse",
    x = nearbyRecord.x,
    y = nearbyRecord.y,
    z = nearbyRecord.z,
    corpseToken = "corpse:nearby",
    colonist = true,
    infected = false,
}
sent = {}
PNC.Network.BroadcastRemoval(nearbyRecord.id, "death")
assertEqual(#sent, 8, "death snapshot interest recipient count")
assertEqual(sent[1].command, "SyncRecord", "death snapshot command")
assertEqual(sent[1].payload.snapshot.deathMarker, true,
    "death event did not use compact marker snapshot")
assertEqual(sent[1].payload.snapshot.inventory, nil,
    "death event leaked heavyweight record data")
sent = {}
assertEqual(PNC.Network.FlushRosterDeltas(7000, true), 1,
    "death marker roster delta count")
assertEqual(#sent, 16, "death marker roster delta recipients")
assertEqual(sent[1].payload.entries[1].removed, false,
    "death marker was sent as a removal")
assertEqual(sent[1].payload.entries[1].snapshot.deathMarker, true,
    "death marker roster delta lost marker metadata")
activeDeathMarker = nil

sent = {}
assertEqual(
    PNC.Network.BroadcastDeathMarkerRemoval(
        nearbyRecord.id,
        "corpse_collected"
    ),
    true,
    "death marker removal broadcast"
)
assertEqual(#sent, 16, "death marker removal was not immediate for all players")
assertEqual(sent[1].command, "RemoveRecord",
    "death marker removal command")
assertEqual(sent[1].payload.reason, "corpse_collected",
    "death marker removal reason")
sent = {}
assertEqual(PNC.Network.FlushRosterDeltas(8000, true), 1,
    "death marker removal roster delta count")
assertEqual(#sent, 16, "death marker removal delta recipients")
assertEqual(sent[1].payload.entries[1].removed, true,
    "death marker removal delta was not terminal")

sent = {}
assertEqual(
    PNC.Network.BroadcastBodyRemoval("npc_near", 707, 77, "startup_uuid"),
    true,
    "body-instance removal broadcast"
)
assertEqual(#sent, 16, "body-instance removal reaches all players")
assertEqual(sent[1].command, "RemoveBody", "body-instance removal command")
assertEqual(sent[1].payload.id, "npc_near", "body-instance removal NPC id")
assertEqual(sent[1].payload.bodyInstanceID, "707", "body-instance removal outfit id")
assertEqual(sent[1].payload.bodyOnlineID, 77, "body-instance removal online id")

sent = {}
assertEqual(PNC.Network.BroadcastFirearmShot({
    shotId = "npc_near:1",
    npcId = "npc_near",
    sx = 0,
    sy = 0,
    sz = 0,
    soundRadius = 60,
}), true, "firearm shot event broadcast")
assertEqual(#sent, 8, "firearm shot distance recipient count")
assertEqual(sent[1].command, "FirearmShot", "firearm shot command")
assertEqual(sent[1].payload.shotId, "npc_near:1", "firearm shot id")

print("pnc_network_scale_smoke: ok")
