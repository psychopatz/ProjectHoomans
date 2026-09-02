local T = require "tests/support/test"

local SHARED =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

local function saveSafe(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "string"
        or kind == "number" or kind == "boolean"
    then
        return
    end
    if kind ~= "table" or getmetatable(value) ~= nil then
        error("unsafe faction warfare value: " .. kind)
    end
    seen = seen or {}
    if seen[value] then error("cycle in faction warfare value") end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe faction warfare key")
        end
        saveSafe(item, seen)
    end
    seen[value] = nil
end

local hour = 50
local globalData = {}

-- Project Zomboid's Kahlua runtime does not expose Lua's global next().
-- Keep it absent across the complete faction service/behavior path.
next = nil

function isClient() return false end
function isServer() return true end
function getTimeInMillis() return hour * 3600000 end
function getGameTime()
    return {
        getWorldAgeHours = function() return hour end,
    }
end

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
ModData = {
    getOrCreate = function(key)
        globalData[key] = globalData[key] or {}
        return globalData[key]
    end,
}

PNC = {}
T.load(SHARED .. "Base/PNC_Core.lua")
T.load(SHARED .. "Base/PNC_Constants.lua")
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED .. "Factions/PNC_FactionBalance.lua")
T.load(SHARED .. "Factions/PNC_FactionArchetypes.lua")
T.load(SHARED .. "Factions/PNC_FactionEmblems.lua")
T.load(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
T.load(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
T.load(SHARED .. "Factions/PNC_FactionIntent.lua")
T.load(SHARED .. "Factions/PNC_FactionTypes.lua")

PNC.Types = {
    NormalizeTacticalClass = function(value)
        value = tostring(value or "neutral")
        if value == "colonist" or value == "neutral"
            or value == "hostile"
        then
            return value
        end
        return "neutral"
    end,
    DefaultHostility = function(value)
        if value == "colonist" then
            return {
                mode = "defend_owner",
                attackPlayers = false,
                attackNPCs = true,
                attackZombies = true,
            }
        end
        return {
            mode = "neutral",
            attackPlayers = false,
            attackNPCs = true,
            attackZombies = false,
        }
    end,
}
PNC.Types.ResolveTacticalClass = function(value)
    if type(value) == "table" then
        value = value.tacticalClass or value.faction
    end
    return PNC.Types.NormalizeTacticalClass(value)
end

local dirty = {}
PNC.Registry = { Data = {} }
function PNC.Registry.Get(id) return PNC.Registry.Data[id] end
function PNC.Registry.EnsureLoaded() return true end
function PNC.Registry.MarkDirty(record)
    if not dirty[record.id] then
        record.recordRevision =
            (tonumber(record.recordRevision) or 0) + 1
    end
    dirty[record.id] = true
    return true
end

PNC.OrderSystem = {
    SetOrder = function(record, order)
        record.orderSpec = PNC.Core.DeepCopy(order)
    end,
}
PNC.SimulationClock = { Wake = function() end }
local broadcasts = {}
PNC.Network = {
    BroadcastRecord = function(record, reason)
        broadcasts[#broadcasts + 1] = {
            id = record.id,
            reason = reason,
        }
    end,
}

local playerKey = "player:Patrick:char_player"
local memberKey = "player:Alex:char_member"
local player = {
    uuid = "char_player",
    getUsername = function() return "Patrick" end,
    getDisplayName = function() return "Patrick" end,
    getOnlineID = function() return 7 end,
}
PNC.PlayerCharacters = {
    Registry = {
        byUUID = {
            char_player = {
                uuid = "char_player",
                accountIdentity = "Patrick",
                displayName = "Patrick",
                status = "active",
            },
            char_member = {
                uuid = "char_member",
                accountIdentity = "Alex",
                displayName = "Alex",
                status = "active",
            },
            char_join = {
                uuid = "char_join",
                accountIdentity = "Morgan",
                displayName = "Morgan",
                status = "active",
            },
        },
    },
    RuntimeByUUID = {
        char_player = player,
        char_member = {
            uuid = "char_member",
            getUsername = function() return "Alex" end,
        },
        char_join = {
            uuid = "char_join",
            getUsername = function() return "Morgan" end,
        },
    },
    EnsureLoaded = function() return true end,
    GetCharacterUUID = function(value)
        return value and value.uuid
    end,
    GetEntityKey = function(value)
        local uuid = value and value.uuid
        local account = value and value.getUsername
            and value:getUsername() or nil
        return uuid and PNC.EntityRef.ForPlayerIdentity(
            account,
            uuid
        ) or playerKey, "resolved"
    end,
}

local function npc(id)
    local record = {
        id = id,
        name = id,
        alive = true,
        tacticalClass = "colonist",
        recruited = true,
        ownerUsername = "Patrick",
        ownerOnlineID = 7,
        hostility = {
            attackPlayers = false,
            attackNPCs = true,
            attackZombies = true,
        },
        affiliation = PNC.FactionTypes.NewAffiliation(),
        recordRevision = 0,
        presenceRevision = 9,
        runtime = {},
        x = 10,
        y = 20,
        z = 0,
    }
    PNC.Registry.Data[id] = record
    return record
end

local looterNPC = npc("npc_looter")
local playerNPC = npc("npc_player_member")
local transferredNPC = npc("npc_transferred_member")
local traderNPC = npc("npc_trader")
local tollLooterNPC = npc("npc_toll_looter")
local settlerNPC = npc("npc_settler")

T.load(SERVER .. "Factions/PNC_FactionService.lua")
T.load(SERVER .. "Factions/PNC_FactionIncidentService.lua")
T.load(SERVER .. "Factions/PNC_FactionBehavior.lua")
T.load(SERVER .. "Factions/PNC_FactionMembershipService.lua")
T.load(SHARED .. "Relationships/PNC_Relationships.lua")
T.load(SHARED .. "Commands/PNC_CompanionCommandRegistry.lua")

local Factions = PNC.Factions
Factions.Load()
local ids = {
    "faction_player",
    "faction_looter",
    "faction_trader",
    "faction_toll_looter",
    "faction_settler",
    "faction_provisional_promote",
    "faction_provisional_join",
    "faction_provisional_death",
}
local idIndex = 0
Factions.IDGenerator = function()
    idIndex = idIndex + 1
    return ids[idIndex]
end

-- Stable player-character identity owns a persistent faction.
local ok, reason, playerFaction =
    Factions.CreatePlayerFaction(player, {
        name = "Patrick Survivors",
        createdAt = hour,
    })
T.truthy(ok, "player faction created")
T.equal(playerFaction.ownerPlayerKey, playerKey,
    "stable player owner key")
T.equal(Factions.GetPlayerFaction(player).id,
    playerFaction.id, "player faction lookup")
T.truthy(Factions.AddPlayerMember(
    playerFaction.id,
    memberKey,
    { actorKey = playerKey }
), "owner adds second player member")
T.equal(Factions.Registry.byPlayerKey[memberKey],
    playerFaction.id, "second player indexed")
T.truthy(Factions.TransferPlayerLeadership(
    playerFaction.id,
    memberKey,
    { actorKey = playerKey }
), "leadership transfers to player member")
T.equal(Factions.Get(playerFaction.id).ownerPlayerKey,
    memberKey, "one transferred player leader")
T.truthy(Factions.TransferPlayerLeadership(
    playerFaction.id,
    playerKey,
    { actorKey = memberKey }
), "leadership transfers back")

local _, _, looterFaction = Factions.Create({
    name = "Mill Looters",
    archetypeID = "looter",
    createdAt = hour,
})
local _, _, traderFaction = Factions.Create({
    name = "Knox Traders",
    archetypeID = "trader",
    createdAt = hour,
})
local _, _, tollLooterFaction = Factions.Create({
    name = "Bridge Toll",
    archetypeID = "looter",
    createdAt = hour,
    tags = {
        settlementType = "looter_toll",
        territorialToll = true,
    },
})
local _, _, settlerFaction = Factions.Create({
    name = "Oakridge Enclave",
    archetypeID = "settler",
    createdAt = hour,
})

-- Looter assignment strips companion ownership and immediately applies
-- its default outsider hostility.
T.truthy(Factions.AddNPC(
    looterFaction.id,
    looterNPC.id,
    { joinedAt = hour }
), "assign looter")
T.equal(looterNPC.tacticalClass, "hostile", "looter tactical class")
T.equal(looterNPC.recruited, false, "looter not companion")
T.equal(looterNPC.ownerUsername, nil, "looter owner cleared")
T.equal(looterNPC.hostility.attackPlayers, true,
    "looter attacks outsiders by default")
T.equal(looterNPC.orderSpec.kind, PNC.Const.ORDER_HOSTILE_HUNT,
    "looter follows hostile hunt policy")
T.truthy(Factions.CanNPCTargetPlayer(looterNPC, player),
    "looter can target player by default")

-- Mobile-group state changes only path/order selection. It must preserve the
-- looter's hostile outsider policy while offering both debug-selectable modes.
Factions.Registry.byID[looterFaction.id].mobile = {
    active = true,
    pathMode = "random",
    site = { home = { x = 300, y = 400, z = 0, radius = 12 } },
}
PNC.FactionBehavior.ApplyNPC(looterNPC, "mobile_random_test")
T.equal(looterNPC.orderSpec.kind, PNC.Const.ORDER_HOSTILE_ROAM,
    "mobile random looters roam locally")
T.equal(looterNPC.hostility.attackPlayers, true,
    "mobile random looters remain aggressive")
Factions.Registry.byID[looterFaction.id].mobile.pathMode = "player"
PNC.FactionBehavior.ApplyNPC(looterNPC, "mobile_player_test")
T.equal(looterNPC.orderSpec.kind, PNC.Const.ORDER_HOSTILE_HUNT,
    "mobile player looters use hostile hunt")
Factions.Registry.byID[looterFaction.id].mobile = nil
PNC.FactionBehavior.ApplyNPC(looterNPC, "mobile_reset_test")

-- A base-owning looter settlement starts in a toll posture. It remains
-- distinct from roaming looter gangs, which retain proactive hostility.
T.truthy(Factions.AddNPC(
    tollLooterFaction.id,
    tollLooterNPC.id,
    { joinedAt = hour }
), "assign territorial toll looter")
T.equal(tollLooterNPC.tacticalClass, "neutral",
    "toll settlement does not start shoot-on-sight")
T.equal(Factions.CanNPCTargetPlayer(tollLooterNPC, player),
    false, "toll settlement awaits escalation")
local tollIntent = PNC.FactionIntent.Resolve({
    archetypeID = "looter",
    policy = tollLooterFaction.policy,
    territorialToll = true,
    targetInsideTerritory = true,
})
T.equal(tollIntent.intent, "threaten",
    "territorial looter requests toll inside base")
T.equal(tollIntent.attackAllowed, false,
    "unrefused toll is nonlethal")
looterNPC.runtime.target = {
    kind = "player",
    player = player,
}
T.truthy(Factions.PacifyForPlayer(
    looterFaction.id,
    playerKey,
    {
        worldAgeHours = hour,
        durationHours = 24,
        reason = "test_bribe",
        sourceNPCID = looterNPC.id,
    }
), "specific player pacified")
T.equal(looterNPC.runtime.target, nil,
    "pacification clears current player target")
T.equal(Factions.CanNPCTargetPlayer(looterNPC, player),
    false, "pacified player is ignored")
local sameAccountOtherCharacter = {
    uuid = "char_other",
    getUsername = function() return "Patrick" end,
    getDisplayName = function() return "Patrick II" end,
    getOnlineID = function() return 8 end,
}
T.truthy(Factions.CanNPCTargetPlayer(
    looterNPC,
    sameAccountOtherCharacter
), "pacification does not transfer to another character UUID")
T.truthy(PNC.FactionBehavior.ResolveIntent(
    looterNPC,
    player,
    { immediateSelfDefense = true }
).attackAllowed, "self-defense remains available")
hour = hour + 25
T.truthy(Factions.CanNPCTargetPlayer(looterNPC, player),
    "expired pacification restores hostility")
hour = hour - 25

-- Player-owned faction membership derives companion ownership.
T.truthy(Factions.AddNPC(
    playerFaction.id,
    playerNPC.id,
    { joinedAt = hour }
), "assign player faction NPC")
T.equal(playerNPC.tacticalClass, "colonist",
    "player member tactical class")
T.equal(playerNPC.recruited, true,
    "player member companion")
T.equal(playerNPC.ownerUsername, "Patrick",
    "player member stable owner")
T.equal(playerNPC.orderSpec.kind, PNC.Const.ORDER_FOLLOW,
    "player member follows owner")
T.truthy(PNC.CompanionCommands.IsOwnedByPlayer(
    playerNPC,
    player
), "owner character can command member")
T.truthy(Factions.AddNPC(
    playerFaction.id,
    transferredNPC.id,
    { joinedAt = hour }
), "assign transfer test companion")
T.equal(transferredNPC.recruited, true,
    "transfer test starts as companion")
local replacementSurvivor = {
    uuid = "char_replacement",
    getUsername = function() return "Patrick" end,
    getOnlineID = function() return 8 end,
}
T.equal(PNC.CompanionCommands.IsOwnedByPlayer(
    playerNPC,
    replacementSurvivor
), false, "same account replacement cannot inherit faction")

-- Non-hostile external factions are neutral until war.
T.truthy(Factions.AddNPC(
    traderFaction.id,
    traderNPC.id,
    { joinedAt = hour }
), "assign trader")
T.equal(traderNPC.tacticalClass, "neutral",
    "trader initially neutral")
T.equal(traderNPC.recruited, false,
    "trader not companion")
T.equal(Factions.CanNPCTargetPlayer(traderNPC, player),
    false, "neutral trader ignores player")

-- A directed personal enemy overrides the faction's neutral outsider policy
-- for this player only; it must not require a faction-wide declaration of war.
traderNPC.social = {
    relationships = {
        [playerKey] = { state = "enemy" },
    },
}
local personalEnemyIntent = PNC.FactionBehavior.ResolveIntent(
    traderNPC,
    player,
    {}
)
T.equal(personalEnemyIntent.reason, "personal_enemy",
    "personal enemy intent reason")
T.truthy(personalEnemyIntent.attackAllowed,
    "personal enemy overrides neutral outsider policy")
T.truthy(Factions.CanNPCTargetPlayer(traderNPC, player),
    "personal enemy enables directed player targeting")
traderNPC.social = nil

-- Settlements use neutral outsider policy unless diplomacy or immediate
-- self-defense explicitly escalates them.
T.truthy(Factions.AddNPC(
    settlerFaction.id,
    settlerNPC.id,
    { joinedAt = hour }
), "assign peaceful settler")
T.equal(settlerNPC.tacticalClass, "neutral",
    "settler is not colored hostile without war")
T.equal(settlerNPC.hostility.attackPlayers, false,
    "settler does not attack neutral outsider")
T.equal(settlerNPC.orderSpec.kind, PNC.Const.ORDER_ROAM,
    "settler receives neutral roam order")

-- War is symmetric, revisioned once, and updates every member's behavior.
local beforeWarRevision = Factions.Registry.revision
T.truthy(Factions.DeclareWar(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour,
        reason = "manual_debug",
        instigatorFactionID = playerFaction.id,
    }
), "declare war")
T.truthy(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), "forward war")
T.truthy(Factions.AreAtWar(
    traderFaction.id,
    playerFaction.id
), "reverse war")
T.equal(traderNPC.tacticalClass, "hostile",
    "war activates aggressive behavior")
T.equal(traderNPC.hostility.attackPlayers, true,
    "war attacks enemy player faction")
T.truthy(PNC.Relationships.AreNPCsEnemies(
    traderNPC,
    playerNPC
), "war NPC targeting")
T.truthy(Factions.CanNPCTargetPlayer(traderNPC, player),
    "war player targeting")
T.equal(Factions.DeclareWar(
    playerFaction.id,
    traderFaction.id,
    { worldAgeHours = hour }
), false, "duplicate war unchanged")
T.equal(Factions.Registry.revision,
    beforeWarRevision + 1, "duplicate war no revision")

-- Moving an existing companion into a faction whose war is already active
-- must immediately replace companion behavior with faction-war behavior.
local broadcastsBeforeTransfer = #broadcasts
T.truthy(Factions.TransferNPC(
    transferredNPC.id,
    traderFaction.id,
    { worldAgeHours = hour }
), "transfer companion into active enemy faction")
T.equal(transferredNPC.tacticalClass, "hostile",
    "transferred member tactical class")
T.equal(transferredNPC.recruited, false,
    "transferred member no longer companion")
T.equal(transferredNPC.ownerUsername, nil,
    "transferred member owner cleared")
T.equal(transferredNPC.hostility.attackPlayers, true,
    "transferred member attacks enemy player faction")
T.equal(transferredNPC.orderSpec.kind,
    PNC.Const.ORDER_HOSTILE_HUNT,
    "transferred member receives hostile hunt order")
T.truthy(Factions.CanNPCTargetPlayer(transferredNPC, player),
    "transferred member can target player immediately")
T.equal(#broadcasts, broadcastsBeforeTransfer + 1,
    "transfer broadcasts live behavior immediately")
T.equal(broadcasts[#broadcasts].reason,
    "faction_transferred",
    "transfer broadcast reason")
traderNPC.runtime.target = {
    kind = "player",
    player = player,
}
traderNPC.runtime.attackAction = { active = true }

-- Peace restores external factions to nonlethal policy.
T.truthy(Factions.MakePeace(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1,
        reason = "manual_debug",
    }
), "make peace")
T.equal(traderNPC.tacticalClass, "neutral",
    "peace restores neutral behavior")
T.equal(Factions.CanNPCTargetPlayer(traderNPC, player),
    false, "peace stops player targeting")
T.equal(traderNPC.runtime.target, nil,
    "peace clears stale faction-war player target")
T.equal(PNC.Relationships.AreNPCsEnemies(
    looterNPC,
    playerNPC
), true, "looter policy is hostile to outsider NPCs")

-- Treaty behavior changes preserve unrelated higher-priority zombie combat.
T.truthy(Factions.DeclareWar(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1.1,
        reason = "manual_debug",
        instigatorFactionID = playerFaction.id,
    }
), "declare second war")
local zombieTarget = {
    kind = "zombie",
    zombieId = 99,
}
traderNPC.runtime.target = zombieTarget
T.truthy(Factions.MakePeace(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1.2,
        reason = "manual_debug",
    }
), "second peace")
T.equal(traderNPC.runtime.target, zombieTarget,
    "peace preserves unrelated zombie target")
T.equal(#PNC.FactionBehavior.ReconciliationQueue, 0,
    "small treaty reconciliation completes immediately")

T.truthy(Factions.DeclareWar(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1.3,
        reason = "manual_debug",
        instigatorFactionID = playerFaction.id,
    }
), "declare self-defense test war")
local activeAttackerTarget = {
    kind = "player",
    player = player,
    targetAggression = true,
}
traderNPC.runtime.target = activeAttackerTarget
T.truthy(Factions.MakePeace(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1.4,
        reason = "manual_debug",
    }
), "self-defense test peace")
T.equal(traderNPC.runtime.target, activeAttackerTarget,
    "peace preserves immediate self-defense target")
traderNPC.runtime.target = {
    kind = "player",
    player = player,
}
T.truthy(Factions.FormAlliance(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1.5,
        instigatorFactionID = playerFaction.id,
        override = true,
    }
), "form alliance for stale target test")
T.equal(traderNPC.runtime.target, nil,
    "alliance clears stale allied target")
T.truthy(Factions.BreakAlliance(
    playerFaction.id,
    traderFaction.id,
    {
        worldAgeHours = hour + 1.6,
        instigatorFactionID = playerFaction.id,
    }
), "break alliance after target test")
T.equal(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), false, "breaking alliance does not declare war")

-- Personal enemy state is reported only by faction authority and does not
-- immediately declare war under the safe default.
T.truthy(Factions.SetLeader(
    traderFaction.id,
    traderNPC.id,
    hour + 1
), "set faction leader")
T.truthy(Factions.OnRelationshipChanged(
    traderNPC,
    playerKey,
    {
        state = "enemy",
        lastEvaluatedAt = hour + 1,
        revision = 1,
    }
), "leader reports personal grievance")
T.equal(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), false, "personal enemy does not force war")

hour = hour + 2
T.truthy(Factions.OnPlayerAggression(
    player,
    traderNPC,
    hour
), "first attack records incident")
T.equal(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), false, "minor attack does not force war")
T.truthy(Factions.OnPlayerAggression(
    player,
    traderNPC,
    hour + 0.001,
    { killed = true }
), "death upgrades attack episode")
T.truthy(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), "member death escalates to war")
T.truthy(Factions.Archive(
    traderFaction.id,
    "test_archive",
    hour + 1
), "archive warring faction")
T.equal(Factions.AreAtWar(
    playerFaction.id,
    traderFaction.id
), false, "archive ends active war")
T.equal(traderNPC.affiliation.factionID, nil,
    "archive removes membership")
T.equal(traderNPC.tacticalClass, "neutral",
    "archived member becomes neutral")
T.equal(looterNPC.presenceRevision, 9,
    "looter behavior leaves presence revision")
T.equal(playerNPC.presenceRevision, 9,
    "player faction behavior leaves presence revision")
T.equal(traderNPC.presenceRevision, 9,
    "war behavior leaves presence revision")

-- Large-pair reconciliation is runtime-only, bounded, and deduplicated.
for index = 1, 20 do
    local record = npc("npc_queue_" .. tostring(index))
    T.truthy(Factions.AddNPC(
        looterFaction.id,
        record.id,
        { joinedAt = hour + 2 }
    ), "queue test member")
end
T.truthy(PNC.FactionBehavior.QueueTreatyReconciliation(
    playerFaction.id,
    looterFaction.id,
    "queue_test",
    hour + 2
), "reconciliation queued")
T.equal(PNC.FactionBehavior.QueueTreatyReconciliation(
    playerFaction.id,
    looterFaction.id,
    "queue_test_duplicate",
    hour + 2
), false, "reconciliation request deduplicated")
T.equal(#PNC.FactionBehavior.ReconciliationQueue, 1,
    "one runtime reconciliation job")
T.equal(PNC.FactionBehavior.PumpReconciliation(5), 5,
    "reconciliation bounded per pump")
T.equal(PNC.FactionBehavior.ReconciliationQueue[1]
    .processedCount, 5, "reconciliation cursor retained")
while #PNC.FactionBehavior.ReconciliationQueue > 0 do
    PNC.FactionBehavior.PumpReconciliation(5)
end
T.equal(#PNC.FactionBehavior.ReconciliationQueue, 0,
    "reconciliation completes")

-- Existing looter factions that already own a settled community are
-- deterministically upgraded to territorial toll behavior on load.
PNC.Communities = {
    GetForFaction = function(factionID)
        if factionID == looterFaction.id then
            return {
                {
                    id = "community_legacy_looter_base",
                    status = "active",
                    mode = "settled",
                },
            }
        end
        return {}
    end,
}
T.equal(Factions.ReconcileTerritorialLooterFactions(), 1,
    "legacy looter settlement reconciled")
T.truthy(Factions.IsTerritorialTollFaction(
    looterFaction.id
), "legacy looter settlement receives toll tag")
T.equal(looterNPC.tacticalClass, "neutral",
    "legacy looter base stops shoot-on-sight behavior")

-- V2 diplomacy migrates to directed relations, emblems, and V6
-- player-scoped pacification storage.
local migrated = PNC.FactionTypes.NormalizeFactionRegistry({
    schemaVersion = 2,
    revision = 3,
    byID = {
        faction_old_a = {
            id = "faction_old_a",
            name = "Old A",
            archetypeID = "settler",
        },
        faction_old_b = {
            id = "faction_old_b",
            name = "Old B",
            archetypeID = "looter",
        },
    },
    diplomacy = {
        ["faction_old_a|faction_old_b"] = {
            factionAID = "faction_old_a",
            factionBID = "faction_old_b",
            state = "war",
            changedAt = 20,
            revision = 2,
        },
    },
})
T.equal(migrated.schemaVersion, 6, "registry migrated to V6")
T.truthy(type(migrated.byPlayerKey) == "table",
    "player index added")
T.equal(migrated.diplomacy, nil,
    "legacy pair table removed")
T.truthy(migrated.byID.faction_old_a
    .relations.faction_old_b.atWar,
    "forward war migrated")
T.truthy(migrated.byID.faction_old_b
    .relations.faction_old_a.atWar,
    "reverse war migrated")
T.truthy(#migrated.byID.faction_old_a.emblem.layers > 0,
    "old faction receives deterministic emblem")
T.truthy(type(migrated.byID.faction_old_a
    .playerPacifications) == "table",
    "old faction receives pacification table")
T.truthy(PNC.FactionTypes.AreEqual(
    migrated,
    PNC.FactionTypes.NormalizeFactionRegistry(migrated)
), "V6 faction migration idempotent")

local memberSnapshot = PNC.FactionMembership.BuildSnapshot(player)
T.equal(memberSnapshot.faction.id, playerFaction.id,
    "membership snapshot is scoped to actor faction")
T.equal(memberSnapshot.canManage, true,
    "faction owner can manage players")
T.equal(#memberSnapshot.playerMembers, 2,
    "membership snapshot lists player members")
T.equal(#memberSnapshot.availablePlayers, 1,
    "membership snapshot lists eligible online player")
memberSnapshot = PNC.FactionMembership.PerformAction(player, {
    memberAction = "add_player",
    playerKey = "player:Morgan:char_join",
})
T.equal(memberSnapshot.actionResult.ok, true,
    "membership channel adds selected player")
T.equal(#memberSnapshot.playerMembers, 3,
    "added player appears in snapshot")
memberSnapshot = PNC.FactionMembership.PerformAction(player, {
    memberAction = "banish_player",
    playerKey = "player:Morgan:char_join",
})
T.equal(memberSnapshot.actionResult.ok, true,
    "membership channel banishes selected player")
T.equal(Factions.Registry.byPlayerKey[
    "player:Morgan:char_join"
], nil, "banished player index removed")
saveSafe(memberSnapshot)

-- Player-character death removes the dead UUID. A living player member
-- succeeds first; when no player successor remains, the organization becomes
-- a neutral refugee faction instead of lingering as a duplicate player
-- faction.
PNC.PlayerCharacters.Registry.byUUID.char_player.status = "dead"
T.truthy(Factions.HandlePlayerCharacterDeath(
    playerKey,
    hour + 3
), "dead owner reconciled")
T.equal(Factions.Get(playerFaction.id).ownerPlayerKey,
    memberKey, "living player member succeeds")
T.equal(Factions.Registry.byPlayerKey[playerKey], nil,
    "dead player faction index removed")
PNC.PlayerCharacters.Registry.byUUID.char_member.status = "dead"
T.truthy(Factions.HandlePlayerCharacterDeath(
    memberKey,
    hour + 4
), "last player leader reconciled")
local refugeeFaction = Factions.Get(playerFaction.id)
T.equal(refugeeFaction.ownerPlayerKey, nil,
    "refugee faction has no player owner")
T.equal(refugeeFaction.archetypeID, "refugee",
    "orphaned player faction becomes refugees")
T.equal(refugeeFaction.name, "Patrick Refugees",
    "orphaned faction receives distinct refugee name")
T.equal(Factions.Registry.byPlayerKey[memberKey], nil,
    "last dead player faction index removed")
T.equal(playerNPC.affiliation.factionID, playerFaction.id,
    "surviving NPC remains with refugee faction")
T.equal(playerNPC.tacticalClass, "neutral",
    "former companion becomes neutral refugee")
T.equal(playerNPC.recruited, false,
    "former companion is no longer recruited")
T.equal(playerNPC.presenceRevision, 9,
    "player death reconciliation leaves presence revision")
local reconciledRevision = Factions.Registry.revision
T.equal(Factions.ReconcilePlayerMemberships(hour + 5), 0,
    "repeat player membership reconciliation is idempotent")
T.equal(Factions.Registry.revision, reconciledRevision,
    "idempotent reconciliation leaves registry revision")

-- Every active character can own a hidden diplomacy container without
-- appearing to have founded a playable faction. Founding promotes that same
-- record so accumulated diplomacy is not discarded.
local provisionalPlayer = {
    uuid = "char_provisional",
    getUsername = function() return "Taylor" end,
    getDisplayName = function() return "Taylor" end,
}
PNC.PlayerCharacters.Registry.byUUID.char_provisional = {
    uuid = "char_provisional",
    accountIdentity = "Taylor",
    displayName = "Taylor",
    status = "active",
}
T.truthy(Factions.EnsurePlayerDiplomacyFaction(
    provisionalPlayer,
    { worldAgeHours = hour + 6 }
), "provisional diplomacy faction created")
local provisionalKey =
    "player:Taylor:char_provisional"
local provisional =
    Factions.GetDiplomacyFactionForPlayerKey(provisionalKey)
T.truthy(Factions.IsProvisionalPlayerFaction(provisional),
    "diplomacy container is provisional")
T.equal(Factions.GetFactionForPlayerKey(provisionalKey), nil,
    "provisional container is not a playable faction")
local visibleBeforePromotion = #Factions.List()
local promotedOK, promotedReason, promoted =
    Factions.CreatePlayerFaction(provisionalPlayer, {
        name = "Taylor Union",
        createdAt = hour + 7,
    })
T.truthy(promotedOK, "provisional faction promoted")
T.equal(promotedReason, "promoted_provisional",
    "promotion result is explicit")
T.equal(promoted.id, provisional.id,
    "promotion preserves diplomacy faction identity")
T.equal(#Factions.List(), visibleBeforePromotion + 1,
    "promoted faction becomes visible")

local joiningPlayer = {
    uuid = "char_provisional_join",
    getUsername = function() return "Casey" end,
    getDisplayName = function() return "Casey" end,
}
PNC.PlayerCharacters.Registry.byUUID.char_provisional_join = {
    uuid = "char_provisional_join",
    accountIdentity = "Casey",
    displayName = "Casey",
    status = "active",
}
T.truthy(Factions.EnsurePlayerDiplomacyFaction(
    joiningPlayer,
    { worldAgeHours = hour + 7.2 }
), "joining player provisional container created")
local joiningKey = "player:Casey:char_provisional_join"
local joiningProvisional =
    Factions.GetDiplomacyFactionForPlayerKey(joiningKey)
T.truthy(Factions.AddPlayerMember(
    promoted.id,
    joiningKey,
    {
        actorKey = provisionalKey,
        worldAgeHours = hour + 7.3,
    }
), "provisional player joins founded faction")
T.equal(Factions.GetFactionForPlayerKey(joiningKey).id,
    promoted.id, "joining player receives actual membership")
T.equal(Factions.Get(joiningProvisional.id).status,
    "archived", "joining retires provisional container")

local doomedPlayer = {
    uuid = "char_provisional_dead",
    getUsername = function() return "Robin" end,
    getDisplayName = function() return "Robin" end,
}
PNC.PlayerCharacters.Registry.byUUID.char_provisional_dead = {
    uuid = "char_provisional_dead",
    accountIdentity = "Robin",
    displayName = "Robin",
    status = "active",
}
T.truthy(Factions.EnsurePlayerDiplomacyFaction(
    doomedPlayer,
    { worldAgeHours = hour + 8 }
), "second provisional container created")
local doomedKey = "player:Robin:char_provisional_dead"
local doomed = Factions.GetDiplomacyFactionForPlayerKey(
    doomedKey
)
PNC.PlayerCharacters.Registry.byUUID
    .char_provisional_dead.status = "dead"
local retiredOK, retiredReason =
    Factions.HandlePlayerCharacterDeath(
        doomedKey,
        hour + 9
    )
T.truthy(retiredOK, "dead provisional player reconciled")
T.equal(retiredReason, "provisional_retired",
    "provisional death does not create refugees")
T.equal(Factions.Registry.byPlayerKey[doomedKey], nil,
    "dead provisional identity index removed")
T.equal(Factions.Get(doomed.id).status, "archived",
    "dead provisional container archived")
saveSafe(Factions.Registry)
T.finish("pnc_faction_warfare_smoke")

T.finish("pnc_faction_warfare_smoke")
