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

function Awareness.ObserveCorpse(record, corpse, deathContext)
    local core = PNC.Core
    local relationships = PNC.Relationships
    local corpseData = modDataOf(corpse)
    local now = nowMs()
    local runtime
    local scanToken
    local identity
    local attribution
    local memoryID
    local witnessCount
    local count
    local context
    local carriedIdentity
    local hasDeathContext = false
    if not record or not corpse or not corpseData
        or not core or not core.IsAuthority
        or core.IsAuthority() ~= true
        or not relationships
        or type(relationships.AddMemory) ~= "function"
        or not PNC.Perception
        or type(PNC.Perception.CanSeeWorldObject) ~= "function"
    then
        return 0
    end
    scanToken = tostring(
        corpseData.PNC_CorpseToken
            or record.corpseToken
            or record.corpse and record.corpse.token
            or ""
    )
    if scanToken == "" then return 0 end
    runtime = type(record.runtime) == "table"
        and record.runtime or {}
    record.runtime = runtime
    if type(deathContext) == "table"
        and tostring(deathContext.token or "") == scanToken
    then
        carriedIdentity = copyDeathIdentity(
            record,
            scanToken,
            deathContext.identity
        )
        if carriedIdentity then
            identity = carriedIdentity
            cacheCorpseIdentity(corpseData, identity)
            cacheDeathAttribution(
                corpseData,
                scanToken,
                deathContext.attribution
            )
            hasDeathContext = true
        end
    end
    if not identity then
        identity = corpseIdentity(record, corpse, corpseData)
        attribution = cachedDeathAttribution(corpseData, scanToken)
    else
        attribution = deathContext.attribution
    end
    if not identity then return 0 end
    memoryID = deathMemoryID(identity.token)
    if not memoryID then return 0 end
    if tonumber(corpseData.PNC_CorpseAwarenessVersion)
            ~= CACHE_SCHEMA_VERSION
        or tostring(corpseData.PNC_CorpseAwarenessToken or "") ~= ""
            and tostring(corpseData.PNC_CorpseAwarenessToken or "")
                ~= scanToken
    then
        corpseData.PNC_CorpseAwarenessVersion = CACHE_SCHEMA_VERSION
        corpseData.PNC_CorpseAwarenessToken = scanToken
        corpseData.PNC_CorpseAwarenessWitnessCount = 0
        corpseData.PNC_CorpseAwarenessCandidateCursor = 0
    else
        corpseData.PNC_CorpseAwarenessToken = scanToken
    end
    witnessCount = math.max(0, math.floor(tonumber(
        corpseData.PNC_CorpseAwarenessWitnessCount
    ) or 0))
    if hasDeathContext then
        count = math.max(0, math.floor(tonumber(
            deathContext.witnessCount
        ) or 0))
        witnessCount = math.max(witnessCount, count)
        corpseData.PNC_CorpseAwarenessWitnessCount = witnessCount
        corpseData.PNC_CorpseAwarenessCandidateCursor = math.max(0, math.floor(
            tonumber(deathContext.PNC_CorpseAwarenessCandidateCursor) or 0
        ))
    elseif tostring(runtime.corpseAwarenessScanToken or "") == scanToken
        and tonumber(runtime.corpseAwarenessWitnessCount)
    then
        witnessCount = math.max(
            witnessCount,
            math.floor(tonumber(runtime.corpseAwarenessWitnessCount) or 0)
        )
        corpseData.PNC_CorpseAwarenessWitnessCount = witnessCount
        corpseData.PNC_CorpseAwarenessCandidateCursor = math.max(
            tonumber(corpseData.PNC_CorpseAwarenessCandidateCursor) or 0,
            math.floor(tonumber(runtime.corpseAwarenessCandidateCursor) or 0)
        )
    end
    if hasDeathContext then
        context = deathContext
    else
        context = {
            token = scanToken,
            identity = identity,
            attribution = attribution,
            witnessCount = witnessCount,
            PNC_CorpseAwarenessWitnessCount = witnessCount,
            PNC_CorpseAwarenessCandidateCursor = math.max(0, math.floor(
                tonumber(corpseData.PNC_CorpseAwarenessCandidateCursor) or 0
            )),
        }
    end
    context.token = scanToken
    context.identity = identity
    context.attribution = attribution
    context.witnessCount = witnessCount
    context.PNC_CorpseAwarenessWitnessCount = witnessCount
    context.PNC_CorpseAwarenessCandidateCursor = math.max(
        0,
        math.floor(tonumber(
            corpseData.PNC_CorpseAwarenessCandidateCursor
        ) or 0)
    )
    cacheDeathAwarenessState(
        corpseData,
        scanToken,
        identity,
        attribution,
        witnessCount,
        corpseData.PNC_CorpseAwarenessCandidateCursor
    )
    if witnessCount >= MAX_WITNESSES_PER_CORPSE then return 0 end
    if tostring(runtime.corpseAwarenessScanToken or "") ~= scanToken then
        runtime.corpseAwarenessScanToken = scanToken
        runtime.corpseAwarenessNextScanAtMs = 0
    end
    if now < (tonumber(runtime.corpseAwarenessNextScanAtMs) or 0) then
        return 0
    end
    runtime.corpseAwarenessNextScanAtMs = now + SCAN_INTERVAL_MS
    return processWitnesses(
        record,
        corpse,
        corpseData,
        identity,
        context
    )
end

