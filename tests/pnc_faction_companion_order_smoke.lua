local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/PNC_FactionBehavior.lua"

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

local player = {
    getOnlineID = function() return 7 end,
}
local faction = {
    id = "player_faction",
    ownerPlayerKey = "player:alice:character_alice",
    memberIDs = {},
}
local records = {}

PNC = {
    Const = {
        FACTION_COLONIST = "colonist",
        FACTION_HOSTILE = "hostile",
        FACTION_NEUTRAL = "neutral",
        ORDER_FOLLOW = "follow",
        ORDER_GUARD = "guard",
        ORDER_PATROL = "patrol",
        ORDER_TRAVEL = "travel",
        ORDER_HOSTILE_HUNT = "hostile_hunt",
        ORDER_ROAM = "roam",
        ROAM_MODE_AREA = "area",
        ROAM_DEFAULT_RADIUS = 6,
    },
    Core = {
        Now = function() return 1000 end,
        DeepCopy = copy,
    },
    Factions = {
        Registry = { byID = { player_faction = faction } },
        GetOrganizationalFactionID = function(record)
            return record.affiliation and record.affiliation.factionID
        end,
    },
    FactionArchetypes = {},
    FactionConstants = {},
    FactionBalance = {},
    EntityRef = {
        Parse = function()
            return {
                accountIdentity = "alice",
                characterUUID = "character_alice",
            }
        end,
    },
    PlayerCharacters = {
        RuntimeByUUID = { character_alice = player },
    },
    Types = {
        DefaultHostility = function()
            return {
                mode = "friendly",
                attackPlayers = false,
                attackNPCs = false,
                attackZombies = true,
            }
        end,
    },
    FactionTypes = {
        AreEqual = function(left, right)
            if left == right then return true end
            if type(left) ~= "table" or type(right) ~= "table" then
                return false
            end
            for key, value in pairs(left) do
                if not PNC.FactionTypes.AreEqual(value, right[key]) then
                    return false
                end
            end
            for key, value in pairs(right) do
                if not PNC.FactionTypes.AreEqual(value, left[key]) then
                    return false
                end
            end
            return true
        end,
    },
    Registry = {
        Get = function(id) return records[id] end,
        MarkDirty = function() end,
    },
    OrderSystem = {
        SetOrder = function(record, order) record.orderSpec = copy(order) end,
    },
    Network = { BroadcastRecord = function() end },
    SimulationClock = { Wake = function() end },
    JobSystem = { OrderJobs = {
        production_work = "ProductionWork",
        colony_home = "AtHome",
    } },
}

dofile(FILE)

local waiting = {
    id = "waiting",
    alive = true,
    recruited = true,
    faction = "colonist",
    ownerUsername = "alice",
    ownerOnlineID = 3,
    affiliation = { factionID = faction.id },
    hostility = PNC.Types.DefaultHostility("colonist"),
    orderSpec = { kind = "guard", x = 12, y = 8, z = 0 },
    runtime = {},
    x = 12,
    y = 8,
    z = 0,
}
records.waiting = waiting

PNC.FactionBehavior.ApplyNPC(waiting, "periodic_reconciliation")
assert(waiting.orderSpec.kind == "guard",
    "faction reconciliation overwrote Stay with Follow")
assert(waiting.orderSpec.x == 12 and waiting.orderSpec.y == 8,
    "faction reconciliation changed the Stay anchor")

local onlineOwned = copy(waiting)
onlineOwned.id = "online_owned"
onlineOwned.ownerUsername = nil
onlineOwned.ownerOnlineID = 7
onlineOwned.orderSpec = { kind = "guard", x = 14, y = 9, z = 0 }
onlineOwned.runtime = {}
records.online_owned = onlineOwned

PNC.FactionBehavior.ApplyNPC(onlineOwned, "periodic_reconciliation")
assert(onlineOwned.orderSpec.kind == "guard",
    "online-ID ownership reconciliation overwrote Stay with Follow")
assert(onlineOwned.orderSpec.x == 14 and onlineOwned.orderSpec.y == 9,
    "online-ID ownership reconciliation changed the Stay anchor")

local working = copy(waiting)
working.id = "working"
working.orderSpec = { kind = "production_work",
    workOrderId = "work:42", operation = "CONSTRUCT" }
working.runtime = { workOrderId = "work:42" }
records.working = working
PNC.FactionBehavior.ApplyNPC(working, "periodic_reconciliation")
assert(working.orderSpec.kind == "production_work"
        and working.orderSpec.workOrderId == "work:42",
    "faction reconciliation interrupted a registered job order")

local atHomeAfterRestart = copy(waiting)
atHomeAfterRestart.id = "at_home_after_restart"
atHomeAfterRestart.ownerOnlineID = nil
atHomeAfterRestart.orderSpec = {
    kind = "colony_home",
    baseId = "base-1",
    x = 15,
    y = 16,
    z = 0,
    radius = 2,
}
atHomeAfterRestart.runtime = {}
records.at_home_after_restart = atHomeAfterRestart

-- Registry/faction loading runs before the player has a live runtime entry.
-- The durable owner key must still protect the persisted At Home order.
PNC.PlayerCharacters.RuntimeByUUID.character_alice = nil
PNC.FactionBehavior.ApplyNPC(atHomeAfterRestart, "registry_load")
assert(atHomeAfterRestart.orderSpec.kind == "colony_home",
    "offline startup reconciliation replaced At Home with Follow")
assert(atHomeAfterRestart.orderSpec.baseId == "base-1",
    "offline startup reconciliation lost the remembered home base")
assert(atHomeAfterRestart.ownerUsername == "alice",
    "offline startup reconciliation lost the durable owner identity")
PNC.PlayerCharacters.RuntimeByUUID.character_alice = player

local joining = copy(waiting)
joining.id = "joining"
joining.recruited = false
joining.faction = "neutral"
joining.ownerUsername = nil
joining.ownerOnlineID = nil
joining.orderSpec = { kind = "guard", x = 20, y = 20, z = 0 }
joining.runtime = {}
records.joining = joining

PNC.FactionBehavior.ApplyNPC(joining, "faction_joined")
assert(joining.orderSpec.kind == "follow",
    "new player-faction member did not receive its initial Follow order")
assert(joining.orderSpec.ownerUsername == "alice",
    "initial Follow order did not bind the faction owner")

print("pnc_faction_companion_order_smoke: ok")
