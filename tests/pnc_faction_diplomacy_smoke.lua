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
        if kind == "number" and (
            value ~= value or value == math.huge
            or value == -math.huge
        ) then
            error("non-finite persisted number")
        end
        return
    end
    if kind ~= "table" or getmetatable(value) ~= nil then
        error("unsafe persisted faction value: " .. kind)
    end
    seen = seen or {}
    if seen[value] then error("cycle in persisted faction data") end
    seen[value] = true
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            error("unsafe faction key")
        end
        saveSafe(item, seen)
    end
    seen[value] = nil
end

local worldHour = 200
local globalData = {}
local authorityEnabled = true

-- Exercise shared math/types and the authoritative services under the same
-- missing-next constraint as Project Zomboid's Kahlua runtime.
next = nil

function isClient() return false end
function isServer() return true end
function getTimeInMillis() return worldHour * 3600000 end
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
PNC.Core.IsAuthority = function() return authorityEnabled end
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

PNC.Registry = {
    Data = {},
    Get = function(id) return PNC.Registry.Data[id] end,
    EnsureLoaded = function() return true end,
    MarkDirty = function() return true end,
}

T.load(SERVER .. "PNC_FactionTelemetry.lua")
T.load(SERVER .. "PNC_FactionService.lua")
T.load(SERVER .. "PNC_FactionIncidentService.lua")
T.load(SERVER .. "PNC_FactionValidation.lua")

local Factions = PNC.Factions
local Types = PNC.FactionTypes
local Math = PNC.FactionDiplomacyMath
Factions.Load()

local generated = {
    "faction_alpha",
    "faction_bravo",
    "faction_charlie",
    "faction_delta",
}
local generatedIndex = 0
Factions.IDGenerator = function()
    generatedIndex = generatedIndex + 1
    return generated[generatedIndex]
end

local _, _, alpha = Factions.Create({
    name = "Alpha",
    archetypeID = "settler",
    createdAt = worldHour,
})
local _, _, bravo = Factions.Create({
    name = "Bravo",
    archetypeID = "looter",
    createdAt = worldHour,
})
local _, _, charlie = Factions.Create({
    name = "Charlie",
    archetypeID = "trader",
    createdAt = worldHour,
})
local _, _, delta = Factions.Create({
    name = "Delta",
    archetypeID = "refugee",
    createdAt = worldHour,
})

-- Policy generation is deterministic per faction and archetype.
local normalizedAlpha = Types.NormalizeFaction(alpha, alpha.id)
T.equal(normalizedAlpha.policy.aggression,
    alpha.policy.aggression, "deterministic policy")
T.equal(bravo.policy.outsiderPolicy,
    "predatory", "looter policy")
local authoredPolicy = Types.NewPolicy(
    "settler",
    "faction_authored",
    {
        aggression = 2,
        caution = -1,
        outsiderPolicy = "sheltering",
    }
)
T.equal(authoredPolicy.aggression, 1, "policy upper clamp")
T.equal(authoredPolicy.caution, 0, "policy lower clamp")
T.equal(authoredPolicy.outsiderPolicy,
    "sheltering", "authored outsider policy")

local newRelation = Types.NewRelation(alpha.id, bravo.id)
T.equal(newRelation.state, "unknown", "new relation unknown")
T.equal(newRelation.standing, 0, "new relation standing")
T.equal(newRelation.revision, 0, "new relation revision")

-- Directed incidents affect only the observing/victim faction.
local revisionBefore = Factions.Registry.revision
local ok, reason = PNC.FactionIncidentService.AddIncident(
    alpha.id,
    bravo.id,
    "member_attacked_minor",
    {
        worldAgeHours = worldHour,
        externalID = "test:minor:1",
    }
)
T.truthy(ok, "minor incident accepted")
local bravoToAlpha = Factions.GetRelation(bravo.id, alpha.id)
T.equal(bravoToAlpha.standing, -8, "directed standing")
T.equal(bravoToAlpha.trust, -10, "directed trust")
T.equal(bravoToAlpha.grievance, 10, "directed grievance")
T.equal(Factions.GetRelation(alpha.id, bravo.id), nil,
    "reverse relation remains absent")
T.equal(Factions.Registry.revision,
    revisionBefore + 1, "incident registry revision")
local duplicateRevision = Factions.Registry.revision
T.equal(PNC.FactionIncidentService.AddIncident(
    alpha.id,
    bravo.id,
    "member_attacked_minor",
    {
        worldAgeHours = worldHour,
        externalID = "test:minor:1",
    }
), false, "duplicate incident rejected")
T.equal(Factions.Registry.revision, duplicateRevision,
    "duplicate incident revision-neutral")

-- Numeric normalization clamps malformed metrics.
local clamped = Types.NormalizeRelation({
    standing = 500,
    trust = -500,
    fear = -20,
    grievance = 900,
}, alpha.id, bravo.id)
T.equal(clamped.standing, 100, "standing clamp")
T.equal(clamped.trust, -100, "trust clamp")
T.equal(clamped.fear, 0, "fear clamp")
T.equal(clamped.grievance, 100, "grievance clamp")

-- State entry and hysteresis are deterministic.
local friendly = Types.NormalizeRelation({
    standing = 35,
    trust = 15,
    grievance = 10,
    lastEvaluatedAt = 1,
}, alpha.id, charlie.id)
T.equal(friendly.state, "friendly", "friendly entry")
friendly.standing = 22
friendly.trust = 5
friendly.grievance = 25
T.equal(Math.ResolveState(friendly, 2),
    "friendly", "friendly hysteresis")
friendly.standing = 19
T.equal(Math.ResolveState(friendly, 2),
    "neutral", "friendly exit")
local hostile = Types.NormalizeRelation({
    standing = -50,
    grievance = 20,
    lastEvaluatedAt = 1,
}, alpha.id, charlie.id)
T.equal(hostile.state, "hostile", "hostile entry")
hostile.standing = -31
T.equal(Math.ResolveState(hostile, 2),
    "hostile", "hostile hysteresis")

-- Coarse recalculation decays metrics from elapsed world age.
local decayed = Math.RecalculateRelation(
    Types.NormalizeRelation({
        standing = 10,
        trust = -10,
        fear = 10,
        grievance = 10,
        lastEvaluatedAt = 24,
    }, alpha.id, delta.id),
    48
)
T.equal(decayed.standing, 9.95, "standing decay")
T.equal(decayed.trust, -9.975, "trust decay")
T.equal(decayed.fear, 9.9, "fear decay")
T.equal(decayed.grievance, 9.98, "peace grievance decay")

-- Official treaties are symmetric even though metrics remain directed.
local registryBeforeWar = Factions.Registry.revision
T.truthy(Factions.DeclareWar(
    alpha.id,
    charlie.id,
    {
        worldAgeHours = worldHour,
        reason = "manual_debug",
        instigatorFactionID = alpha.id,
    }
), "war declaration")
T.truthy(Factions.AreAtWar(alpha.id, charlie.id),
    "war symmetric")
T.equal(Factions.Registry.revision,
    registryBeforeWar + 1, "war atomic registry revision")
T.equal(Factions.DeclareWar(
    alpha.id,
    charlie.id,
    {
        worldAgeHours = worldHour,
        reason = "manual_debug",
        instigatorFactionID = alpha.id,
    }
), false, "duplicate war idempotent")
T.truthy(Factions.StartTruce(
    alpha.id,
    charlie.id,
    {
        worldAgeHours = worldHour + 1,
        truceUntil = worldHour + 25,
        instigatorFactionID = alpha.id,
    }
), "truce starts")
T.equal(Factions.AreAtWar(alpha.id, charlie.id),
    false, "truce ends war")
T.equal(Factions.GetTruceUntil(alpha.id, charlie.id),
    worldHour + 25, "truce symmetric")
T.truthy(Factions.MakePeace(
    alpha.id,
    charlie.id,
    {
        worldAgeHours = worldHour + 2,
        instigatorFactionID = alpha.id,
    }
), "peace")
T.equal(Factions.GetTruceUntil(alpha.id, charlie.id),
    0, "peace clears truce")

-- Alliance operations are symmetric and audited.
T.truthy(Factions.FormAlliance(
    alpha.id,
    charlie.id,
    {
        worldAgeHours = worldHour + 3,
        instigatorFactionID = alpha.id,
        override = true,
    }
), "alliance")
T.truthy(Factions.AreAllied(alpha.id, charlie.id),
    "alliance symmetric")
T.truthy(Factions.BreakAlliance(
    alpha.id,
    charlie.id,
    {
        worldAgeHours = worldHour + 4,
        instigatorFactionID = charlie.id,
    }
), "break alliance")
T.equal(Factions.AreAllied(alpha.id, charlie.id),
    false, "alliance break symmetric")
T.truthy(Factions.FormAlliance(
    bravo.id,
    charlie.id,
    {
        worldAgeHours = worldHour + 5,
        instigatorFactionID = bravo.id,
        override = true,
    }
), "second alliance")
T.truthy(PNC.FactionIncidentService.AddIncident(
    bravo.id,
    charlie.id,
    "member_attacked_minor",
    {
        worldAgeHours = worldHour + 6,
        externalID = "test:ally_attack",
    }
), "ally attack incident")
T.equal(Factions.AreAllied(bravo.id, charlie.id),
    false, "attacking ally breaks alliance")

T.truthy(Factions.StartTruce(
    alpha.id,
    charlie.id,
    {
        worldAgeHours = worldHour + 7,
        truceUntil = worldHour + 31,
        instigatorFactionID = alpha.id,
    }
), "second truce")
T.truthy(PNC.FactionIncidentService.AddIncident(
    alpha.id,
    charlie.id,
    "member_attacked_minor",
    {
        worldAgeHours = worldHour + 8,
        externalID = "test:truce_attack",
    }
), "truce attack incident")
T.truthy(Factions.AreAtWar(alpha.id, charlie.id),
    "truce attack renews war")

-- Predatory looters are hostile to outsiders by default.
local neutralLooter = PNC.FactionIntent.Resolve({
    archetypeID = "looter",
    policy = bravo.policy,
    diplomaticState = "neutral",
    observerStrength = 2,
    targetStrength = 1,
})
T.equal(neutralLooter.intent, "attack",
    "looter neutral attack")
T.equal(neutralLooter.attackAllowed, true,
    "looter default hostility")
local pacifiedLooter = PNC.FactionIntent.Resolve({
    archetypeID = "looter",
    policy = bravo.policy,
    diplomaticState = "war",
    playerPacified = true,
})
T.equal(pacifiedLooter.intent, "tolerate",
    "player-scoped pacification suppresses looter attack")
T.equal(pacifiedLooter.attackAllowed, false,
    "pacification is nonlethal")
T.truthy(PNC.FactionIntent.Resolve({
    archetypeID = "looter",
    playerPacified = true,
    immediateSelfDefense = true,
}).attackAllowed, "self-defense overrides pacification")
T.truthy(PNC.FactionIntent.Resolve({
    archetypeID = "trader",
    policy = charlie.policy,
    diplomaticState = "war",
}).attackAllowed, "war intent lethal")
T.equal(PNC.FactionIntent.Resolve({
    archetypeID = "refugee",
    policy = delta.policy,
    diplomaticState = "neutral",
}).intent, "avoid", "refugee caution")
local companionIntent = PNC.FactionIntent.Resolve({
    samePlayerOwnedFaction = true,
    targetIsOwner = true,
    commandable = true,
})
T.equal(companionIntent.intent, "obey",
    "player owner companion intent")
T.truthy(companionIntent.commandable,
    "player owner commandable")

-- Attack callbacks aggregate: first hit is minor, a death upgrades the same
-- persisted episode and can escalate under victim policy.
local invalidAttackRevision = Factions.Registry.revision
T.equal(PNC.FactionIncidentService.RecordAttack(
    alpha.id,
    delta.id,
    {
        worldAgeHours = worldHour + 9,
        actorKey = "malformed",
        subjectKey = "npc:victim",
    }
), false, "malformed attack key rejected")
T.equal(Factions.Registry.revision, invalidAttackRevision,
    "malformed attack key revision neutral")
T.truthy(PNC.FactionIncidentService.RecordAttack(
    alpha.id,
    delta.id,
    {
        worldAgeHours = worldHour + 10,
        actorKey = "npc:attacker",
        subjectKey = "npc:victim",
    }
), "attack episode starts")
T.truthy(PNC.FactionIncidentService.RecordAttack(
    alpha.id,
    delta.id,
    {
        worldAgeHours = worldHour + 10.001,
        actorKey = "npc:attacker",
        subjectKey = "npc:victim",
        killed = true,
    }
), "attack episode upgrades")
local deltaRelation = Factions.GetRelation(delta.id, alpha.id)
local attackIncidents = {}
for _, incident in ipairs(deltaRelation.incidents) do
    if incident.type == "member_attacked_minor"
        or incident.type == "member_attacked_severe"
        or incident.type == "member_killed"
    then
        attackIncidents[#attackIncidents + 1] = incident
    end
end
T.equal(#attackIncidents, 1,
    "attack episode stores one combat incident")
T.equal(attackIncidents[1].type,
    "member_killed", "episode upgraded to death")
T.truthy(Factions.AreAtWar(alpha.id, delta.id),
    "death policy escalates")
local episode = PNC.FactionIncidentService
    .GetActiveEpisodes()[1]
T.truthy(episode ~= nil, "aggregation diagnostics available")
T.equal(episode.hitCount, 2, "aggregation hit count")
T.equal(episode.state, "upgraded_to_severe",
    "aggregation upgrade state")
T.equal(episode.actorKey, "npc:attacker",
    "aggregation stable actor key")
T.equal(PNC.FactionIncidentService.PumpRuntime(
    worldHour + 11
), 1, "aggregation expiry cleanup")
T.equal(#PNC.FactionIncidentService.GetActiveEpisodes(), 0,
    "expired aggregation removed")

-- Optional intent traces preserve the ordinary result and are read-only.
local intentSpec = {
    archetypeID = "looter",
    policy = bravo.policy,
    diplomaticState = "neutral",
    observerStrength = 1,
    targetStrength = 2,
}
local ordinaryIntent = PNC.FactionIntent.Resolve(intentSpec)
local tracedIntent = PNC.FactionIntent.ResolveWithTrace(intentSpec)
T.equal(tracedIntent.result.intent, ordinaryIntent.intent,
    "intent trace matches ordinary result")
T.equal(tracedIntent.result.reason, ordinaryIntent.reason,
    "intent trace matches ordinary reason")
T.equal(tracedIntent.trace.selectedRule, ordinaryIntent.reason,
    "intent trace selected rule")

-- Runtime telemetry is safe, bounded, copied, and revision-neutral.
PNC.Config.Factions.EnableValidationTelemetry = true
local telemetryRevision = Factions.Registry.revision
PNC.Config.Factions.reconciliationBatchSize = 999999
T.equal(PNC.FactionBalance.Get("reconciliationBatchSize"),
    128, "balance override clamped")
PNC.Config.Factions.reconciliationBatchSize = nil
for index = 1, 520 do
    PNC.FactionTelemetry.RecordCallback({
        operation = "test_callback",
        worldAgeHours = worldHour,
        result = "accepted",
        sequenceInput = index,
        unsafe = function() end,
    })
end
local telemetrySnapshot =
    PNC.FactionTelemetry.BuildSnapshot({ maximum = 600 })
T.equal(telemetrySnapshot.count, 512,
    "telemetry bounded")
T.equal(#telemetrySnapshot.entries, 512,
    "telemetry snapshot bounded")
T.equal(telemetrySnapshot.entries[1].sequenceInput, 9,
    "telemetry FIFO deterministic")
T.equal(telemetrySnapshot.entries[1].unsafe, nil,
    "telemetry strips functions")
telemetrySnapshot.entries[1].result = "tampered"
T.equal(PNC.FactionTelemetry.GetRecent(512)[1].result,
    "accepted", "telemetry reads copied")
T.equal(Factions.Registry.revision, telemetryRevision,
    "telemetry revision neutral")
T.equal(globalData.PNC_Factions.telemetry, nil,
    "telemetry never enters faction ModData")

-- Isolated scenarios are deterministic and never touch persistence.
local scenarioRevision = Factions.Registry.revision
local scenarioA = PNC.FactionValidation.RunScenario(
    "war_then_peace"
)
local scenarioB = PNC.FactionValidation.RunScenario(
    "war_then_peace"
)
T.equal(scenarioA.finalDiplomaticState,
    scenarioB.finalDiplomaticState,
    "scenario deterministic")
T.equal(scenarioA.revisionDeltas.registry, 0,
    "scenario registry delta zero")
T.equal(Factions.Registry.revision, scenarioRevision,
    "scenario preview persistence neutral")

local repairRevision = Factions.Registry.revision
Factions.Registry.byArchetype = {}
T.truthy(PNC.FactionValidation.RepairSecondaryIndexes(),
    "safe secondary index repair")
T.equal(Factions.Registry.revision, repairRevision + 1,
    "secondary repair increments registry once")
T.equal(PNC.FactionValidation.RepairSecondaryIndexes(),
    false, "secondary repair deterministic")

-- The read-only checker detects treaty asymmetry.
local savedReverse = Types.NormalizeRelation(
    Factions.Registry.byID[delta.id].relations[alpha.id],
    delta.id,
    alpha.id
)
Factions.Registry.byID[delta.id]
    .relations[alpha.id].atWar = false
local checkerRevision = Factions.Registry.revision
local invalidPair = PNC.FactionValidation.CheckRelation(
    alpha.id, delta.id
)
T.equal(invalidPair.ok, false,
    "invariant checker detects asymmetric war")
T.equal(Factions.Registry.revision, checkerRevision,
    "invariant checker read-only")
Factions.Registry.byID[delta.id].relations[alpha.id] =
    savedReverse
T.truthy(PNC.FactionValidation.CheckRegistry().ok,
    "registry invariants hold after restoration")

-- Invalid time and non-authority mutations are rejected without revisions.
local rejectedRevision = Factions.Registry.revision
T.equal(Factions.DeclareWar(
    bravo.id,
    charlie.id,
    {
        worldAgeHours = 0 / 0,
        reason = "manual_debug",
        instigatorFactionID = bravo.id,
    }
), false, "invalid treaty time")
authorityEnabled = false
T.equal(PNC.FactionIncidentService.AddIncident(
    bravo.id,
    charlie.id,
    "member_rescued",
    {
        worldAgeHours = worldHour,
        externalID = "client:rejected",
    }
), false, "client mutation rejected")
authorityEnabled = true
T.equal(Factions.Registry.revision, rejectedRevision,
    "rejections revision-neutral")

-- V2 migration is deterministic, idempotent, directed, and save-safe.
local legacy = {
    schemaVersion = 2,
    revision = 4,
    byID = {
        faction_legacy_a = {
            id = "faction_legacy_a",
            name = "Legacy A",
            archetypeID = "settler",
        },
        faction_legacy_b = {
            id = "faction_legacy_b",
            name = "Legacy B",
            archetypeID = "trader",
        },
    },
    diplomacy = {
        ["faction_legacy_a|faction_legacy_b"] = {
            factionAID = "faction_legacy_a",
            factionBID = "faction_legacy_b",
            state = "war",
            changedAt = 12,
            revision = 3,
        },
    },
}
local migratedOnce = Types.NormalizeFactionRegistry(legacy)
local migratedTwice =
    Types.NormalizeFactionRegistry(migratedOnce)
T.truthy(Types.AreEqual(migratedOnce, migratedTwice),
    "migration idempotent")
T.truthy(migratedOnce.byID.faction_legacy_a
    .relations.faction_legacy_b.atWar,
    "legacy forward treaty")
T.truthy(migratedOnce.byID.faction_legacy_b
    .relations.faction_legacy_a.atWar,
    "legacy reverse treaty")

local manyIncidents = {
    {
        id = "audit:war",
        type = "war_declared",
        sourceFactionID = alpha.id,
        targetFactionID = bravo.id,
        occurredAt = 1,
        severity = 1,
        preserve = true,
    },
}
for index = 1, 70 do
    manyIncidents[#manyIncidents + 1] = {
        id = "ordinary:" .. tostring(index),
        type = "member_attacked_minor",
        sourceFactionID = alpha.id,
        targetFactionID = bravo.id,
        occurredAt = index + 1,
        severity = index / 100,
    }
end
local boundedRelation = Types.NormalizeRelation({
    incidents = manyIncidents,
}, bravo.id, alpha.id)
T.equal(#boundedRelation.incidents,
    PNC.FactionConstants.INCIDENT_LIMIT,
    "incident history bounded")
local auditPreserved = false
for _, incident in ipairs(boundedRelation.incidents) do
    if incident.id == "audit:war" then
        auditPreserved = true
    end
end
T.truthy(auditPreserved, "treaty audit preserved")
saveSafe(Factions.Registry)
saveSafe(migratedOnce)
T.finish("pnc_faction_diplomacy_smoke")

T.finish("pnc_faction_diplomacy_smoke")
