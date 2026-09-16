local T = require "tests/support/test"
T.addPackagePaths()

local leaseChecks = 0
local revisionChecks = 0
local transferCalls = 0
local syncCalls = 0
local player = {}
local record = { id = "npc:alice" }

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}
PNC = {
    Registry = {},
    Network = {
        SendCharacterPayload = function() syncCalls = syncCalls + 1 end,
    },
    Conversation = {
        Authority = {
            Internal = {
                ValidateLease = function(owner, npc, token)
                    leaseChecks = leaseChecks + 1
                    return owner == player and npc == record
                        and token == "lease:1", "invalid_lease"
                end,
            },
        },
    },
    ServerInventory = {
        Internal = {
            checkRevision = function(_, args)
                revisionChecks = revisionChecks + 1
                if args.inventoryRevision ~= 7 then
                    return false, "revision_conflict", {
                        currentInventoryRevision = 7,
                    }
                end
                return true, 7
            end,
            transferNPCToPlayer = function(owner, npc, args, revision)
                transferCalls = transferCalls + 1
                T.equal(owner, player, "transfer receives the player")
                T.equal(npc, record, "transfer receives the NPC record")
                T.equal(revision, 7,
                    "transfer receives the checked revision")
                T.equal(args.direction, "npc_to_player",
                    "semantic transfer preserves direction")
                return true, "transferred_to_player"
            end,
        },
    },
}

local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Server/ServerInventory/PNC_ServerInventory_Semantic.lua"
)

local invalidDirection, invalidDirectionReason =
    Service.SemanticTransferNPCToPlayer(player, record, {
        direction = "player_to_npc",
        conversationToken = "lease:1",
        inventoryRevision = 7,
    })
T.falsy(invalidDirection, "semantic transfer rejects wrong direction")
T.equal(invalidDirectionReason, "semantic_direction_invalid",
    "wrong direction is diagnosable")

local invalidLease, invalidLeaseReason =
    Service.SemanticTransferNPCToPlayer(player, record, {
        direction = "npc_to_player",
        conversationToken = "lease:bad",
        inventoryRevision = 7,
    })
T.falsy(invalidLease, "semantic transfer rejects an invalid lease")
T.equal(invalidLeaseReason, "invalid_lease",
    "invalid lease is returned from conversation authority")

local conflict, conflictReason =
    Service.SemanticTransferNPCToPlayer(player, record, {
        direction = "npc_to_player",
        conversationToken = "lease:1",
        inventoryRevision = 6,
    })
T.falsy(conflict, "semantic transfer rejects stale inventory state")
T.equal(conflictReason, "revision_conflict",
    "stale inventory reason is preserved")
T.equal(syncCalls, 1, "revision conflicts trigger an authoritative resync")

local accepted, acceptedReason =
    Service.SemanticTransferNPCToPlayer(player, record, {
        direction = "npc_to_player",
        conversationToken = "lease:1",
        inventoryRevision = 7,
        itemIDs = { "item:apple:1" },
    })
T.equal(accepted, true, "valid semantic transfer delegates successfully")
T.equal(acceptedReason, "transferred_to_player",
    "transfer result is preserved")
T.equal(leaseChecks, 3, "each transfer validates the conversation lease")
T.equal(revisionChecks, 2,
    "revision check runs only after authority validation")
T.equal(transferCalls, 1,
    "only a fully authorized current transfer reaches mutation")

T.finish("pnc_server_inventory_semantic_smoke")
