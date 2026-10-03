local Awareness = PNC and PNC.CorpseAwareness
if not Awareness then return end

local Internal = Awareness.Internal or {}
local Deps = Internal.WitnessDeps or {}
local deathMemoryID = Deps.deathMemoryID
local deathMemoryCount = Deps.deathMemoryCount
local hasSpokenMemory = Deps.hasSpokenMemory
local rememberWitness = Deps.rememberWitness
local speak = Deps.speak
local knownKillerName = Deps.knownKillerName
local collectCandidates = Deps.collectCandidates
local MEMORY_LIMIT_PER_NPC = Deps.MEMORY_LIMIT_PER_NPC
local MAX_WITNESSES_PER_CORPSE = Deps.MAX_WITNESSES_PER_CORPSE
local MAX_VISIBILITY_CHECKS = Deps.MAX_VISIBILITY_CHECKS
local MAX_CORPSE_REACTIONS_PER_SCAN = Deps.MAX_CORPSE_REACTIONS_PER_SCAN

local function processWitnesses(
    record,
    target,
    scanState,
    identity,
    deathContext
)
    local witnessCount = math.max(0, math.floor(tonumber(
        scanState.PNC_CorpseAwarenessWitnessCount
    ) or 0))
    local memoryID = deathMemoryID(identity and identity.token)
    local candidates
    local checks = 0
    local reactions = 0
    local candidate
    local observer
    local visible
    local count
    local added
    local attribution = deathContext and deathContext.attribution or nil
    local index
    if not memoryID or witnessCount >= MAX_WITNESSES_PER_CORPSE then
        return witnessCount
    end
    candidates = collectCandidates(record, target, scanState, identity)
    for index = 1, #candidates do
        candidate = candidates[index]
        observer = candidate.record
        if checks >= MAX_VISIBILITY_CHECKS
            or reactions >= MAX_CORPSE_REACTIONS_PER_SCAN
            or witnessCount >= MAX_WITNESSES_PER_CORPSE
        then
            break
        end
        if not hasSpokenMemory(candidate.relationship, memoryID) then
            count = deathMemoryCount(observer)
            if count < MEMORY_LIMIT_PER_NPC then
                checks = checks + 1
                visible = PNC.Perception.CanSeeWorldObject(observer, target)
                if visible == true then
                    added = rememberWitness(
                        observer,
                        candidate.targetKey,
                        identity,
                        candidate.category,
                        memoryID,
                        attribution
                    )
                    if added then
                        witnessCount = witnessCount + 1
                        scanState.PNC_CorpseAwarenessWitnessCount =
                            witnessCount
                        if type(record.runtime) == "table" then
                            record.runtime.corpseAwarenessWitnessCount =
                                witnessCount
                            record.runtime.corpseAwarenessCandidateCursor =
                                tonumber(
                                    scanState.PNC_CorpseAwarenessCandidateCursor
                                ) or 0
                        end
                        if type(deathContext) == "table" then
                            deathContext.witnessCount = witnessCount
                            deathContext.PNC_CorpseAwarenessCandidateCursor =
                                tonumber(
                                    scanState.PNC_CorpseAwarenessCandidateCursor
                                ) or 0
                        end
                        if speak(
                            observer,
                            candidate.actor,
                            identity,
                            candidate.category,
                            identity.token,
                            attribution,
                            candidate.sameFaction
                                and knownKillerName(attribution)
                        ) then
                            reactions = reactions + 1
                        end
                    end
                end
            end
        end
    end
    if type(record.runtime) == "table" then
        record.runtime.corpseAwarenessWitnessCount = witnessCount
        record.runtime.corpseAwarenessCandidateCursor = tonumber(
            scanState.PNC_CorpseAwarenessCandidateCursor
        ) or 0
        record.runtime.corpseAwarenessScanToken = tostring(
            identity and identity.token or ""
        )
    end
    if type(deathContext) == "table" then
        deathContext.witnessCount = witnessCount
        deathContext.PNC_CorpseAwarenessCandidateCursor = tonumber(
            scanState.PNC_CorpseAwarenessCandidateCursor
        ) or 0
    end
    return witnessCount
end


Awareness.Internal.Witnesses = { processWitnesses = processWitnesses }
