local T = require "tests/support/test"

local SHARED_ROOT = T.path("ProjectHoomans", "shared", "")
T.addPackagePaths()

local FILE = T.path("ProjectHoomans", "shared", "PNC/Core/Networking/PNC_Network.lua")

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
local debugVisibleZombieEntries = {}
local firstReplicaSequence
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
    Equipment = {
        Describe = function()
            return {
                combatModeResolved = "melee",
                weaponStatus = "ready",
            }
        end,
        BuildWornVisualSummary = function()
            return {
                Shirt = {
                    fullType = "Base.Shirt_FormalWhite",
                    textureChoice = 3,
                },
            }
        end,
    },
    Inventory = {
        BuildSummaryPayload = function() return { revision = 0, itemCount = 3 } end,
        BuildFullPayload = function() return { summary = { revision = 0 }, items = {}, containers = {} } end,
        BuildDeltaPayload = function() return nil end,
    },
    Skills = {
        BuildSnapshot = function(record)
            T.equal(type(record), "table", "skills snapshot received non-record")
            return {}
        end,
    },
    Stamina = {
        BuildSnapshot = function(record)
            T.equal(type(record), "table", "stamina snapshot received non-record")
            return { current = 100, max = 100, state = "fresh" }
        end,
    },
    Sandbox = {
        CanZombieTargetRecord = function(record)
            return record.zombieTargetable ~= false
        end,
    },
    Registry = {
        Get = function(id)
            if id == "npc_near" then
                return { id = id, name = "Nearby" }
            end
            return nil
        end,
    },
    Perception = {
        GetZombieFrame = function()
            return { entries = debugVisibleZombieEntries }
        end,
        GetVisibleZombieEntries = function()
            return debugVisibleZombieEntries
        end,
    },
    VisualProfiles = { RollAppearance = function() return {} end },
    MotionHints = {},
    Health = { CanRevive = function() return false end },
    NPCWounds = {
        BuildSnapshot = function(record)
            return record.health and record.health.body or { wounds = {} }
        end,
    },
    NeedsRepository = {
        Get = function(record)
            return record and record.needsState or nil
        end,
    },
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
    Factions = {
        Get = function(id)
            if id == "faction_crossroads" then
                return {
                    id = id,
                    name = "Crossroads Exchange",
                    archetypeID = "trader",
                }
            end
            return nil
        end,
    },
}

local nearbyRecord = {
    id = "npc_near",
    name = "Nearby",
    identitySeed = 123,
    tacticalClass = "colonist",
    hostility = {
        mode = "faction_war",
        attackPlayers = false,
        attackNPCs = true,
        attackZombies = true,
    },
    presenceState = "live",
    alive = true,
    recruited = false,
    persist = true,
    x = 1,
    y = 0,
    z = 0,
    health = {
        current = 100, max = 100, state = "normal",
        body = {
            wholeBodyAilments = {
                starvation = { severity = 0.65 },
                dehydration = { severity = 1 },
            },
        },
    },
    needsState = {
        needs = { hunger = 0.90, thirst = 0.91, fatigue = 0.10 },
    },
    equipment = { worn = {}, attached = {} },
    runtime = {},
    presenceRevision = 1,
    affiliation = {
        factionID = "faction_crossroads",
        membershipStatus = "member",
        role = "trader",
        rank = "member",
    },
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

T.load(FILE)

PNC.Network.ClientState.snapshots = {
    live = {
        id = "live",
        presenceState = "live",
        alive = true,
        liveBodyOnlineID = 73,
    },
    abstract = {
        id = "abstract",
        presenceState = "abstract",
        alive = true,
        liveBodyOnlineID = 74,
    },
    dead = {
        id = "dead",
        presenceState = "live",
        alive = false,
        liveBodyOnlineID = 75,
    },
}
local bodyIdentityIndex = PNC.Network.RefreshClientBodyIdentityIndex()
T.equal(bodyIdentityIndex["73"], true,
    "client body identity index includes live carrier")
T.equal(bodyIdentityIndex["74"], nil,
    "client body identity index excludes abstract carrier")
T.equal(bodyIdentityIndex["75"], nil,
    "client body identity index excludes dead carrier")

nearbyRecord.ownerUsername = "player_1"
T.equal(
    PNC.Network.BuildRosterSnapshot(nearbyRecord).zombieTargetable,
    true,
    "roster omitted zombie targetability"
)
T.equal(
    PNC.Network.BuildSnapshot(nearbyRecord).zombieTargetable,
    true,
    "detailed snapshot omitted zombie targetability"
)
T.equal(
    PNC.Network.BuildPresenceDelta(nearbyRecord).zombieTargetable,
    true,
    "presence delta omitted zombie targetability"
)
T.equal(
    PNC.Network.BuildRosterSnapshot(nearbyRecord).ownerUsername,
    "player_1",
    "roster snapshot owner identity"
)
T.equal(
    PNC.Network.BuildSnapshot(nearbyRecord).ownerUsername,
    "player_1",
    "detailed snapshot owner identity"
)
T.equal(
    PNC.Network.BuildSnapshot(nearbyRecord).hostility.attackPlayers,
    false,
    "detailed snapshot omitted explicit player hostility"
)
local needsSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
T.near(needsSnapshot.needs.hunger, 0.90, 0.000001,
    "detailed snapshot omitted hunger state")
T.near(needsSnapshot.needs.thirst, 0.91, 0.000001,
    "detailed snapshot omitted thirst state")
T.near(needsSnapshot.bodyHealth.wholeBodyAilments.starvation.severity,
    0.65, 0.000001, "detailed snapshot omitted starvation ailment")
T.near(needsSnapshot.bodyHealth.wholeBodyAilments.dehydration.severity,
    1, 0.000001, "detailed snapshot omitted dehydration ailment")
T.equal(
    PNC.Network.BuildRosterSnapshot(nearbyRecord)
        .organizationalFaction.name,
    "Crossroads Exchange",
    "roster faction presentation"
)
T.equal(
    PNC.Network.BuildSnapshot(nearbyRecord)
        .organizationalFaction.role,
    "trader",
    "detailed faction role"
)
nearbyRecord.orderSpec = {
    kind = "camp",
    campId = "camp:trailhead",
    x = 1,
    y = 0,
    z = 0,
    resourceRadius = 12,
}
nearbyRecord.campState = {
    campId = "camp:trailhead",
    anchorX = 1,
    anchorY = 0,
    anchorZ = 0,
    resourceRadius = 12,
    capturedAtWorldHour = 42,
    resources = {
        {
            detectorId = "bed",
            resourceKind = "sleep_surface",
            role = "sleep.bed",
            resourceKey = "bed:1:2:0",
            x = 1.5, y = 2.5, z = 0,
        },
        {
            detectorId = "faucet",
            resourceKind = "water_source",
            role = "water.spigot",
            resourceKey = "faucet:2:2:0:1",
            x = 2.5, y = 2.5, z = 0,
        },
    },
}
local campSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
T.equal(campSnapshot.debugState.campResourceDebug.bedCount, 1,
    "detailed camp debug bed count")
T.equal(campSnapshot.debugState.campResourceDebug.waterCount, 1,
    "detailed camp debug water count")
T.equal(campSnapshot.debugState.campResourceDebug.facilities[1].resourceKey,
    "bed:1:2:0", "detailed camp debug facility key")
T.equal(PNC.Network.BuildPresenceDelta(nearbyRecord)
    .campResourceDebug.resourceCount, 2,
    "presence camp debug resource count")
nearbyRecord.orderSpec = nil
nearbyRecord.campState = nil
T.equal(
    #PNC.Network.BuildRosterSnapshot(nearbyRecord).travel.route.points,
    2,
    "initial roster omitted travel route"
)
T.equal(
    PNC.Network.BuildPresenceDelta(nearbyRecord).travel.route,
    nil,
    "high-frequency presence delta repeated travel route"
)
T.equal(
    PNC.Network.BuildRosterSnapshot(nearbyRecord).mapPresentation.roleTag,
    "trader",
    "roster omitted map presentation"
)
T.equal(
    PNC.Network.BuildRosterSnapshot(nearbyRecord)
        .portrait.equipment.worn.Hat,
    "Base.Hat_HardHat",
    "roster omitted compact portrait metadata"
)
T.equal(
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
    colonyOwned = true,
    colonist = true,
    infected = false,
    portrait = {
        identitySeed = 88,
        faceOnly = true,
        appearance = { hairModel = "Short" },
        equipment = { worn = {} },
    },
})
T.equal(deathSnapshot.deathMarker, true, "death marker roster flag")
T.equal(deathSnapshot.colonist, true, "death marker colonist flag")
T.equal(deathSnapshot.presenceState, "corpse",
    "death marker roster presence")
T.equal(deathSnapshot.inventory, nil,
    "death marker snapshot leaked heavyweight inventory")
T.equal(deathSnapshot.portrait.identitySeed, 88,
    "death marker snapshot omitted compact portrait")

T.equal(PNC.Network.BuildSnapshot(nearbyRecord).attackMode, false, "idle snapshot attack mode")
nearbyRecord.runtime.animationScene = {
    id = "social.surrender",
    bump = "Surrender",
    revision = 4,
    playbackRevision = 2,
    stepId = "surrender",
    stepPosition = 1,
    sequenceLength = 1,
    sequenceIteration = 1,
    repeatMode = "loop",
    stepStartedAt = 1900,
    startedAt = 1900,
    finishAt = 0,
    loop = true,
    blocking = true,
    priority = 80,
}
local sceneSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
T.equal(sceneSnapshot.visualState.sceneActive, true,
    "animation scene omitted from visual snapshot")
T.equal(sceneSnapshot.visualState.sceneId, "social.surrender",
    "animation scene ID snapshot")
T.equal(sceneSnapshot.visualState.sceneBump, "Surrender",
    "animation scene selector snapshot")
T.equal(sceneSnapshot.visualState.scenePlaybackRevision, 2,
    "animation primitive revision snapshot")
T.equal(sceneSnapshot.visualState.sceneStepPosition, 1,
    "animation scene step position snapshot")
T.equal(sceneSnapshot.visualState.sceneRepeatMode, "loop",
    "animation scene repeat policy snapshot")
T.equal(sceneSnapshot.visualState.sceneLoop, true,
    "animation scene loop policy snapshot")
nearbyRecord.runtime.animationScene = nil
nearbyRecord.runtime.target = {
    kind = "zombie",
    zombieId = "z1",
    x = 4,
    y = 0,
    z = 0,
    distSq = 9,
    visible = true,
}
debugVisibleZombieEntries[1] = {
    zombie = {
        getModData = function()
            return {
                PNC_ZombieID = "z1",
                PNC_AggroNPCId = "npc_near",
                PNC_AggroNPCUntil = 3000,
            }
        end,
        getX = function() return 4 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        getActionStateName = function() return "walktoward" end,
        getBumpType = function() return nil end,
        getPath2 = function() return nil end,
    },
    distSq = 9,
    visibilityKind = "clear",
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
nearbyRecord.runtime.zombieAttacker = {
    zombieId = "z1",
    observedAt = 1950,
    phase = "pursuit",
    x = 4,
    y = 0,
    z = 0,
    distSq = 9,
}
local combatSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
T.equal(combatSnapshot.attackMode, true, "combat snapshot attack mode")
T.equal(
    combatSnapshot.equipmentSummary.wornVisuals.Shirt.textureChoice,
    3,
    "worn inventory visual metadata snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.decision,
    "melee_pressure_retreat",
    "combat tactical decision snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.visiblePressureCount,
    3,
    "combat visible pressure snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.target.x,
    4,
    "combat target position snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.tacticalMove.x,
    -2,
    "combat movement goal snapshot"
)
nearbyRecord.runtime.localNavigation = {
    nativeTraversalState = "ClimbWindow",
}
local traversalCombatSnapshot =
    PNC.Network.BuildSnapshot(nearbyRecord)
T.equal(
    traversalCombatSnapshot.visualState.attackActive,
    false,
    "native traversal published an overlapping attack"
)
nearbyRecord.runtime.localNavigation = nil
T.equal(
    combatSnapshot.combatDebugState.coneHalfAngleDegrees,
    55,
    "combat cone snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.visibleZombieCount,
    1,
    "combat visible zombie count snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.nearbyZombieCount,
    1,
    "combat nearby zombie count snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.viewZombies[1].intent,
    "selected",
    "combat visible zombie intent snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.viewZombies[1].targetKind,
    "npc",
    "combat zombie target kind snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.viewZombies[1].targetId,
    "npc_near",
    "combat zombie target ID snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.viewZombies[1].targetName,
    "Nearby",
    "combat zombie target name snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.zombieAttacker.targetName,
    "Nearby",
    "zombie attacker NPC display name snapshot"
)
T.equal(
    combatSnapshot.combatDebugState.zombieAttacker.targetId,
    "npc_near",
    "zombie attacker NPC ID snapshot"
)
nearbyRecord.runtime.pathing = {
    phase = "active",
    ownerMode = "fake_locomotion",
    resolvedMode = "run",
    mode = "run",
    moveAnim = "Run",
    isRunning = true,
    visualMovingUntil = 0,
}
local stalledMotionSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
T.equal(stalledMotionSnapshot.visualState.moving, false,
    "fake movement intent was published as physical movement")
nearbyRecord.runtime.pathing.visualMovingUntil = 2100
local progressedMotionSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
T.equal(progressedMotionSnapshot.visualState.moving, true,
    "recent fake physical movement lost its visual continuity lease")
nearbyRecord.runtime.pathing = nil
nearbyRecord.runtime.combatDebugReplicatedAt = nil
local combatDelta = PNC.Network.BuildPresenceDelta(nearbyRecord)
T.equal(combatDelta.attackMode, true, "combat delta attack mode")
T.equal(
    combatDelta.combatDebugState.decision,
    "melee_pressure_retreat",
    "combat decision presence delta"
)
T.equal(
    PNC.Network.BuildPresenceDelta(nearbyRecord).combatDebugState,
    nil,
    "combat debug presence delta throttle"
)
nearbyRecord.runtime.target = nil
debugVisibleZombieEntries[1] = nil
nearbyRecord.runtime.combatTactical = nil
nearbyRecord.runtime.combatRetreat = nil
local idleCombatDelta = PNC.Network.BuildPresenceDelta(nearbyRecord)
T.equal(
    idleCombatDelta.combatDebugState.target,
    nil,
    "combat debug sends terminal idle transition"
)
T.equal(
    PNC.Network.BuildPresenceDelta(nearbyRecord).combatDebugState,
    nil,
    "idle combat debug does not repeat"
)

nearbyRecord.runtime.bandageCompletionRevision = 3
nearbyRecord.runtime.bandageCompletionAt = 1999
nearbyRecord.runtime.bandageCompletionPartId = "ForeArm_L"
local bandageSnapshot = PNC.Network.BuildSnapshot(nearbyRecord)
T.equal(bandageSnapshot.bandageFeedback.revision, 3,
    "bandage completion revision snapshot")
T.equal(bandageSnapshot.bandageFeedback.partId, "ForeArm_L",
    "bandage completion part snapshot")
T.equal(bandageSnapshot.bandageFeedback.sound, "PNC_BandageComplete",
    "bandage completion sound snapshot")
T.equal(
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
T.equal(passengerSnapshot.aiState, "VehiclePassenger", "vehicle passenger AI state")
T.equal(passengerSnapshot.vehiclePassenger.seat, 1, "vehicle seat snapshot")
T.equal(
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
T.equal(#sent, 12, "500-record roster packet count")
T.equal(sent[1].command, "RosterSyncBegin", "roster begin")
T.equal(sent[12].command, "RosterSyncEnd", "roster end")
for i = 2, 11 do
    T.equal(#sent[i].payload.snapshots, 50, "roster chunk size")
    T.equal(sent[i].payload.snapshots[1].inventory, nil, "roster leaked inventory")
end

sent = {}
PNC.Network.RefreshInterestSets(2000)
T.equal(#sent, 8, "interest-enter recipient count")
sent = {}
PNC.Network.BroadcastRecord(nearbyRecord, "tick")
T.equal(#sent, 8, "targeted live snapshot recipient count")
T.equal(sent[1].payload.snapshot.skillLevels, nil, "tick snapshot leaked detailed skills")
firstReplicaSequence = sent[1].payload.snapshot.replicaSequence
T.truthy(type(firstReplicaSequence) == "number",
    "tick snapshot did not carry replica sequence")
T.equal(PNC.Network.BuildRosterSnapshot(nearbyRecord).replicaSequence,
    firstReplicaSequence,
    "roster snapshot did not carry the current replica sequence")

nearbyRecord.x = 100
sent = {}
PNC.Network.RefreshInterestSets(4000)
T.equal(#sent, 16, "interest enter/exit transition count")
sent = {}
PNC.Network.BroadcastRecord(nearbyRecord, "tick")
T.equal(#sent, 8, "interest recipients did not switch")
T.truthy(
    sent[1].payload.snapshot.replicaSequence > firstReplicaSequence,
    "replica sequence did not advance between server broadcasts"
)

local loopbackEvents = 0
triggerEvent = function()
    loopbackEvents = loopbackEvents + 1
end
isServer = function() return false end
PNC.Network.BroadcastRecord(nearbyRecord, "tick")
T.equal(loopbackEvents, 0,
    "single-player rebuilt a periodic network tick payload")
PNC.Network.BroadcastRecord(nearbyRecord, "materialize")
T.equal(loopbackEvents, 1,
    "single-player explicit mutation event lost its local notification")
isServer = function() return true end

nearbyRecord.ownerUsername = "player_16"
nearbyRecord.x = 1
T.equal(PNC.Network.CanViewCharacter(players[1], nearbyRecord), true, "nearby detail access")
T.equal(PNC.Network.CanViewCharacter(players[16], nearbyRecord), true, "owner detail access")
nearbyRecord.ownerUsername = nil
T.equal(PNC.Network.CanViewCharacter(players[16], nearbyRecord), false, "remote detail rejection")

-- Removal deltas carry only an id. The old `true and nil or snapshot()` idiom
-- evaluated snapshot() anyway and sent that id string through stamina/skills.
sent = {}
PNC.Network.BroadcastRemoval("npc_removed", "range_exit")
T.equal(PNC.Network.FlushRosterDeltas(6000, true), 1, "removal roster delta count")
T.equal(#sent, 16, "removal roster delta recipients")
T.equal(sent[1].command, "RosterDelta", "removal roster delta command")
T.equal(sent[1].payload.entries[1].id, "npc_removed", "removal roster id")
T.equal(sent[1].payload.entries[1].removed, true, "removal roster marker")
T.equal(sent[1].payload.entries[1].snapshot, nil, "removal roster leaked snapshot")
T.equal(PNC.Network.QueueRosterDelta("npc_invalid", false, "invalid"), false, "non-removal accepted id-only record")

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
T.equal(#sent, 8, "death snapshot interest recipient count")
T.equal(sent[1].command, "SyncRecord", "death snapshot command")
T.equal(sent[1].payload.snapshot.deathMarker, true,
    "death event did not use compact marker snapshot")
T.equal(sent[1].payload.snapshot.inventory, nil,
    "death event leaked heavyweight record data")
sent = {}
T.equal(PNC.Network.FlushRosterDeltas(7000, true), 1,
    "death marker roster delta count")
T.equal(#sent, 16, "death marker roster delta recipients")
T.equal(sent[1].payload.entries[1].removed, false,
    "death marker was sent as a removal")
T.equal(sent[1].payload.entries[1].snapshot.deathMarker, true,
    "death marker roster delta lost marker metadata")
activeDeathMarker = nil

sent = {}
T.equal(
    PNC.Network.BroadcastDeathMarkerRemoval(
        nearbyRecord.id,
        "corpse_collected"
    ),
    true,
    "death marker removal broadcast"
)
T.equal(#sent, 16, "death marker removal was not immediate for all players")
T.equal(sent[1].command, "RemoveRecord",
    "death marker removal command")
T.equal(sent[1].payload.reason, "corpse_collected",
    "death marker removal reason")
sent = {}
T.equal(PNC.Network.FlushRosterDeltas(8000, true), 1,
    "death marker removal roster delta count")
T.equal(#sent, 16, "death marker removal delta recipients")
T.equal(sent[1].payload.entries[1].removed, true,
    "death marker removal delta was not terminal")

sent = {}
T.equal(
    PNC.Network.BroadcastBodyRemoval("npc_near", 707, 77, "startup_uuid"),
    true,
    "body-instance removal broadcast"
)
T.equal(#sent, 16, "body-instance removal reaches all players")
T.equal(sent[1].command, "RemoveBody", "body-instance removal command")
T.equal(sent[1].payload.id, "npc_near", "body-instance removal NPC id")
T.equal(sent[1].payload.bodyInstanceID, "707", "body-instance removal outfit id")
T.equal(sent[1].payload.bodyOnlineID, 77, "body-instance removal online id")

sent = {}
T.equal(PNC.Network.BroadcastFirearmShot({
    shotId = "npc_near:1",
    npcId = "npc_near",
    sx = 0,
    sy = 0,
    sz = 0,
    soundRadius = 60,
}), true, "firearm shot event broadcast")
T.equal(#sent, 8, "firearm shot distance recipient count")
T.equal(sent[1].command, "FirearmShot", "firearm shot command")
T.equal(sent[1].payload.shotId, "npc_near:1", "firearm shot id")
T.finish("pnc_network_scale_smoke")

T.finish("pnc_network_scale_smoke")
