local CLIENT_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/"
package.path = CLIENT_ROOT .. "?.lua;" .. package.path

local FILE = CLIENT_ROOT .. "PNC/PNC_Client.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(
            (label or "assertEqual")
                .. ": expected=" .. tostring(expected)
                .. " actual=" .. tostring(actual)
        )
    end
end

local firearmShot
local inventoryResult
local mapResult
local removedBody
local tollMessage
local knowledgeRefreshes = 0
local sentCommand

package.preload["PsychopatzCore/World/PsychopatzTeleport"] = function()
    return { ToCoordinates = function() return true end }
end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_DEBUG_ROSTER = "DebugRoster",
        CMD_FACTION_DEBUG = "FactionDebug",
        CMD_MAP_COMMAND_RESULT = "MapCommandResult",
        CMD_FACTION_TOLL = "FactionToll",
        CMD_ZOMBIE_REACTION = "ZombieReaction",
        CMD_ZOMBIE_BITE = "ZombieBite",
        CMD_FIREARM_SHOT = "FirearmShot",
        CMD_FULL_SYNC = "FullSync",
        CMD_ROSTER_SYNC_BEGIN = "RosterSyncBegin",
        CMD_ROSTER_SYNC_CHUNK = "RosterSyncChunk",
        CMD_ROSTER_SYNC_END = "RosterSyncEnd",
        CMD_ROSTER_DELTA = "RosterDelta",
        CMD_SYNC_RECORD = "SyncRecord",
        CMD_REMOVE_RECORD = "RemoveRecord",
        CMD_REMOVE_BODY = "RemoveBody",
        CMD_CHARACTER_PAYLOAD = "CharacterPayload",
        CMD_INVENTORY_DELTA = "InventoryDelta",
        CMD_INVENTORY_RESULT = "InventoryResult",
        CMD_NPC_KNOWLEDGE = "NPCKnowledge",
        CMD_NPC_KNOWLEDGE_REQUEST = "RequestNPCKnowledge",
        CMD_PLAYER_BOOTSTRAP_REQUEST = "PlayerBootstrapRequest",
        CMD_PLAYER_BOOTSTRAP = "PlayerBootstrap",
        CMD_NPC_PRESENTATION_REQUEST = "NPCPresentationRequest",
        CMD_NPC_PRESENTATION = "NPCPresentation",
        CMD_KNOWLEDGE_DISCLOSURE_REQUEST = "KnowledgeDisclosureRequest",
        CMD_KNOWLEDGE_DISCLOSURE = "KnowledgeDisclosure",
    },
    Core = {
        Now = function() return 5000 end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
        IsClientOnly = function() return false end,
    },
    Network = {
        ClientState = {
            snapshots = {},
            characterPayloads = {},
        },
        FindZombieByOnlineID = function() return nil end,
    },
    Registry = {
        Get = function() return nil end,
        GetLiveZombie = function() return nil end,
    },
    ClientFirearmEffects = {
        Play = function(args) firearmShot = args end,
    },
    ClientPresenceSync = {
        RemoveBodyInstance = function(args) removedBody = args end,
    },
    InventoryWindow = {
        OnResult = function(args) inventoryResult = args end,
    },
    MapCommands = {
        HandleResult = function(args) mapResult = args end,
    },
    FactionTollUI = {
        HandleServerMessage = function(args)
            tollMessage = args
        end,
    },
    Conversation = {
        ReceiveKnowledgeSnapshot = function(snapshot)
            if snapshot then knowledgeRefreshes = knowledgeRefreshes + 1 end
        end,
    },
}

dofile(FILE)

local Client = PNC.Client
local State = PNC.Network.ClientState

Client.HandleServerCommand("NPCKnowledge", {
    snapshot = { npcID = "npc_known", categories = {} },
})
assertEqual(State.npcKnowledge.npc_known.npcID, "npc_known",
    "multiplayer knowledge reply updates client cache")
assertEqual(knowledgeRefreshes, 1,
    "multiplayer knowledge reply refreshes active conversation")

PNC.NPCKnowledge = {
    DiscoverTopicForPlayer = function()
        return { revealed = { "identity.name" } }
    end,
    BuildPlayerSnapshotForPlayer = function()
        return {
            npcID = "npc_direct",
            categories = {
                { descriptors = {
                    { descriptorID = "identity.name", value = "Burton Gilmore", status = "confirmed" },
                } },
            },
        }
    end,
}
PNC.PlayerKnowledgeCommands = {
    HandleDisclosure = function(_, args)
        local disclosure = PNC.NPCKnowledge.DiscoverTopicForPlayer()
        local snapshot = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer()
        Client.HandleServerCommand("KnowledgeDisclosure", {
            requestID = args.requestID,
            npcID = args.npcID,
            success = disclosure ~= nil,
            presentation = {
                npcID = args.npcID,
                state = "known",
                displayName = "Burton Gilmore",
                snapshot = snapshot,
            },
        })
    end,
}
assertEqual(Client.RequestNPCKnowledgeTopic(
    "npc_direct", "identity_name"
), true, "single-player disclosure succeeds in process")
assertEqual(State.npcKnowledge.npc_direct.categories[1].descriptors[1].value,
    "Burton Gilmore", "single-player disclosure uses shared cache receiver")
assertEqual(knowledgeRefreshes, 2,
    "single-player disclosure refreshes active conversation")

PNC.Core.IsClientOnly = function() return true end
getSpecificPlayer = function() return {} end
sendClientCommand = function(_, module, command, args)
    sentCommand = { module = module, command = command, args = args }
end
assertEqual(Client.RequestNPCKnowledgeTopic(
    "npc_remote", "identity_name"
), true, "multiplayer disclosure request is sent")
assertEqual(sentCommand.command, "KnowledgeDisclosureRequest",
    "multiplayer disclosure uses authoritative server command")
assertEqual(sentCommand.args.topicID, "identity_name",
    "multiplayer disclosure retains topic")
PNC.Core.IsClientOnly = function() return false end

local customPayload
Client.Internal.RegisterServerCommand(
    "CustomCommand",
    function(args) customPayload = args end
)
Client.HandleServerCommand("CustomCommand", { value = 7 })
assertEqual(customPayload.value, 7, "extensible command registry")

Client.HandleServerCommand("FullSync", {
    snapshots = {
        { id = "npc_full", x = 1 },
    },
})
assertEqual(State.snapshots.npc_full.x, 1, "legacy full sync")

Client.HandleServerCommand("RosterSyncBegin", {
    directoryRevision = 4,
    chunkCount = 1,
})
Client.HandleServerCommand("RosterSyncChunk", {
    chunkIndex = 1,
    snapshots = {
        {
            id = "npc_roster",
            travel = {
                route = { points = { { x = 1, y = 2 } } },
            },
        },
    },
})
Client.HandleServerCommand("RosterSyncEnd", {
    directoryRevision = 4,
})
assertEqual(State.rosterRevision, 4, "roster revision")
assertEqual(
    State.snapshots.npc_roster.travel.route.points[1].y,
    2,
    "roster chunk applied"
)

Client.HandleServerCommand("SyncRecord", {
    event = "tick",
    snapshot = {
        id = "npc_roster",
        x = 9,
        travel = { state = "en_route" },
    },
})
assertEqual(State.snapshots.npc_roster.x, 9, "record delta merged")
assertEqual(
    State.snapshots.npc_roster.travel.route.points[1].x,
    1,
    "record delta retained route"
)

Client.HandleServerCommand("CharacterPayload", {
    npcId = "npc_roster",
    snapshot = { id = "npc_roster", x = 10 },
    inventory = {
        items = {
            item_1 = { id = "item_1", stack = 1 },
        },
        containers = {},
        summary = { revision = 1 },
    },
})
Client.HandleServerCommand("InventoryDelta", {
    npcId = "npc_roster",
    inventoryRevision = 2,
    ops = {
        {
            op = "update",
            itemID = "item_1",
            stack = 3,
        },
    },
    summary = { revision = 2 },
})
assertEqual(
    State.characterPayloads.npc_roster.inventory.items.item_1.stack,
    3,
    "inventory delta applied"
)
assertEqual(
    State.characterPayloads.npc_roster.inventory.revision,
    2,
    "inventory revision applied"
)

State.snapshots.npc_roster.inventory = { heavyweight = true }
Client.HandleServerCommand("SyncRecord", {
    event = "death",
    snapshot = {
        id = "npc_roster",
        name = "Dead NPC",
        presenceState = "corpse",
        alive = false,
        deathMarker = true,
        colonist = false,
        x = 11,
        y = 12,
        z = 0,
    },
})
assertEqual(State.snapshots.npc_roster.deathMarker, true,
    "death marker snapshot was not applied")
assertEqual(State.snapshots.npc_roster.inventory, nil,
    "thin death marker retained heavyweight live snapshot fields")
assertEqual(State.characterPayloads.npc_roster, nil,
    "death marker retained stale character payload")

Client.HandleServerCommand("InventoryResult", { success = true })
assertEqual(inventoryResult.success, true, "inventory result dispatched")
Client.HandleServerCommand("MapCommandResult", { ok = true })
assertEqual(mapResult.ok, true, "map result dispatched")
Client.HandleServerCommand("FactionToll", {
    kind = "demand",
    amount = 12,
})
assertEqual(tollMessage.amount, 12,
    "faction toll dispatched")
Client.HandleServerCommand("FactionDebug", {
    authorized = true,
    snapshot = {
        registryRevision = 3,
        factions = {},
    },
})
assertEqual(State.factionDebugAuthorized, true,
    "faction debug authorization")
assertEqual(State.factionDebug.registryRevision, 3,
    "faction debug snapshot dispatched")
Client.HandleServerCommand("FirearmShot", { shotId = "shot:1" })
assertEqual(firearmShot.shotId, "shot:1", "firearm event dispatched")
Client.HandleServerCommand("RemoveBody", { bodyInstanceID = "17" })
assertEqual(removedBody.bodyInstanceID, "17", "body removal dispatched")

Client.HandleServerCommand("RemoveRecord", { id = "npc_roster" })
assertEqual(State.snapshots.npc_roster, nil, "record removal applied")
assertEqual(
    State.characterPayloads.npc_roster,
    nil,
    "character payload removal applied"
)
assertEqual(State.lastSyncReceiveAt, 5000, "command receive timestamp")

print("pnc_client_commands_smoke: ok")
