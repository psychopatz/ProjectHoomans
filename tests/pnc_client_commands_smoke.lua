local T = require "tests/support/test"

local CLIENT_ROOT =
    T.path("ProjectHoomans", "client", "")
T.addPackagePaths()

local FILE = CLIENT_ROOT .. "PNC/PNC_Client.lua"

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
        PRESENCE_LIVE = "live",
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

T.load(FILE)

local Client = PNC.Client
local State = PNC.Network.ClientState

Client.HandleServerCommand("NPCKnowledge", {
    snapshot = { npcID = "npc_known", categories = {} },
})
T.equal(State.npcKnowledge.npc_known.npcID, "npc_known",
    "multiplayer knowledge reply updates client cache")
T.equal(knowledgeRefreshes, 1,
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
T.equal(Client.RequestNPCKnowledgeTopic(
    "npc_direct", "identity_name"
), true, "single-player disclosure succeeds in process")
T.equal(State.npcKnowledge.npc_direct.categories[1].descriptors[1].value,
    "Burton Gilmore", "single-player disclosure uses shared cache receiver")
T.equal(knowledgeRefreshes, 2,
    "single-player disclosure refreshes active conversation")
PNC.PlayerKnowledgeCommands.HandleDisclosure = function()
    return { success = false, reason = "insufficient_familiarity" }
end
local denied, deniedReason = Client.RequestNPCKnowledgeTopic(
    "npc_direct", "traits"
)
T.falsy(denied, "single-player disclosure propagates the authoritative gate")
T.equal(deniedReason, "insufficient_familiarity",
    "single-player disclosure returns the gate reason")
T.equal(State.pendingDisclosure.npc_direct, nil,
    "rejected local disclosure does not leave a stale pending request")

PNC.Core.IsClientOnly = function() return true end
getSpecificPlayer = function() return {} end
sendClientCommand = function(_, module, command, args)
    sentCommand = { module = module, command = command, args = args }
end
T.equal(Client.RequestNPCKnowledgeTopic(
    "npc_remote", "identity_name"
), true, "multiplayer disclosure request is sent")
T.equal(sentCommand.command, "KnowledgeDisclosureRequest",
    "multiplayer disclosure uses authoritative server command")
T.equal(sentCommand.args.topicID, "identity_name",
    "multiplayer disclosure retains topic")
PNC.Core.IsClientOnly = function() return false end

-- Roster success must not mask a failed/early identity bootstrap. The retry
-- is separately throttled and stops only after a character-bound response.
PNC.Core.IsClientOnly = function() return true end
State.bootstrapState = "error"
State.playerContext = nil
State.lastBootstrapRequestAt = 0
State.snapshots = {
    npc_live = {
        id = "npc_live", presenceState = "live", alive = true,
        interestDetailed = true,
    },
    npc_abstract = {
        id = "npc_abstract", presenceState = "abstract", alive = true,
        interestDetailed = true,
    },
}
sentCommand = nil
local bootstrapRequested, bootstrapReason =
    Client.EnsurePlayerBootstrap(5000, false)
T.equal(bootstrapRequested, true,
    "failed startup bootstrap retries independently of roster state")
T.equal(sentCommand.command, "PlayerBootstrapRequest",
    "bootstrap retry uses authoritative MP command")
T.equal(#sentCommand.args.npcIDs, 1,
    "bootstrap requests only live interested NPCs")
T.equal(sentCommand.args.npcIDs[1], "npc_live",
    "abstract NPC is excluded from bootstrap request")
T.equal(sentCommand.args.scope, "interest",
    "bootstrap uses centralized knowledge-interest scope")
T.equal(State.bootstrapState, "loading",
    "bootstrap retry records loading state")
local requestBeforeKnown = sentCommand.args.requestID
Client.HandleServerCommand("PlayerBootstrap", {
    requestID = requestBeforeKnown,
    state = "known",
    context = {
        characterUUID = "player:retry",
        bindingRevision = 1,
    },
    knowledgeRevision = 0,
    chunkIndex = 1,
    chunkCount = 1,
    scope = "live",
    snapshots = {
        { npcID = "npc_live", revision = 0, categories = {} },
    },
})
sentCommand = nil
local bootstrapCurrent, currentReason =
    Client.EnsurePlayerBootstrap(10000, false)
T.equal(bootstrapCurrent, true,
    "character-bound bootstrap stops retries")
T.equal(currentReason, "current",
    "completed bootstrap reports current")
T.equal(sentCommand, nil,
    "completed bootstrap does not send another request")

-- A visible map consumer may demand an abstract NPC without widening the
-- bootstrap to every abstract record. The tick-facing debounce batches rapid
-- hover changes, and hydration removes the ID from the demand set.
local queued, queueReason = PNC.KnowledgeInterest.Require(
    "npc_abstract", "map_hover")
T.equal(queued, true, "map hover queues distant NPC knowledge")
T.equal(queueReason, "queued", "new map demand reports queued")
T.equal(PNC.KnowledgeInterest.ConsumeFlush(5099), false,
    "map knowledge demand observes batching debounce")
T.equal(PNC.KnowledgeInterest.ConsumeFlush(5100), true,
    "map knowledge demand becomes ready as one batch")
sentCommand = nil
local mapRequested = Client.EnsurePlayerBootstrap(5100, true)
T.equal(mapRequested, true, "map demand forces a scoped bootstrap")
T.equal(#sentCommand.args.npcIDs, 1,
    "map demand does not resend hydrated live NPCs")
T.equal(sentCommand.args.npcIDs[1], "npc_abstract",
    "map demand requests only the hovered abstract NPC")
Client.HandleServerCommand("PlayerBootstrap", {
    requestID = sentCommand.args.requestID,
    state = "known",
    context = {
        characterUUID = "player:retry",
        bindingRevision = 1,
    },
    knowledgeRevision = 0,
    chunkIndex = 1,
    chunkCount = 1,
    scope = "interest",
    snapshots = {
        { npcID = "npc_abstract", revision = 0, categories = {} },
    },
})
T.equal(PNC.KnowledgeInterest.CollectNPCIDs(true)[1], nil,
    "hydrated map demand leaves no retry work")
State.activeBootstrapRequestID = nil
PNC.Core.IsClientOnly = function() return false end

local customPayload
Client.Internal.RegisterServerCommand(
    "CustomCommand",
    function(args) customPayload = args end
)
Client.HandleServerCommand("CustomCommand", { value = 7 })
T.equal(customPayload.value, 7, "extensible command registry")

Client.HandleServerCommand("PlayerBootstrap", {
    requestID = "bootstrap:restart",
    state = "known",
    context = {
        characterUUID = "player:restart",
        bindingRevision = 1,
    },
    knowledgeRevision = 3,
    chunkIndex = 1,
    chunkCount = 1,
    snapshots = {
        {
            npcID = "npc_bootstrap",
            revision = 4,
            categories = {
                { descriptors = {
                    {
                        descriptorID = "identity.name",
                        value = "Persisted Name",
                        status = "confirmed",
                    },
                } },
            },
        },
    },
})
T.equal(State.npcKnowledge.npc_bootstrap.npcID, "npc_bootstrap",
    "restart bootstrap hydrates NPC knowledge")
T.equal(State.npcPresentations.npc_bootstrap.state, "known",
    "restart bootstrap hydrates known identity presentation")
T.equal(State.npcPresentations.npc_bootstrap.displayName, "Persisted Name",
    "restart bootstrap restores the learned NPC name")

Client.HandleServerCommand("FullSync", {
    snapshots = {
        { id = "npc_full", x = 1 },
    },
})
T.equal(State.snapshots.npc_full.x, 1, "legacy full sync")
T.equal(State.npcKnowledge.npc_bootstrap.npcID, "npc_bootstrap",
    "legacy full sync cannot erase bootstrapped NPC knowledge")

Client.HandleServerCommand("RosterSyncBegin", {
    directoryRevision = 4,
    chunkCount = 1,
})
T.equal(State.npcKnowledge.npc_bootstrap.npcID, "npc_bootstrap",
    "roster sync begin cannot erase bootstrapped NPC knowledge")
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
T.equal(State.rosterRevision, 4, "roster revision")
T.equal(
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
T.equal(State.snapshots.npc_roster.x, 9, "record delta merged")
T.equal(
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
T.equal(
    State.characterPayloads.npc_roster.inventory.items.item_1.stack,
    3,
    "inventory delta applied"
)
T.equal(
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
T.equal(State.snapshots.npc_roster.deathMarker, true,
    "death marker snapshot was not applied")
T.equal(State.snapshots.npc_roster.inventory, nil,
    "thin death marker retained heavyweight live snapshot fields")
T.equal(State.characterPayloads.npc_roster, nil,
    "death marker retained stale character payload")

Client.HandleServerCommand("InventoryResult", { success = true })
T.equal(inventoryResult.success, true, "inventory result dispatched")
Client.HandleServerCommand("MapCommandResult", { ok = true })
T.equal(mapResult.ok, true, "map result dispatched")
Client.HandleServerCommand("FactionToll", {
    kind = "demand",
    amount = 12,
})
T.equal(tollMessage.amount, 12,
    "faction toll dispatched")
Client.HandleServerCommand("FactionDebug", {
    authorized = true,
    snapshot = {
        registryRevision = 3,
        factions = {},
    },
})
T.equal(State.factionDebugAuthorized, true,
    "faction debug authorization")
T.equal(State.factionDebug.registryRevision, 3,
    "faction debug snapshot dispatched")
Client.HandleServerCommand("FirearmShot", { shotId = "shot:1" })
T.equal(firearmShot.shotId, "shot:1", "firearm event dispatched")
Client.HandleServerCommand("RemoveBody", { bodyInstanceID = "17" })
T.equal(removedBody.bodyInstanceID, "17", "body removal dispatched")

Client.HandleServerCommand("RemoveRecord", { id = "npc_roster" })
T.equal(State.snapshots.npc_roster, nil, "record removal applied")
T.equal(
    State.characterPayloads.npc_roster,
    nil,
    "character payload removal applied"
)
T.equal(State.lastSyncReceiveAt, 5000, "command receive timestamp")
T.finish("pnc_client_commands_smoke")

T.finish("pnc_client_commands_smoke")
