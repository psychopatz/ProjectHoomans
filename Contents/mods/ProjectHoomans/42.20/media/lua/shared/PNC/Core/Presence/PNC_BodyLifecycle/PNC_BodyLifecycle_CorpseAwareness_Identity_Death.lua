local Awareness = PNC and PNC.CorpseAwareness
if not Awareness then return end

local Internal = Awareness.Internal or {}
local Deps = Internal.IdentityDeps or {}
local lower = Internal.RelationshipDeps
    and Internal.RelationshipDeps.lower
local safeDisplayText = Deps.safeDisplayText
local MAX_CORPSE_ITEMS_TO_SCAN = Deps.MAX_CORPSE_ITEMS_TO_SCAN
local CACHE_SCHEMA_VERSION = Deps.CACHE_SCHEMA_VERSION
local ExistingIdentity = Internal.Identity or {}
local cacheCorpseIdentity = ExistingIdentity.cacheCorpseIdentity

local function deathIdentityFromRecord(record, token)
    local npcID = tostring(record and record.id or "")
    local affiliation = record and record.affiliation or nil
    local factionID = tostring(affiliation and affiliation.factionID or "")
    local factionName = affiliation
        and (affiliation.factionName or affiliation.name) or ""
    local factions = PNC.Factions
    local faction
    if npcID == "" then return nil end
    if factionID ~= "" and factions and type(factions.Get) == "function" then
        faction = factions.Get(factionID)
        if faction and faction.name then factionName = faction.name end
    end
    return {
        npcID = npcID,
        name = safeDisplayText(
            record.name or record.displayName,
            "Unknown NPC"
        ),
        factionID = factionID,
        factionName = safeDisplayText(factionName, ""),
        token = tostring(token or ""),
    }
end

local function copyDeathIdentity(record, token, identity)
    if type(identity) ~= "table"
        or tostring(identity.npcID or "") ~= tostring(record and record.id or "")
        or tostring(identity.token or "") ~= tostring(token or "")
    then
        return nil
    end
    local name = safeDisplayText(identity.name, "Unknown NPC")
    if name == "Unknown NPC" and identity.name ~= "Unknown NPC" then
        return nil
    end
    return {
        npcID = tostring(identity.npcID),
        name = name,
        factionID = tostring(identity.factionID or ""),
        factionName = safeDisplayText(identity.factionName, ""),
        token = tostring(identity.token),
    }
end

local function deathAttribution(record, damageEvent)
    local attackerKind = lower(damageEvent and damageEvent.attackerKind)
    local attackerID = tostring(damageEvent and damageEvent.attackerID or "")
    local killerName
    local sourceKey
    local attacker
    if attackerKind == "player" then
        killerName = safeDisplayText(
            damageEvent.attackerUsername or damageEvent.username,
            ""
        )
        if killerName == "" then return nil end
        return {
            kind = "player",
            killerName = killerName,
        }
    end
    if attackerKind ~= "npc"
        and attackerKind ~= "foreign_npc"
        and attackerKind ~= "managed_npc"
    then
        return nil
    end
    if attackerID == "" or attackerID == tostring(record and record.id or "") then
        return nil
    end
    attacker = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(attackerID) or nil
    killerName = attacker and (attacker.name or attacker.displayName) or nil
    if PNC.EntityRef and PNC.EntityRef.ForNPC then
        sourceKey = PNC.EntityRef.ForNPC(attackerID)
    end
    if not sourceKey then return nil end
    return {
        kind = "npc",
        killerName = safeDisplayText(killerName, ""),
        sourceKey = sourceKey,
    }
end

local function knownKillerName(attribution)
    local name = type(attribution) == "table"
        and safeDisplayText(attribution.killerName, "") or ""
    return name ~= "" and name ~= "the one who did this"
end

local function cacheDeathAttribution(corpseData, token, attribution)
    if type(corpseData) ~= "table" then return false end
    corpseData.PNC_CorpseAwarenessAttributionVersion = 1
    corpseData.PNC_CorpseAwarenessAttributionToken = tostring(token or "")
    corpseData.PNC_CorpseAwarenessAttributionKnown =
        type(attribution) == "table"
    corpseData.PNC_CorpseAwarenessAttributionKind = type(attribution)
            == "table" and tostring(attribution.kind or "") or ""
    corpseData.PNC_CorpseAwarenessAttributionKiller = type(attribution)
            == "table"
        and safeDisplayText(
            attribution.killerName,
            "the one who did this"
        ) or ""
    corpseData.PNC_CorpseAwarenessAttributionSourceKey = type(attribution)
            == "table"
        and tostring(attribution.sourceKey or "") or ""
    return true
end

local function cachedDeathAttribution(corpseData, token)
    local entityRef = PNC.EntityRef
    local kind
    local sourceKey
    if type(corpseData) ~= "table"
        or tonumber(corpseData.PNC_CorpseAwarenessAttributionVersion) ~= 1
        or tostring(corpseData.PNC_CorpseAwarenessAttributionToken or "")
            ~= tostring(token or "")
        or corpseData.PNC_CorpseAwarenessAttributionKnown ~= true
    then
        return nil
    end
    kind = lower(corpseData.PNC_CorpseAwarenessAttributionKind)
    if kind ~= "player" and kind ~= "npc" then return nil end
    sourceKey = tostring(
        corpseData.PNC_CorpseAwarenessAttributionSourceKey or ""
    )
    if not entityRef or not entityRef.IsValid
        or not entityRef.IsValid(sourceKey)
    then
        sourceKey = nil
    end
    return {
        kind = kind,
        killerName = safeDisplayText(
            corpseData.PNC_CorpseAwarenessAttributionKiller,
            "the one who did this"
        ),
        sourceKey = sourceKey,
    }
end

local function cacheDeathAwarenessState(
    corpseData,
    token,
    identity,
    attribution,
    witnessCount,
    candidateCursor
)
    if type(corpseData) ~= "table" then return false end
    cacheCorpseIdentity(corpseData, identity)
    cacheDeathAttribution(corpseData, token, attribution)
    corpseData.PNC_CorpseAwarenessVersion = CACHE_SCHEMA_VERSION
    corpseData.PNC_CorpseAwarenessToken = tostring(token or "")
    corpseData.PNC_CorpseAwarenessWitnessCount = math.max(
        0,
        math.floor(tonumber(witnessCount) or 0)
    )
    corpseData.PNC_CorpseAwarenessCandidateCursor = math.max(
        0,
        math.floor(tonumber(candidateCursor) or 0)
    )
    return true
end

local Identity = Awareness.Internal.Identity or {}
Awareness.Internal.Identity = Identity
Identity.deathIdentityFromRecord = deathIdentityFromRecord
Identity.copyDeathIdentity = copyDeathIdentity
Identity.deathAttribution = deathAttribution
Identity.knownKillerName = knownKillerName
Identity.cachedDeathAttribution = cachedDeathAttribution
Identity.cacheDeathAttribution = cacheDeathAttribution
Identity.cacheDeathAwarenessState = cacheDeathAwarenessState
