local T = require "tests/support/test"

local SHARED =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

local function validatePersistedValue(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "string"
        or kind == "number" or kind == "boolean"
    then
        return
    end
    if kind ~= "table" or getmetatable(value) ~= nil then
        error("unsafe persisted faction value: " .. kind)
    end
    seen = seen or {}
    if seen[value] then error("cycle in faction data") end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe faction key")
        end
        validatePersistedValue(item, seen)
    end
    seen[value] = nil
end

local worldHour = 100
local globalData = {}

function isClient() return false end
function isServer() return true end
function getTimeInMillis() return worldHour * 3600000 end
function ZombRand() return 7 end
function getGameTime()
    return {
        getWorldAgeHours = function() return worldHour end,
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
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED .. "Factions/PNC_FactionArchetypes.lua")
T.load(SHARED .. "Factions/PNC_FactionEmblems.lua")
T.load(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
T.load(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
T.load(SHARED .. "Factions/PNC_FactionTypes.lua")

local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local Constants = PNC.FactionConstants

local dirty = {}
PNC.Registry = {
    Data = {},
    DirtyByID = dirty,
}
function PNC.Registry.Get(id)
    return PNC.Registry.Data[tostring(id)]
end
function PNC.Registry.EnsureLoaded() return true end
function PNC.Registry.MarkDirty(record, domain)
    if not dirty[record.id] then
        record.recordRevision =
            (tonumber(record.recordRevision) or 0) + 1
    end
    dirty[record.id] = true
    return domain ~= nil
end

local function resetDirty()
    dirty = {}
    PNC.Registry.DirtyByID = dirty
end

local function newNPC(id, legacyFaction)
    local record = {
        id = id,
        name = id,
        alive = true,
        faction = legacyFaction or "neutral",
        hostility = {
            attackPlayers = legacyFaction == "hostile",
            attackNPCs = true,
        },
        recruited = legacyFaction == "colonist",
        affiliation = Types.NewAffiliation(),
        recordRevision = 0,
        presenceRevision = 3,
        social = {
            revision = 4,
            relationships = {
                ["npc:history"] = { revision = 5 },
            },
            conduct = { revision = 6 },
            personality = { compassion = 50 },
        },
    }
    PNC.Registry.Data[id] = record
    return record
end

-- 1-4. Pure defaults and all four data-only archetypes.
local registryDefault = Types.NewFactionRegistry()
T.equal(registryDefault.schemaVersion, 6, "registry schema")
T.equal(registryDefault.revision, 0, "registry revision")
T.equal(next(registryDefault.byID), nil, "registry starts empty")
local affiliationDefault = Types.NewAffiliation()
T.equal(affiliationDefault.schemaVersion, 2, "affiliation schema")
T.equal(affiliationDefault.membershipStatus,
    "unaffiliated", "default status")
T.equal(affiliationDefault.role, "civilian", "default role")
T.equal(affiliationDefault.rank, "member", "default rank")
for _, id in ipairs({ "settler", "looter", "trader", "refugee" }) do
    local definition = Archetypes.Get(id)
    T.truthy(definition ~= nil, "archetype " .. id)
    T.truthy(definition.allowedRoles[definition.defaultRole],
        "valid default role " .. id)
    T.equal(definition.attackPlayers, nil,
        "archetype has no hostility " .. id)
end

T.load(SERVER .. "Factions/PNC_FactionService.lua")
T.load(SERVER .. "Factions/PNC_FactionLeadership.lua")
local Factions = PNC.Factions
Factions.Load()

-- 5-10. IDs are generated, collision checked, and indexed.
local generated = {
    "faction_collision",
    "faction_collision",
    "faction_settlement",
    "faction_looters",
    "faction_traders",
    "faction_refugees",
}
local generatedIndex = 0
Factions.IDGenerator = function()
    generatedIndex = generatedIndex + 1
    return generated[generatedIndex] or "faction_extra_"
        .. tostring(generatedIndex)
end
local ok, reason, settlement = Factions.Create({
    name = "Riverside Cooperative",
    archetypeID = "settler",
    createdAt = 100,
})
T.truthy(ok, "settlement creation")
T.equal(settlement.id, "faction_collision", "first generated ID")
ok, reason, settlement = Factions.Create({
    name = "Second Settlement",
    archetypeID = "settler",
    createdAt = 100,
})
T.truthy(ok, "collision retry creation")
T.equal(settlement.id, "faction_settlement",
    "collision skipped")
local settlementID = settlement.id
local _, _, looters = Factions.Create({
    name = "Old Mill Crew",
    archetypeID = "looter",
    createdAt = 100,
})
local looterID = looters.id
local _, _, traders = Factions.Create({
    name = "Knox Exchange",
    archetypeID = "trader",
    createdAt = 100,
})
local traderID = traders.id
local _, _, refugees = Factions.Create({
    name = "Crossroads Group",
    archetypeID = "refugee",
    createdAt = 100,
})
local refugeeID = refugees.id
T.truthy(Factions.Registry.byArchetype.settler[settlementID],
    "settler secondary index")
local beforeBadCreate = Factions.Registry.revision
T.falsy(Factions.Create({
    name = "",
    archetypeID = "settler",
}), "empty name rejected")
T.falsy(Factions.Create({
    name = "Unknown",
    archetypeID = "military",
}), "unknown archetype rejected")
T.equal(Factions.Registry.revision, beforeBadCreate,
    "rejected creates do not revise")

-- Bounded collision failure.
local originalGenerator = Factions.IDGenerator
Factions.IDGenerator = function() return settlementID end
T.equal(Factions.GenerateID(), nil, "bounded collisions fail")
Factions.IDGenerator = originalGenerator

-- 11-12. Reads are copies and revision-neutral.
local readRevision = Factions.Registry.revision
local copiedFaction = Factions.Get(settlementID)
copiedFaction.name = "mutated copy"
T.equal(Factions.Get(settlementID).name,
    "Second Settlement", "faction read copy")
Factions.List()
Factions.GetByArchetype("settler")
T.equal(Factions.Registry.revision, readRevision,
    "pure faction reads")

-- Persistent emblem edits are normalized and revision-aware.
local emblemFactionBefore = Factions.Get(settlementID)
local emblemRegistryBefore = Factions.Registry.revision
ok, reason = Factions.SetEmblem(settlementID, {
    backgroundColorID = "red",
    layers = {
        {
            symbolID = "Skull",
            colorID = "white",
            scale = 0.95,
        },
    },
})
T.truthy(ok, "emblem mutation")
local emblemFactionAfter = Factions.Get(settlementID)
T.equal(emblemFactionAfter.emblem.backgroundColorID,
    "red", "emblem persisted")
T.equal(emblemFactionAfter.revision,
    emblemFactionBefore.revision + 1,
    "emblem touches faction")
T.equal(Factions.Registry.revision,
    emblemRegistryBefore + 1,
    "emblem touches registry")
local unchangedRegistry = Factions.Registry.revision
ok, reason = Factions.SetEmblem(
    settlementID,
    emblemFactionAfter.emblem
)
T.truthy(ok, "identical emblem accepted")
T.equal(reason, "unchanged",
    "identical emblem is revision-neutral")
T.equal(Factions.Registry.revision,
    unchangedRegistry,
    "identical emblem does not touch registry")

-- 13-18. Membership is separate from every legacy behavior field.
local alice = newNPC("npc_alice", "hostile")
local bob = newNPC("npc_bob", "neutral")
local cara = newNPC("npc_cara", "neutral")
local dana = newNPC("npc_dana", "neutral")
local aliceLegacy = {
    faction = alice.faction,
    attackPlayers = alice.hostility.attackPlayers,
    attackNPCs = alice.hostility.attackNPCs,
    recruited = alice.recruited,
    presenceRevision = alice.presenceRevision,
    socialRevision = alice.social.revision,
    relationshipRevision =
        alice.social.relationships["npc:history"].revision,
    conductRevision = alice.social.conduct.revision,
}
resetDirty()
ok, reason = Factions.AddNPC(settlementID, alice.id, {
    membershipStatus = "member",
    role = "guard",
    rank = "officer",
    joinedAt = 101,
})
T.truthy(ok, "add NPC")
T.equal(alice.affiliation.factionID, settlementID,
    "assigned faction")
T.equal(alice.affiliation.membershipStatus, "member",
    "assigned status")
T.equal(alice.affiliation.role, "guard", "assigned role")
T.equal(alice.affiliation.rank, "officer", "assigned rank")
T.truthy(Factions.Registry.byID[settlementID]
    .memberIDs[alice.id], "member index")
T.equal(alice.faction, aliceLegacy.faction,
    "legacy faction unchanged")
T.equal(alice.hostility.attackPlayers,
    aliceLegacy.attackPlayers, "attackPlayers unchanged")
T.equal(alice.hostility.attackNPCs,
    aliceLegacy.attackNPCs, "attackNPCs unchanged")
T.equal(alice.recruited, aliceLegacy.recruited,
    "recruitment unchanged")
T.equal(alice.presenceRevision,
    aliceLegacy.presenceRevision, "presence unchanged")
T.equal(alice.social.revision,
    aliceLegacy.socialRevision, "social unchanged")
T.equal(alice.social.relationships["npc:history"].revision,
    aliceLegacy.relationshipRevision, "relationship unchanged")
T.equal(alice.social.conduct.revision,
    aliceLegacy.conductRevision, "conduct unchanged")

local rejectedRevision = Factions.Registry.revision
local rejectedRecordRevision = alice.recordRevision
T.falsy(Factions.AddNPC(looterID, alice.id, {}),
    "dual membership rejected")
T.equal(Factions.Registry.revision, rejectedRevision,
    "dual membership registry revision")
T.equal(alice.recordRevision, rejectedRecordRevision,
    "dual membership record revision")

-- 19-25. Transfer is atomic, historical, and role-aware.
resetDirty()
ok, reason = Factions.TransferNPC(
    alice.id,
    traderID,
    {
        role = "guard",
        rank = "senior",
        worldAgeHours = 120,
    }
)
T.truthy(ok, "transfer")
T.equal(alice.affiliation.factionID, traderID,
    "transfer destination")
T.equal(alice.affiliation.role, "guard",
    "trader permits guard")
T.equal(#alice.affiliation.formerFactionIDs, 1,
    "transfer history")
T.equal(alice.affiliation.formerFactionIDs[1].factionID,
    settlementID, "former faction")
T.equal(alice.affiliation.formerFactionIDs[1].reason,
    "transferred", "transfer reason")
T.falsy(Factions.Registry.byID[settlementID]
    .memberIDs[alice.id] == true, "source index removed")
T.truthy(Factions.Registry.byID[traderID]
    .memberIDs[alice.id], "destination index added")
T.truthy(Factions.AddNPC(refugeeID, cara.id, {
    role = "medic",
}), "refugee permits medic")
T.falsy(Factions.SetNPCRole(cara.id, "raider"),
    "invalid archetype role rejected")

-- Bounded former history keeps the newest deterministic entries.
local history = {}
for index = 1, 12 do
    history[#history + 1] = {
        factionID = "faction_history_" .. tostring(index),
        joinedAt = index,
        leftAt = index + 1,
        reason = "left",
    }
end
local bounded = Types.NormalizeAffiliation({
    formerFactionIDs = history,
})
T.equal(#bounded.formerFactionIDs,
    Constants.FORMER_FACTION_LIMIT, "history bound")
T.equal(bounded.formerFactionIDs[1].factionID,
    "faction_history_5", "oldest history removed")

-- 32-37. Leadership requires membership and demotes/reconciles safely.
T.falsy(Factions.SetLeader(traderID, bob.id, 121),
    "leader must be member")
T.truthy(Factions.AddNPC(traderID, bob.id, {
    role = "trader",
}), "add first leader candidate")
T.truthy(Factions.SetLeader(traderID, bob.id, 121),
    "set leader")
T.equal(Factions.Get(traderID).leaderNPCID,
    bob.id, "leader ID")
T.equal(bob.affiliation.role, "leader", "leader role")
T.equal(bob.affiliation.rank, "leader", "leader rank")
T.truthy(Factions.AddNPC(traderID, dana.id, {
    role = "mechanic",
}), "add second leader candidate")
T.truthy(Factions.SetLeader(traderID, dana.id, 122),
    "replace leader")
T.equal(bob.affiliation.rank, "member",
    "old leader demoted")
T.equal(bob.affiliation.role, "civilian",
    "old leader safe role")
T.truthy(Factions.RemoveNPC(
    traderID,
    dana.id,
    "removed",
    123
), "remove leader")
T.equal(Factions.Get(traderID).leaderNPCID,
    alice.id, "AI factions select the highest-ranked successor")
alice.alive = false
T.truthy(Factions.OnNPCDeath(alice.id),
    "death reconciliation")
T.equal(Factions.Get(traderID).leaderNPCID,
    bob.id, "death promotes the next eligible AI leader")
T.truthy(Factions.Get(traderID).memberIDs[alice.id],
    "death hook only changes leadership")
T.equal(Factions.Get(traderID).status,
    "active", "death does not archive")
alice.alive = true
T.truthy(Factions.TransferNPC(bob.id, refugeeID, {
    role = "guard",
    membershipStatus = "member",
    worldAgeHours = 124,
}), "recruitment-style transfer succeeds")
T.equal(Factions.Get(traderID).leaderNPCID,
    alice.id, "transferred AI leader is replaced")

-- 38-40. Archive preserves identity and removes affiliations.
T.truthy(Factions.SetLeader(
    refugeeID,
    cara.id,
    125
), "refugee leader")
local archivedID = refugeeID
T.truthy(Factions.Archive(
    archivedID,
    "test_archive",
    130
), "archive")
local archived = Factions.Get(archivedID)
T.equal(archived.status, "archived", "archived status")
T.equal(archived.leaderNPCID, nil, "archived leader")
T.equal(next(archived.memberIDs), nil, "archived members")
T.equal(cara.affiliation.factionID, nil,
    "archival removes affiliation")
T.equal(cara.affiliation.formerFactionIDs[
    #cara.affiliation.formerFactionIDs
].reason, "faction_archived", "archive history")
Factions.IDGenerator = function() return archivedID end
T.equal(Factions.GenerateID(), nil,
    "archived ID never reused")
Factions.IDGenerator = originalGenerator

-- 41-47. Repair and migration are deterministic and invent no membership.
local malformedAffiliation = Types.NormalizeAffiliation({
    factionID = "invalid",
    membershipStatus = "member",
    role = "raider",
    rank = "chief",
    joinedAt = 0 / 0,
})
T.equal(malformedAffiliation.factionID, nil,
    "invalid affiliation reference")
T.equal(malformedAffiliation.membershipStatus,
    "unaffiliated", "invalid affiliation status")
local normalizedOnce = Types.NormalizeFactionRegistry({
    schemaVersion = 99,
    revision = 3,
    byID = {
        [settlementID] = {
            id = "faction_wrong",
            name = "Repaired",
            archetypeID = "settler",
            status = "active",
            memberIDs = { ghost = true },
        },
    },
    byArchetype = { wrong = { ghost = true } },
})
local normalizedTwice =
    Types.NormalizeFactionRegistry(normalizedOnce)
T.truthy(Types.AreEqual(normalizedOnce, normalizedTwice),
    "registry normalization idempotent")
T.truthy(normalizedOnce.byArchetype.settler[settlementID],
    "archetype rebuilt")

Factions.Registry.byID[settlementID].memberIDs = {
    ghost = true,
}
Factions.Registry.byArchetype = {}
local orphan = newNPC("npc_orphan", "neutral")
orphan.affiliation = Types.NormalizeAffiliation({
    factionID = "faction_missing",
    membershipStatus = "member",
    role = "civilian",
    rank = "member",
    joinedAt = 90,
})
local rebuildRevision = Factions.Registry.revision
T.truthy(Factions.RebuildIndexes(), "index repair")
T.equal(Factions.Registry.byID[settlementID]
    .memberIDs.ghost, nil, "ghost member removed")
T.truthy(Factions.Registry.byArchetype.settler[
    settlementID], "archetype index repaired")
T.equal(orphan.affiliation.factionID, nil,
    "missing faction reference cleared")
T.equal(#orphan.affiliation.formerFactionIDs, 1,
    "missing faction reference quarantined in history")
T.equal(Factions.Registry.revision, rebuildRevision,
    "repair does not revise")
T.falsy(Factions.RebuildIndexes(),
    "correct index rebuild unchanged")

-- 51-55. Mutations advance only faction/affiliation record domains.
local beforeAffiliation = alice.affiliation.revision
local beforePresence = alice.presenceRevision
local beforeSocial = alice.social.revision
resetDirty()
T.truthy(Factions.SetNPCRank(alice.id, "officer"),
    "rank mutation")
T.equal(alice.affiliation.revision,
    beforeAffiliation + 1, "affiliation revision")
T.equal(alice.recordRevision,
    rejectedRecordRevision + 2,
    "record revision logical mutation")
T.equal(alice.presenceRevision, beforePresence,
    "rank presence unchanged")
T.equal(alice.social.revision, beforeSocial,
    "rank social unchanged")
local unchangedRegistry = Factions.Registry.revision
local unchangedRecord = alice.recordRevision
T.falsy(Factions.SetNPCRank(alice.id, "officer"),
    "identical rank unchanged")
T.equal(Factions.Registry.revision, unchangedRegistry,
    "identical rank registry revision")
T.equal(alice.recordRevision, unchangedRecord,
    "identical rank record revision")

-- Automatically founded player factions use the character surname, retain a
-- flavor suffix, and keep the one-time naming prompt pending until confirmed.
local automaticPlayerKey = "player:MorganAccount:char_default_name"
local automaticPlayer = {
    getDisplayName = function() return "Alex Morgan" end,
    getDescriptor = function()
        return { getSurname = function() return "Morgan" end }
    end,
}
PNC.PlayerCharacters = {
    GetEntityKey = function() return automaticPlayerKey, "resolved" end,
}
local automaticOK, _, automaticFaction = Factions.EnsurePlayerFaction(
    automaticPlayer, { worldAgeHours = worldHour }
)
T.truthy(automaticOK, "automatic player faction creation")
T.equal(automaticFaction.name, "Morgan Kin",
    "automatic faction surname and flavor")
T.equal(automaticFaction.tags.factionNamePending, true,
    "automatic faction name pending")
local renameOK, _, renamedFaction = Factions.SetPlayerFactionName(
    automaticPlayer, "Morgan Wardens"
)
T.truthy(renameOK, "player faction rename")
T.equal(renamedFaction.name, "Morgan Wardens", "renamed faction")
T.equal(renamedFaction.tags.factionNamePending, nil,
    "rename clears faction prompt")
T.equal(renamedFaction.tags.factionNameConfirmed, true,
    "rename records faction name confirmation")
local existingOK, _, existingFaction = Factions.EnsurePlayerFaction(
    automaticPlayer, { worldAgeHours = worldHour }
)
T.truthy(existingOK, "confirmed player faction remains available")
T.equal(existingFaction.tags.factionNamePending, nil,
    "confirmed faction does not prompt again")

-- 56-60. Debug formatting/snapshots are primitive-only.
local debugPlayerKey = "player:Patrick:char_debug"
Factions.GetFactionForPlayerKey = function()
    return nil
end
PNC.PlayerCharacters = {
    GetEntityKey = function()
        return debugPlayerKey
    end,
}
PNC.Relationships = {
    Get = function(npcID, targetKey)
        if npcID == alice.id
            and targetKey == debugPlayerKey
        then
            return {
                approval = 9,
                respect = 6,
                familiarity = 4,
                state = "unknown",
                previousState = "unknown",
                revision = 2,
                lastInteractionAt = 100,
            }
        end
        return nil
    end,
}
alice.runtime = alice.runtime or {}
alice.runtime.relationshipDebugChanges = {
    {
        sequence = 1,
        targetKey = debugPlayerKey,
        kind = "social_event",
        memoryType = "treated_wound",
        approvalDelta = 4,
        respectDelta = 2,
        familiarityDelta = 2,
        moraleDelta = 2,
        stateBefore = "unknown",
        stateAfter = "unknown",
    },
}
T.load(SERVER .. "Factions/PNC_FactionDebug.lua")
T.truthy(string.find(
    PNC.FactionDebug.FormatList(),
    "Second Settlement",
    1, true
) ~= nil, "debug list formatting")
T.truthy(string.find(
    PNC.FactionDebug.FormatFaction(traderID),
    "Knox Exchange",
    1, true
) ~= nil, "debug detail formatting")
T.truthy(string.find(
    PNC.FactionDebug.FormatMembers(traderID),
    "npc_alice",
    1, true
) ~= nil, "debug member formatting")
local debugSnapshot =
    PNC.FactionDebug.BuildSnapshot(
        traderID,
        alice.id,
        nil,
        {}
    )
validatePersistedValue(debugSnapshot)
T.equal(debugSnapshot.roster[1].inventory,
    nil, "debug excludes inventory")
T.equal(
    #debugSnapshot.npcDiagnostics,
    #debugSnapshot.roster,
    "debug includes one primitive diagnostic per living NPC"
)
T.equal(
    debugSnapshot.npcDiagnostics[1].presenceRevision
        ~= nil,
    true,
    "debug diagnostic includes revision evidence"
)
local aliceDiagnostic
for _, diagnostic in ipairs(
    debugSnapshot.npcDiagnostics
) do
    if diagnostic.npcID == alice.id then
        aliceDiagnostic = diagnostic
        break
    end
end
T.equal(aliceDiagnostic.relationship.approval, 9,
    "debug diagnostic includes player relationship")
T.equal(
    aliceDiagnostic.relationshipChanges[1].memoryType,
    "treated_wound",
    "debug diagnostic includes relationship change type"
)

-- Guarded GUI diagnostics toggle changes runtime config only.
PNC.FactionTelemetry = {
    BuildSnapshot = function()
        return {
            enabled = PNC.Config.Factions
                .EnableValidationTelemetry == true,
            count = 0,
            maximum = 512,
            entries = {},
        }
    end,
}
PNC.Config.Factions.EnableValidationTelemetry = false
local enabledDiagnostics =
    PNC.FactionDebug.PerformAction(nil, {
        factionAction = "telemetry_toggle",
        factionID = traderID,
        npcID = alice.id,
    })
T.truthy(
    PNC.Config.Factions.EnableValidationTelemetry,
    "debug GUI enables runtime telemetry"
)
T.truthy(
    enabledDiagnostics.actionResult.ok,
    "enable telemetry action succeeds"
)
local disabledDiagnostics =
    PNC.FactionDebug.PerformAction(nil, {
        factionAction = "telemetry_toggle",
        factionID = traderID,
        npcID = alice.id,
    })
T.falsy(
    PNC.Config.Factions.EnableValidationTelemetry,
    "debug GUI disables runtime telemetry"
)
T.equal(
    disabledDiagnostics.actionResult.reason,
    "telemetry_disabled",
    "disable telemetry result"
)

-- Save/load registry remains primitive-only and copy-safe.
T.truthy(Factions.Save(), "faction save")
validatePersistedValue(globalData.PNC_Factions)
Factions.Loaded = false
T.truthy(Factions.Load(), "faction reload")
T.truthy(Factions.Get(traderID) ~= nil,
    "faction persists")
T.equal(Factions.GetNPCAffiliation(alice.id).factionID,
    traderID, "membership persists")
T.finish("pnc_factions_foundation_smoke")

T.finish("pnc_factions_foundation_smoke")
