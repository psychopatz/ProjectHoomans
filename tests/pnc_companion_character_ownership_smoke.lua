local T = require "tests/support/test"
T.addPackagePaths()

local currentUUID = "char_new"
local username = "Psychopatz"
local records = {}
local dirty = {}
local broadcasts = 0

local replacementPlayer = {
    getUsername = function() return username end,
    getOnlineID = function() return 55 end,
}

local oldCompanion = {
    id = "old_companion",
    alive = true,
    recruited = true,
    tacticalClass = "colonist",
    ownerUsername = username,
    ownerOnlineID = 55,
    ownerCharacterUUID = "char_dead",
    generation = {
        source = "starting_companion_trait",
        playerCharacterUUID = "char_dead",
    },
    orderSpec = {
        kind = "follow",
        ownerUsername = username,
        ownerOnlineID = 55,
        ownerCharacterUUID = "char_dead",
    },
    x = 10, y = 20, z = 0,
    runtime = { followOrderActive = true },
}
local currentCompanion = {
    id = "current_companion",
    alive = true,
    recruited = true,
    tacticalClass = "colonist",
    ownerUsername = username,
    ownerOnlineID = 55,
    ownerCharacterUUID = currentUUID,
    orderSpec = {
        kind = "follow",
        ownerUsername = username,
        ownerOnlineID = 55,
        ownerCharacterUUID = currentUUID,
    },
    x = 11, y = 20, z = 0,
    runtime = {},
}
records[oldCompanion.id] = oldCompanion
records[currentCompanion.id] = currentCompanion

PNC = {
    Const = {
        TACTICAL_CLASS_COLONIST = "colonist",
        ORDER_FOLLOW = "follow",
        ORDER_GUARD = "guard",
    },
    Core = {
        ResolvePlayerByOnlineID = function()
            return replacementPlayer
        end,
        ResolvePlayerByUsername = function()
            return replacementPlayer
        end,
    },
    Registry = {
        ForEach = function(callback)
            for _, record in pairs(records) do callback(record) end
        end,
        GetLiveZombie = function() return nil end,
        MarkDirty = function(record, reason)
            dirty[record.id] = reason
        end,
    },
    PlayerCharacters = {
        GetCharacterUUID = function(player)
            return player == replacementPlayer and currentUUID or nil
        end,
        GetRegistryRecord = function(uuid)
            if tostring(uuid) == "char_dead" then
                return { uuid = "char_dead", status = "dead" }
            end
            if tostring(uuid) == currentUUID then
                return { uuid = currentUUID, status = "active" }
            end
            return nil
        end,
    },
    OrderSystem = {
        SetOrder = function(record, order)
            record.orderSpec = order
        end,
    },
    Network = {
        BroadcastRecord = function()
            broadcasts = broadcasts + 1
        end,
    },
    BehaviorCommon = {},
}

-- The shared owner resolver must reject a replacement survivor even when
-- username and online ID are identical to the dead character's session.
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Common.lua"
)
T.equal(PNC.BehaviorCommon.GetOwner(oldCompanion), nil,
    "replacement character inherited old companion by username/online id")
T.equal(PNC.BehaviorCommon.GetOwner(currentCompanion), replacementPlayer,
    "current character could not resolve its own companion")

-- Migration for an already-affected save: once the replacement character is
-- bound, personal ownership attached to a dead/retired character UUID is
-- released without deleting the NPC. The old survivor remains a world/faction
-- NPC but no longer follows the new character.
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Companions/DebugCompanionRecruit/PNC_DebugCompanionRecruit_Ownership.lua"
)
local released = PNC.Recruitment.ReconcileCharacterOwnership(
    replacementPlayer,
    currentUUID
)
T.equal(released, 1,
    "stale dead-character companion ownership was not reconciled")
T.equal(oldCompanion.recruited, false,
    "old companion remained personally recruited to replacement survivor")
T.equal(oldCompanion.ownerUsername, nil,
    "old companion retained username ownership")
T.equal(oldCompanion.ownerOnlineID, nil,
    "old companion retained session online-id ownership")
T.equal(oldCompanion.ownerCharacterUUID, nil,
    "old companion retained dead character UUID ownership")
T.equal(oldCompanion.orderSpec.kind, "guard",
    "old companion kept following the replacement survivor")
T.equal(currentCompanion.recruited, true,
    "current character companion was incorrectly released")
T.equal(currentCompanion.ownerCharacterUUID, currentUUID,
    "current character companion ownership changed")
T.equal(broadcasts, 1,
    "ownership migration did not publish the changed old companion")
T.truthy(dirty[oldCompanion.id] ~= nil,
    "ownership migration was not persisted")

T.finish("pnc_companion_character_ownership_smoke")
