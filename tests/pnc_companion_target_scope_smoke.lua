local T = require "tests/support/test"
T.addPackagePaths()

local records = {
    {
        id = "colonist-owned",
        name = "Owned Colonist",
        recruited = true,
        ownerUsername = "player-one",
        x = 105,
        y = 100,
        z = 0,
    },
    {
        id = "colonist-foreign",
        name = "Foreign Colonist",
        recruited = true,
        ownerUsername = "someone-else",
        x = 103,
        y = 100,
        z = 0,
    },
    {
        id = "other-npc",
        name = "Unrecruited NPC",
        recruited = false,
        x = 102,
        y = 100,
        z = 0,
    },
    {
        id = "far-npc",
        name = "Far NPC",
        recruited = false,
        x = 130,
        y = 100,
        z = 0,
    },
}

local snapshotOnly = {
    id = "snapshot-npc",
    name = "Snapshot NPC",
    recruited = false,
    x = 110,
    y = 100,
    z = 0,
}

local identity = {
    GetName = function(source)
        return source and source.name or "Unknown NPC"
    end,
}

local player = {
    username = "player-one",
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        COMPANION_COMMAND_RADIUS = 20,
    },
    CompanionCommands = {
        IsCompanion = function(source)
            return source and source.recruited == true
        end,
        IsOwnedByPlayer = function(source, targetPlayer)
            return source.ownerUsername == targetPlayer.username
        end,
        GetCurrentAttackType = function(source)
            return source and source.attackType
        end,
    },
    Registry = {
        ForEach = function(callback)
            for _, record in ipairs(records) do callback(record) end
        end,
        Get = function(id)
            for _, record in ipairs(records) do
                if tostring(record.id) == tostring(id) then return record end
            end
            return nil
        end,
    },
    Network = {
        ClientState = {
            snapshots = {
                [snapshotOnly.id] = snapshotOnly,
                ["other-npc"] = snapshotOnly,
            },
        },
    },
    NPCIdentityPresentation = identity,
}

package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return identity end

local Resolver = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Commands/PNC_CompanionTargetResolver.lua"
)

local colonists = Resolver.CollectNearbyCompanions(player)
T.equal(#colonists, 1,
    "the existing companion collection remains owner-scoped")
T.equal(colonists[1].id, "colonist-owned",
    "colonist scope keeps the player-owned companion")

local other = Resolver.CollectNearbyTargets(
    player,
    nil,
    Resolver.SCOPE_OTHER
)
T.equal(#other, 2,
    "other scope includes nearby non-colonist records and snapshots")
T.equal(other[1].id, "other-npc",
    "other scope sorts the nearest non-colonist first")
T.equal(other[2].id, "snapshot-npc",
    "other scope includes snapshot-only NPCs")

local resolved = Resolver.ResolveRecipients(
    player,
    "nearby",
    nil,
    "other"
)
T.equal(resolved.scope, Resolver.SCOPE_OTHER,
    "recipient resolution preserves the selected scope")
T.equal(#resolved.targets, 2,
    "nearby recipient resolution uses the selected non-colonist scope")

-- A conversation handoff may carry the selected live body directly when the
-- registry snapshot is one tick behind. Preserve that body and its entry
-- metadata rather than rebuilding an unrelated target.
local liveBody = { marker = "selected-live-body" }
local selectedEntry = {
    id = "selected-npc",
    name = "Selected NPC",
    record = { id = "selected-npc", name = "Selected NPC" },
    snapshot = { id = "selected-npc", name = "Selected NPC" },
    zombie = liveBody,
}
local selected = Resolver.BuildConversationEntry({
    id = selectedEntry.id,
    source = selectedEntry,
    zombie = liveBody,
})
T.equal(selected.zombie, liveBody,
    "conversation entry preserves the directly selected live body")
T.equal(selected.record, selectedEntry.record,
    "conversation entry preserves selected record metadata")
T.equal(selected.snapshot, selectedEntry.snapshot,
    "conversation entry preserves selected snapshot metadata")

T.finish("pnc_companion_target_scope_smoke")
