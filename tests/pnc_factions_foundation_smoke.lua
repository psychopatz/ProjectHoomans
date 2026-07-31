local SHARED =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER =
    "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function assertTrue(value, label)
    assertEqual(value == true, true, label)
end

local function assertFalse(value, label)
    assertEqual(value == false, true, label)
end

local function assertSaveSafe(value, seen)
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
        assertSaveSafe(item, seen)
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
dofile(SHARED .. "Base/PNC_Core.lua")
dofile(SHARED .. "Factions/PNC_FactionConstants.lua")
dofile(SHARED .. "Factions/PNC_FactionArchetypes.lua")
dofile(SHARED .. "Factions/PNC_FactionEmblems.lua")
dofile(SHARED .. "Factions/PNC_FactionDiplomacyMath.lua")
dofile(SHARED .. "Factions/PNC_FactionIncidentDefinitions.lua")
dofile(SHARED .. "Factions/PNC_FactionTypes.lua")

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
assertEqual(registryDefault.schemaVersion, 4, "registry schema")
assertEqual(registryDefault.revision, 0, "registry revision")
assertEqual(next(registryDefault.byID), nil, "registry starts empty")
local affiliationDefault = Types.NewAffiliation()
assertEqual(affiliationDefault.schemaVersion, 2, "affiliation schema")
assertEqual(affiliationDefault.membershipStatus,
    "unaffiliated", "default status")
assertEqual(affiliationDefault.role, "civilian", "default role")
assertEqual(affiliationDefault.rank, "member", "default rank")
for _, id in ipairs({ "settler", "looter", "trader", "refugee" }) do
    local definition = Archetypes.Get(id)
    assertTrue(definition ~= nil, "archetype " .. id)
    assertTrue(definition.allowedRoles[definition.defaultRole],
        "valid default role " .. id)
    assertEqual(definition.attackPlayers, nil,
        "archetype has no hostility " .. id)
end

dofile(SERVER .. "PNC_FactionService.lua")
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
assertTrue(ok, "settlement creation")
assertEqual(settlement.id, "faction_collision", "first generated ID")
ok, reason, settlement = Factions.Create({
    name = "Second Settlement",
    archetypeID = "settler",
    createdAt = 100,
})
assertTrue(ok, "collision retry creation")
assertEqual(settlement.id, "faction_settlement",
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
assertTrue(Factions.Registry.byArchetype.settler[settlementID],
    "settler secondary index")
local beforeBadCreate = Factions.Registry.revision
assertFalse(Factions.Create({
    name = "",
    archetypeID = "settler",
}), "empty name rejected")
assertFalse(Factions.Create({
    name = "Unknown",
    archetypeID = "military",
}), "unknown archetype rejected")
assertEqual(Factions.Registry.revision, beforeBadCreate,
    "rejected creates do not revise")

-- Bounded collision failure.
local originalGenerator = Factions.IDGenerator
Factions.IDGenerator = function() return settlementID end
assertEqual(Factions.GenerateID(), nil, "bounded collisions fail")
Factions.IDGenerator = originalGenerator

-- 11-12. Reads are copies and revision-neutral.
local readRevision = Factions.Registry.revision
local copiedFaction = Factions.Get(settlementID)
copiedFaction.name = "mutated copy"
assertEqual(Factions.Get(settlementID).name,
    "Second Settlement", "faction read copy")
Factions.List()
Factions.GetByArchetype("settler")
assertEqual(Factions.Registry.revision, readRevision,
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
assertTrue(ok, "emblem mutation")
local emblemFactionAfter = Factions.Get(settlementID)
assertEqual(emblemFactionAfter.emblem.backgroundColorID,
    "red", "emblem persisted")
assertEqual(emblemFactionAfter.revision,
    emblemFactionBefore.revision + 1,
    "emblem touches faction")
assertEqual(Factions.Registry.revision,
    emblemRegistryBefore + 1,
    "emblem touches registry")
local unchangedRegistry = Factions.Registry.revision
ok, reason = Factions.SetEmblem(
    settlementID,
    emblemFactionAfter.emblem
)
assertTrue(ok, "identical emblem accepted")
assertEqual(reason, "unchanged",
    "identical emblem is revision-neutral")
assertEqual(Factions.Registry.revision,
    unchangedRegistry,
    "identical emblem does not touch registry")

-- 13-18. Membership is separate from every legacy behavior field.
local alice = newNPC("npc_alice", "hostile")
local bob = newNPC("npc_bob", "colonist")
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
assertTrue(ok, "add NPC")
assertEqual(alice.affiliation.factionID, settlementID,
    "assigned faction")
assertEqual(alice.affiliation.membershipStatus, "member",
    "assigned status")
assertEqual(alice.affiliation.role, "guard", "assigned role")
assertEqual(alice.affiliation.rank, "officer", "assigned rank")
assertTrue(Factions.Registry.byID[settlementID]
    .memberIDs[alice.id], "member index")
assertEqual(alice.faction, aliceLegacy.faction,
    "legacy faction unchanged")
assertEqual(alice.hostility.attackPlayers,
    aliceLegacy.attackPlayers, "attackPlayers unchanged")
assertEqual(alice.hostility.attackNPCs,
    aliceLegacy.attackNPCs, "attackNPCs unchanged")
assertEqual(alice.recruited, aliceLegacy.recruited,
    "recruitment unchanged")
assertEqual(alice.presenceRevision,
    aliceLegacy.presenceRevision, "presence unchanged")
assertEqual(alice.social.revision,
    aliceLegacy.socialRevision, "social unchanged")
assertEqual(alice.social.relationships["npc:history"].revision,
    aliceLegacy.relationshipRevision, "relationship unchanged")
assertEqual(alice.social.conduct.revision,
    aliceLegacy.conductRevision, "conduct unchanged")

local rejectedRevision = Factions.Registry.revision
local rejectedRecordRevision = alice.recordRevision
assertFalse(Factions.AddNPC(looterID, alice.id, {}),
    "dual membership rejected")
assertEqual(Factions.Registry.revision, rejectedRevision,
    "dual membership registry revision")
assertEqual(alice.recordRevision, rejectedRecordRevision,
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
assertTrue(ok, "transfer")
assertEqual(alice.affiliation.factionID, traderID,
    "transfer destination")
assertEqual(alice.affiliation.role, "guard",
    "trader permits guard")
assertEqual(#alice.affiliation.formerFactionIDs, 1,
    "transfer history")
assertEqual(alice.affiliation.formerFactionIDs[1].factionID,
    settlementID, "former faction")
assertEqual(alice.affiliation.formerFactionIDs[1].reason,
    "transferred", "transfer reason")
assertFalse(Factions.Registry.byID[settlementID]
    .memberIDs[alice.id] == true, "source index removed")
assertTrue(Factions.Registry.byID[traderID]
    .memberIDs[alice.id], "destination index added")
assertTrue(Factions.AddNPC(refugeeID, cara.id, {
    role = "medic",
}), "refugee permits medic")
assertFalse(Factions.SetNPCRole(cara.id, "raider"),
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
assertEqual(#bounded.formerFactionIDs,
    Constants.FORMER_FACTION_LIMIT, "history bound")
assertEqual(bounded.formerFactionIDs[1].factionID,
    "faction_history_5", "oldest history removed")

-- 32-37. Leadership requires membership and demotes/reconciles safely.
assertFalse(Factions.SetLeader(traderID, bob.id, 121),
    "leader must be member")
assertTrue(Factions.AddNPC(traderID, bob.id, {
    role = "trader",
}), "add first leader candidate")
assertTrue(Factions.SetLeader(traderID, bob.id, 121),
    "set leader")
assertEqual(Factions.Get(traderID).leaderNPCID,
    bob.id, "leader ID")
assertEqual(bob.affiliation.role, "leader", "leader role")
assertEqual(bob.affiliation.rank, "leader", "leader rank")
assertTrue(Factions.AddNPC(traderID, dana.id, {
    role = "mechanic",
}), "add second leader candidate")
assertTrue(Factions.SetLeader(traderID, dana.id, 122),
    "replace leader")
assertEqual(bob.affiliation.rank, "member",
    "old leader demoted")
assertEqual(bob.affiliation.role, "civilian",
    "old leader safe role")
assertTrue(Factions.RemoveNPC(
    traderID,
    dana.id,
    "removed",
    123
), "remove leader")
assertEqual(Factions.Get(traderID).leaderNPCID,
    nil, "remove clears leader")
assertTrue(Factions.SetLeader(
    traderID,
    bob.id,
    124
), "restore leader")
bob.alive = false
assertTrue(Factions.OnNPCDeath(bob.id),
    "death reconciliation")
assertEqual(Factions.Get(traderID).leaderNPCID,
    nil, "death clears leader")
assertTrue(Factions.Get(traderID).memberIDs[bob.id],
    "death hook only changes leadership")
assertEqual(Factions.Get(traderID).status,
    "active", "death does not archive")
bob.alive = true

-- 38-40. Archive preserves identity and removes affiliations.
assertTrue(Factions.SetLeader(
    refugeeID,
    cara.id,
    125
), "refugee leader")
local archivedID = refugeeID
assertTrue(Factions.Archive(
    archivedID,
    "test_archive",
    130
), "archive")
local archived = Factions.Get(archivedID)
assertEqual(archived.status, "archived", "archived status")
assertEqual(archived.leaderNPCID, nil, "archived leader")
assertEqual(next(archived.memberIDs), nil, "archived members")
assertEqual(cara.affiliation.factionID, nil,
    "archival removes affiliation")
assertEqual(cara.affiliation.formerFactionIDs[
    #cara.affiliation.formerFactionIDs
].reason, "faction_archived", "archive history")
Factions.IDGenerator = function() return archivedID end
assertEqual(Factions.GenerateID(), nil,
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
assertEqual(malformedAffiliation.factionID, nil,
    "invalid affiliation reference")
assertEqual(malformedAffiliation.membershipStatus,
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
assertTrue(Types.AreEqual(normalizedOnce, normalizedTwice),
    "registry normalization idempotent")
assertTrue(normalizedOnce.byArchetype.settler[settlementID],
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
assertTrue(Factions.RebuildIndexes(), "index repair")
assertEqual(Factions.Registry.byID[settlementID]
    .memberIDs.ghost, nil, "ghost member removed")
assertTrue(Factions.Registry.byArchetype.settler[
    settlementID], "archetype index repaired")
assertEqual(orphan.affiliation.factionID, nil,
    "missing faction reference cleared")
assertEqual(#orphan.affiliation.formerFactionIDs, 1,
    "missing faction reference quarantined in history")
assertEqual(Factions.Registry.revision, rebuildRevision,
    "repair does not revise")
assertFalse(Factions.RebuildIndexes(),
    "correct index rebuild unchanged")

-- 51-55. Mutations advance only faction/affiliation record domains.
local beforeAffiliation = alice.affiliation.revision
local beforePresence = alice.presenceRevision
local beforeSocial = alice.social.revision
resetDirty()
assertTrue(Factions.SetNPCRank(alice.id, "officer"),
    "rank mutation")
assertEqual(alice.affiliation.revision,
    beforeAffiliation + 1, "affiliation revision")
assertEqual(alice.recordRevision,
    rejectedRecordRevision + 2,
    "record revision logical mutation")
assertEqual(alice.presenceRevision, beforePresence,
    "rank presence unchanged")
assertEqual(alice.social.revision, beforeSocial,
    "rank social unchanged")
local unchangedRegistry = Factions.Registry.revision
local unchangedRecord = alice.recordRevision
assertFalse(Factions.SetNPCRank(alice.id, "officer"),
    "identical rank unchanged")
assertEqual(Factions.Registry.revision, unchangedRegistry,
    "identical rank registry revision")
assertEqual(alice.recordRevision, unchangedRecord,
    "identical rank record revision")

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
dofile(SERVER .. "PNC_FactionDebug.lua")
assertTrue(string.find(
    PNC.FactionDebug.FormatList(),
    "Second Settlement",
    1, true
) ~= nil, "debug list formatting")
assertTrue(string.find(
    PNC.FactionDebug.FormatFaction(traderID),
    "Knox Exchange",
    1, true
) ~= nil, "debug detail formatting")
assertTrue(string.find(
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
assertSaveSafe(debugSnapshot)
assertEqual(debugSnapshot.roster[1].inventory,
    nil, "debug excludes inventory")
assertEqual(
    #debugSnapshot.npcDiagnostics,
    #debugSnapshot.roster,
    "debug includes one primitive diagnostic per living NPC"
)
assertEqual(
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
assertEqual(aliceDiagnostic.relationship.approval, 9,
    "debug diagnostic includes player relationship")
assertEqual(
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
assertTrue(
    PNC.Config.Factions.EnableValidationTelemetry,
    "debug GUI enables runtime telemetry"
)
assertTrue(
    enabledDiagnostics.actionResult.ok,
    "enable telemetry action succeeds"
)
local disabledDiagnostics =
    PNC.FactionDebug.PerformAction(nil, {
        factionAction = "telemetry_toggle",
        factionID = traderID,
        npcID = alice.id,
    })
assertFalse(
    PNC.Config.Factions.EnableValidationTelemetry,
    "debug GUI disables runtime telemetry"
)
assertEqual(
    disabledDiagnostics.actionResult.reason,
    "telemetry_disabled",
    "disable telemetry result"
)

-- Save/load registry remains primitive-only and copy-safe.
assertTrue(Factions.Save(), "faction save")
assertSaveSafe(globalData.PNC_Factions)
Factions.Loaded = false
assertTrue(Factions.Load(), "faction reload")
assertTrue(Factions.Get(traderID) ~= nil,
    "faction persists")
assertEqual(Factions.GetNPCAffiliation(alice.id).factionID,
    traderID, "membership persists")

print("pnc_factions_foundation_smoke: ok")
