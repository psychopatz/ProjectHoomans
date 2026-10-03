local Awareness = PNC and PNC.CorpseAwareness
if not Awareness then return end

local Internal = Awareness.Internal or {}
local Deps = Internal.ObserveDeps or {}
local modDataOf = Deps.modDataOf
local nowMs = Deps.nowMs
local deathIdentityFromRecord = Deps.deathIdentityFromRecord
local deathAttribution = Deps.deathAttribution
local copyDeathIdentity = Deps.copyDeathIdentity
local corpseIdentity = Deps.corpseIdentity
local cachedDeathAttribution = Deps.cachedDeathAttribution
local cacheCorpseIdentity = Deps.cacheCorpseIdentity
local cacheDeathAttribution = Deps.cacheDeathAttribution
local cacheDeathAwarenessState = Deps.cacheDeathAwarenessState
local deathMemoryID = Deps.deathMemoryID
local processWitnesses = Deps.processWitnesses
local MAX_WITNESSES_PER_CORPSE = Deps.MAX_WITNESSES_PER_CORPSE
local CACHE_SCHEMA_VERSION = Deps.CACHE_SCHEMA_VERSION
local SCAN_INTERVAL_MS = Deps.SCAN_INTERVAL_MS

function Awareness.ObserveDeath(record, actor, damageEvent, token)
    local core = PNC.Core
    local runtime
    local runtimeTokenMatches
    local identity
    local context
    local actorData
    local witnessCount
    local candidateCursor
    local now
    if not record or not core or not core.IsAuthority
        or core.IsAuthority() ~= true
    then
        return nil
    end
    token = tostring(token or record.corpseToken
        or record.corpse and record.corpse.token or "")
    if token == "" then return nil end
    identity = deathIdentityFromRecord(record, token)
    if not identity then return nil end
    runtime = type(record.runtime) == "table" and record.runtime or {}
    record.runtime = runtime
    runtimeTokenMatches = tostring(
        runtime.corpseAwarenessScanToken or ""
    ) == token
    if not runtimeTokenMatches then
        runtime.corpseAwarenessScanToken = token
        runtime.corpseAwarenessWitnessCount = 0
        runtime.corpseAwarenessCandidateCursor = 0
        runtime.corpseAwarenessNextScanAtMs = 0
    end
    witnessCount = runtimeTokenMatches and math.max(0, math.floor(tonumber(
        runtime.corpseAwarenessWitnessCount
    ) or 0)) or 0
    candidateCursor = runtimeTokenMatches and math.max(0, math.floor(
        tonumber(runtime.corpseAwarenessCandidateCursor) or 0
    )) or 0
    context = {
        token = token,
        identity = identity,
        attribution = deathAttribution(record, damageEvent),
        witnessCount = witnessCount,
        PNC_CorpseAwarenessWitnessCount = witnessCount,
        PNC_CorpseAwarenessCandidateCursor = candidateCursor,
    }
    actorData = modDataOf(actor)
    cacheDeathAwarenessState(
        actorData,
        token,
        identity,
        context.attribution,
        witnessCount,
        candidateCursor
    )
    if actor and PNC.Relationships
        and type(PNC.Relationships.AddMemory) == "function"
        and PNC.Perception
        and type(PNC.Perception.CanSeeWorldObject) == "function"
    then
        now = nowMs()
        processWitnesses(
            record,
            actor,
            context,
            identity,
            context
        )
        runtime.corpseAwarenessNextScanAtMs = now + SCAN_INTERVAL_MS
    end
    cacheDeathAwarenessState(
        actorData,
        token,
        identity,
        context.attribution,
        context.witnessCount,
        context.PNC_CorpseAwarenessCandidateCursor
    )
    return context
end

