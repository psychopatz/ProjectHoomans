local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local clock = 1000
local findCalls, reserveCalls, released = 0, 0, 0
local lastPolicy
local worldSessions = {}
local sourceItems = {
    ["wl:1:s:1"] = {
        { itemToken = "beans:a", fullType = "Base.CannedBeans",
            displayName = "Canned Beans", category = "Food", quantity = 1 },
        { itemToken = "beans:b", fullType = "Base.CannedBeans",
            displayName = "Canned Beans", category = "Food", quantity = 1 },
    },
    ["wl:1:s:2"] = {
        { itemToken = "beans:c", fullType = "Base.CannedBeans",
            displayName = "Canned Beans", category = "Food", quantity = 1 },
    },
    ["wl:1:s:3"] = {
        { itemToken = "bandage:a", fullType = "SomeMod.FieldBandage",
            displayName = "Field Bandage", category = "Medical", quantity = 1 },
    },
}

local WorldLoot = {}
function WorldLoot.FindSources(options)
    findCalls = findCalls + 1
    lastPolicy = options.sourceTypes
    local sources = {}
    local definitions = {
        { key = "containers", sourceType = "container" },
        { key = "floorItems", sourceType = "floor" },
        { key = "corpses", sourceType = "corpse" },
    }
    for index, definition in ipairs(definitions) do
        if options.sourceTypes[definition.key] then
            sources[#sources + 1] = {
                sourceToken = "wl:1:s:" .. index,
                sourceType = definition.sourceType,
                label = definition.sourceType == "container"
                    and "Fridge" or nil,
                x = index, y = 0, z = 0,
                approximateDistanceSq = index * index,
            }
        end
    end
    worldSessions["wl:1"] = true
    return { sessionId = "wl:1", sources = sources,
        counts = { container = options.sourceTypes.containers and 1 or 0,
            floor = options.sourceTypes.floorItems and 1 or 0,
            corpse = options.sourceTypes.corpses and 1 or 0 },
        truncated = false }
end
function WorldLoot.ListItems(token)
    local output = {}
    for index, item in ipairs(sourceItems[token] or {}) do
        output[index] = item
    end
    return output, nil, { truncated = false }
end
function WorldLoot.ReserveItem(sourceToken, itemToken, owner)
    reserveCalls = reserveCalls + 1
    return { reservationToken = table.concat({ "r", sourceToken,
        itemToken, owner }, ":") }
end
function WorldLoot.ReleaseReservation() released = released + 1; return true end
function WorldLoot.ReleaseSession(id) worldSessions[id] = nil; return true end
function WorldLoot.GetDiagnostics() return { Searches = findCalls } end

package.preload["PsychopatzCore/WorldLoot/PsychopatzWorldLoot"] =
    function() return WorldLoot end

local modData = {}
ModData = { getOrCreate = function(key)
    modData[key] = modData[key] or {}
    return modData[key]
end }
GlobalModData = { save = function() end }
Events = { OnInitGlobalModData = { Add = function() end } }
isServer = function() return false end

local owner = {
    username = "alice", getUsername = function(self) return self.username end,
    getX = function() return 0 end, getY = function() return 0 end,
    getZ = function() return 0 end,
}
local intruder = {
    username = "mallory", getUsername = owner.getUsername,
    getX = owner.getX, getY = owner.getY, getZ = owner.getZ,
}
local records = {
    bob = { id = "bob", name = "Bob", alive = true, owner = "alice",
        runtime = {}, orderSpec = { kind = "follow",
            ownerUsername = "alice" } },
    alice2 = { id = "alice2", name = "Alice Two", alive = true,
        owner = "alice", runtime = {}, orderSpec = { kind = "guard" } },
}

local dirty, reevaluated = 0, 0
PNC = {
    Const = {
        COMPANION_COMMAND_RADIUS = 20,
        MODULE = "PNC", CMD_SCAVENGE_STATE = "ScavengeState",
        SCAVENGE_MAX_RADIUS = 24, SCAVENGE_DEFAULT_RADIUS = 12,
        SCAVENGE_MAX_CANDIDATES = 256,
        SCAVENGE_MAX_MANIFEST_ENTRIES = 512,
    },
    Core = {
        Now = function() clock = clock + 1; return clock end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
    PlayerCharacters = {
        GetEntityKey = function(player)
            return "player:" .. tostring(player and player.username)
        end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function() return nil end,
    },
    CompanionCommands = {
        CanPlayerCommand = function(record, player)
            if record.owner ~= player.username then return false, "not_owner" end
            return true
        end,
    },
    Tasking = { Commands = {
        MarkDirty = function() dirty = dirty + 1 end,
        Reevaluate = function() reevaluated = reevaluated + 1; return true end,
        CancelForNPC = function() return true end,
    } },
    Inventory = { GetEncumbranceState = function()
        return { usedWeight = 1, maxWeight = 10, ratio = 0.1,
            level = "normal" }
    end },
}

T.load("ProjectHoomans", "server", "PNC/Scavenge/PNC_ScavengePolicy.lua")
local Service = T.load("ProjectHoomans", "server",
    "PNC/Scavenge/PNC_ScavengeService.lua")

T.equal(findCalls, 0, "idle service performs no world query")
local ok, reason = Service.StartSearch(intruder, { npcId = "bob",
    sourcePolicy = { containers = true } })
T.falsy(ok, "non-owner starts search")
T.equal(reason, "not_owner", "non-owner rejection")
T.equal(findCalls, 0, "rejected command avoids world query")

ok, reason = Service.StartSearch(owner, { npcId = "bob",
    sourcePolicy = { containers = true } })
T.truthy(ok, "owner starts container search")
T.equal(lastPolicy.containers, true, "container mask enabled")
T.equal(lastPolicy.floorItems, false, "floor mask excluded")
T.equal(lastPolicy.corpses, false, "corpse mask excluded")
local first = Service.Internal.SessionForNPC("bob")
T.equal(first.candidateCount, 1, "container-only candidate count")
T.equal(records.bob.scavengeSession, nil, "manifest remains runtime-only")
T.equal(dirty, 1, "task coordinator marked dirty")
T.equal(reevaluated, 1, "task coordinator reevaluated")

ok = Service.StartSearch(owner, { npcId = "bob",
    sourcePolicy = { floorItems = true } })
T.truthy(ok, "owner starts floor-only search")
T.equal(lastPolicy.containers, false, "floor-only excludes containers")
T.equal(lastPolicy.floorItems, true, "floor-only includes floor")
T.equal(lastPolicy.corpses, false, "floor-only excludes corpses")
T.equal(Service.Internal.SessionForNPC("bob").candidates[1].sourceType,
    "floor", "floor-only source")

ok = Service.StartSearch(owner, { npcId = "bob",
    sourcePolicy = { corpses = true } })
T.truthy(ok, "owner starts corpse-only search")
T.equal(lastPolicy.containers, false, "corpse-only excludes containers")
T.equal(lastPolicy.floorItems, false, "corpse-only excludes floor")
T.equal(lastPolicy.corpses, true, "corpse-only includes corpses")
T.equal(Service.Internal.SessionForNPC("bob").candidates[1].sourceType,
    "corpse", "corpse-only source")

ok = Service.StartSearch(owner, { npcId = "bob", sourcePolicy = {
    containers = true, floorItems = true, corpses = true } })
T.truthy(ok, "mixed search starts")
local session = Service.Internal.SessionForNPC("bob")
T.equal(session.candidateCount, 3, "mixed source mask")
for _, source in ipairs(session.candidates) do
    T.truthy(Service.AppendSourceItems(session, source),
        "source manifest append")
end
T.equal(#session.manifest, 4, "manifest retains exact source entries")
T.equal(session.manifest[1].fullType, "Base.CannedBeans",
    "generic FullType survives")
T.equal(session.manifest[4].fullType, "SomeMod.FieldBandage",
    "modded FullType survives")
T.equal(session.manifest[1].sourceLabel, "Fridge",
    "container display name reaches manifest")

T.truthy(Service.SetAutoGrab(owner, { sessionId = session.id,
    fullType = "SomeMod.FieldBandage", enabled = true }))
T.truthy(PNC.ScavengePolicy.Matches(owner, "SomeMod.FieldBandage"),
    "exact FullType auto-grab")
T.truthy(PNC.ScavengePolicy.Save(false), "auto-grab policy persists")
T.truthy(Service.GetAutoGrabPolicy(owner)["SomeMod.FieldBandage"],
    "auto-grab policy shared across followers")
ok, reason = Service.StartSearch(owner, { npcId = "alice2",
    sourcePolicy = { corpses = true } })
T.falsy(ok, "owned NPC not following player cannot start search")
T.equal(reason, "npc_not_following_player", "follower-only reason")
records.alice2.orderSpec = { kind = "follow", ownerUsername = "alice" }
ok = Service.StartSearch(owner, { npcId = "alice2",
    sourcePolicy = { corpses = true } })
T.truthy(ok, "second owned follower starts search after following")
local secondFollower = Service.Internal.SessionForNPC("alice2")
T.truthy(Service.AppendSourceItems(secondFollower,
    secondFollower.candidates[1]), "second follower inspects corpse")
T.equal(secondFollower.manifest[1].autoGrab, true,
    "owner-level Auto Grab applies across followers")

session.state = "WAITING_FOR_SELECTION"
local revision = session.revision
ok, reason = Service.QueueMultiple(owner, { sessionId = session.id,
    revision = revision - 1, entryIds = { session.manifest[1].entryId } })
T.falsy(ok, "stale revision accepted")
T.equal(reason, "revision_conflict", "stale revision reason")
T.equal(reserveCalls, 0, "stale request creates no reservation")
ok, reason = Service.QueueMultiple(owner, { sessionId = session.id,
    revision = revision, entryIds = { "forged-entry" } })
T.falsy(ok, "forged entry accepted")
T.equal(reason, "entry_invalid", "forged entry rejection")
T.equal(reserveCalls, 0, "forged entry creates no reservation")
ok, reason = Service.QueueMultiple(intruder, { sessionId = session.id,
    revision = revision, entryIds = { session.manifest[1].entryId } })
T.falsy(ok, "intruder queued owner loot")
T.equal(reason, "session_not_owned", "session ownership enforced")

ok = Service.QueueMultiple(owner, { sessionId = session.id,
    revision = revision, entryIds = {
        session.manifest[1].entryId, session.manifest[2].entryId,
        session.manifest[3].entryId,
    } })
T.truthy(ok, "manual selection queues")
T.equal(session.queueCount, 3, "all selected exact entries queued")
T.equal(#session.queue, 2, "entries grouped by source")
T.equal(#session.queue[1].entries, 2,
    "same-source entries share one travel group")
T.equal(reserveCalls, 3, "each exact record reserved")

T.truthy(Service.Pause(owner, { sessionId = session.id }),
    "pause accepts active collection")
T.equal(session.state, "PAUSED", "pause state retained")
T.equal(session.phase, "PAUSED", "pause phase retained")
T.equal(#(session.queue or {}), 0, "pause clears pickup queue")
T.equal(session.manifest[1].status, "AVAILABLE",
    "pause makes queued loot selectable again")

session.state = "WAITING_FOR_SELECTION"
revision = session.revision
T.truthy(Service.QueueMultiple(owner, { sessionId = session.id,
    revision = revision, entryIds = { session.manifest[1].entryId,
        session.manifest[2].entryId, session.manifest[3].entryId } }),
    "collection can be queued after pause")

T.truthy(Service.Cancel(owner, { sessionId = session.id,
    reason = "test" }), "collection cancels")
T.equal(session.state, "CANCELLED", "cancel state")
T.equal(released, 6, "pause and cancellation release every reservation")
T.equal(worldSessions[session.worldLootSessionId], nil,
    "cancelled session releases Core runtime tokens")

ok, reason = Service.StartSearch(owner, {
    npcId = "bob", npcIds = { "bob", "alice2" },
    sourcePolicy = { containers = true },
})
T.truthy(ok, "following NPCs start one cooperative run")
local team = Service.Internal.SessionForNPC("bob")
T.equal(Service.Internal.SessionForNPC("alice2"), team,
    "every scavenger maps to the shared session")
T.equal(#team.npcIds, 2, "shared session retains both scavengers")
T.truthy(team.workers.bob and team.workers.alice2,
    "shared session creates independent worker state")
local teamSnapshot = Service.BuildSnapshot(team)
T.truthy(teamSnapshot.runActive,
    "snapshot exposes active search for client toggle feedback")
T.equal(teamSnapshot.carry.usedWeight, 2,
    "team snapshot totals carried weight")
T.equal(teamSnapshot.carry.maxWeight, 20,
    "team snapshot totals carry capacity")
T.equal(#teamSnapshot.scavengers, 2,
    "team snapshot exposes each scavenger")
records.bob.orderSpec = { kind = "scavenge", sessionId = team.id }
records.alice2.orderSpec = { kind = "scavenge", sessionId = team.id }
ok, reason = Service.StartSearch(owner, {
    npcId = "bob", npcIds = { "bob", "alice2" },
    sourcePolicy = { containers = true },
})
T.truthy(ok,
    "assigned scavengers can restart their owned run after leaving follow order")

T.finish("pnc_scavenge_service_smoke")
