-- Read/project bridge for Core-owned directed social state. Hoomans remains
-- an adopter contributing social depth, while Core owns the canonical shared
-- relationship ledger and extension envelope.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreSocial or {}
Persistence.CoreSocial = Adapter

local function service(core)
    return core and core.Actors and core.Actors.Social
end

local function clone(val)
    if type(val) ~= "table" then return val end
    local res = {}
    for k, v in pairs(val) do res[k] = clone(v) end
    return res
end

function Adapter.ToCoreSocial(recordSocial, core)
    local Social = service(core or PsychopatzCore)
    if not Social or type(Social.NewState) ~= "function" then
        return nil, "core_social_unavailable"
    end
    if type(recordSocial) ~= "table" then
        return nil, "source_social_missing"
    end

    local existingExt = type(recordSocial.extensions) == "table"
        and clone(recordSocial.extensions) or {}
    existingExt.ProjectHoomans = {
        morale = tonumber(recordSocial.morale) or 0,
        moraleBaseline = tonumber(recordSocial.moraleBaseline) or 0,
        conduct = clone(recordSocial.conduct),
        lastEvaluatedAt = tonumber(recordSocial.lastEvaluatedAt) or 0,
    }

    local relationships = {}
    if type(recordSocial.relationships) == "table" then
        for targetKey, rel in pairs(recordSocial.relationships) do
            if type(targetKey) == "string" and type(rel) == "table" then
                local relExt = type(rel.extensions) == "table"
                    and clone(rel.extensions) or {}
                relExt.ProjectHoomans = {
                    baselineApproval = tonumber(rel.baselineApproval) or 0,
                    baselineRespect = tonumber(rel.baselineRespect) or 0,
                    state = rel.state,
                    previousState = rel.previousState,
                    bond = clone(rel.bond),
                    saturation = clone(rel.saturation),
                    cooldowns = clone(rel.cooldowns),
                    interactionJournal = clone(rel.interactionJournal),
                    interactionRevision = tonumber(rel.interactionRevision) or 0,
                    lastInteractionAt = tonumber(rel.lastInteractionAt) or 0,
                    lastEvaluatedAt = tonumber(rel.lastEvaluatedAt) or 0,
                }
                relationships[targetKey] = {
                    targetKey = targetKey,
                    approval = tonumber(rel.approval) or 0,
                    respect = tonumber(rel.respect) or 0,
                    familiarity = tonumber(rel.familiarity) or 0,
                    revision = tonumber(rel.revision) or 0,
                    lastEventAt = rel.lastInteractionAt or rel.lastEvaluatedAt,
                    memories = clone(rel.memories or {}),
                    extensions = relExt,
                }
            end
        end
    end

    return Social.NewState({
        schemaVersion = Social.SCHEMA_VERSION,
        revision = tonumber(recordSocial.revision) or 0,
        personality = clone(recordSocial.personality or {}),
        personalityOverrides = clone(recordSocial.personalityOverrides or {}),
        recentEventIDs = clone(recordSocial.recentEventIDs or {}),
        relationships = relationships,
        extensions = existingExt,
    })
end

function Adapter.FromCoreSocial(coreSocial, fallbackSocial)
    if type(coreSocial) ~= "table" then return nil, "core_social_missing" end
    fallbackSocial = type(fallbackSocial) == "table" and fallbackSocial or {}

    local hoomansExt = coreSocial.extensions
        and coreSocial.extensions.ProjectHoomans or {}
    local Types = PNC.RelationshipTypes
    local Constants = PNC.RelationshipConstants

    local relationships = {}
    if type(coreSocial.relationships) == "table" then
        for targetKey, coreRel in pairs(coreSocial.relationships) do
            if type(targetKey) == "string" and type(coreRel) == "table" then
                local fallbackRel = fallbackSocial.relationships
                    and fallbackSocial.relationships[targetKey] or {}
                local relExt = coreRel.extensions
                    and coreRel.extensions.ProjectHoomans or {}

                local state = relExt.state or fallbackRel.state
                if not state or state == "" then
                    if PNC.RelationshipStates
                        and type(PNC.RelationshipStates.ResolveState) == "function"
                    then
                        state = PNC.RelationshipStates.ResolveState(coreRel)
                    else
                        state = Constants and Constants.STATE_UNKNOWN or "unknown"
                    end
                end

                relationships[targetKey] = {
                    targetKey = targetKey,
                    approval = tonumber(coreRel.approval) or 0,
                    respect = tonumber(coreRel.respect) or 0,
                    familiarity = tonumber(coreRel.familiarity) or 0,
                    revision = tonumber(coreRel.revision) or 0,
                    baselineApproval = tonumber(relExt.baselineApproval
                        or fallbackRel.baselineApproval) or 0,
                    baselineRespect = tonumber(relExt.baselineRespect
                        or fallbackRel.baselineRespect) or 0,
                    state = state,
                    previousState = relExt.previousState
                        or fallbackRel.previousState
                        or Constants and Constants.STATE_UNKNOWN or "unknown",
                    bond = clone(relExt.bond or fallbackRel.bond),
                    saturation = clone(relExt.saturation or fallbackRel.saturation or {}),
                    cooldowns = clone(relExt.cooldowns or fallbackRel.cooldowns or {}),
                    interactionJournal = clone(relExt.interactionJournal
                        or fallbackRel.interactionJournal or {}),
                    interactionRevision = tonumber(relExt.interactionRevision
                        or fallbackRel.interactionRevision) or 0,
                    lastInteractionAt = tonumber(relExt.lastInteractionAt
                        or coreRel.lastEventAt or fallbackRel.lastInteractionAt) or 0,
                    lastEvaluatedAt = tonumber(relExt.lastEvaluatedAt
                        or fallbackRel.lastEvaluatedAt) or 0,
                    memories = clone(coreRel.memories or {}),
                    extensions = clone(coreRel.extensions or {}),
                }
            end
        end
    end

    local reconstructed = {
        schemaVersion = Constants and Constants.SOCIAL_SCHEMA_VERSION or 4,
        revision = tonumber(coreSocial.revision) or 0,
        morale = tonumber(hoomansExt.morale or fallbackSocial.morale) or 0,
        moraleBaseline = tonumber(hoomansExt.moraleBaseline
            or fallbackSocial.moraleBaseline) or 0,
        conduct = clone(hoomansExt.conduct or fallbackSocial.conduct),
        lastEvaluatedAt = tonumber(hoomansExt.lastEvaluatedAt
            or fallbackSocial.lastEvaluatedAt) or 0,
        personality = clone(coreSocial.personality or fallbackSocial.personality or {}),
        personalityOverrides = clone(coreSocial.personalityOverrides
            or fallbackSocial.personalityOverrides or {}),
        recentEventIDs = clone(coreSocial.recentEventIDs or {}),
        relationships = relationships,
        extensions = clone(coreSocial.extensions or {}),
    }

    if Types and type(Types.NormalizeSocialState) == "function" then
        return Types.NormalizeSocialState(reconstructed)
    end
    return reconstructed
end

function Adapter.Project(record, core)
    local Social = service(core)
    if not Social or type(Social.NewState) ~= "function" then
        return nil, "core_social_unavailable"
    end
    if type(record) ~= "table" or type(record.social) ~= "table" then
        return nil, "source_social_missing"
    end
    return Adapter.ToCoreSocial(record.social, core)
end

function Adapter.RecordAuthorizedEvent(state, core, event)
    local Social = service(core)
    if not Social or type(Social.RecordAuthorizedEvent) ~= "function" then
        return nil, "core_social_unavailable"
    end
    return Social.RecordAuthorizedEvent(state, event)
end

function Adapter.SyncToCore(record, core)
    core = core or PsychopatzCore
    if not core or not core.Actors or not core.Actors.DefaultRegistry then
        return false, "core_registry_unavailable"
    end
    if type(record) ~= "table" or type(record.social) ~= "table" then
        return false, "record_social_missing"
    end
    local actorID = record.coreActorID
        or (record.runtime and record.runtime.coreActorID)
        or record.id
    if not actorID or not core.Actors.DefaultRegistry:Has(actorID) then
        return false, "core_actor_not_found"
    end

    local actor = (core.Actors.Get and core.Actors.Get(actorID))
        or core.Actors.DefaultRegistry:Get(actorID)
    if not actor then
        return false, "core_actor_not_found"
    end

    local Social = service(core)
    if not Social then
        return false, "core_social_unavailable"
    end

    -- Non-destructive Core-first mutation: operate on existing Core social state
    local currentSocial = actor.social and clone(actor.social) or Social.NewState()

    -- 1. Preserve foreign top-level extensions, update ProjectHoomans top-level
    currentSocial.extensions = currentSocial.extensions or {}
    currentSocial.extensions.ProjectHoomans = {
        morale = tonumber(record.social.morale) or 0,
        moraleBaseline = tonumber(record.social.moraleBaseline) or 0,
        conduct = clone(record.social.conduct),
        lastEvaluatedAt = tonumber(record.social.lastEvaluatedAt) or 0,
    }

    -- 2. Non-destructively merge relationships
    if type(record.social.relationships) == "table" then
        currentSocial.relationships = currentSocial.relationships or {}
        for targetKey, hoomRel in pairs(record.social.relationships) do
            if type(targetKey) == "string" and type(hoomRel) == "table" then
                local resolvedKey = targetKey
                if currentSocial.aliases and currentSocial.aliases[targetKey] then
                    resolvedKey = currentSocial.aliases[targetKey]
                end

                local rel = currentSocial.relationships[resolvedKey]
                if not rel then
                    local createdRel = Social.GetOrCreate(currentSocial, resolvedKey)
                    rel = createdRel or currentSocial.relationships[resolvedKey]
                end

                if rel then
                    local hoomExt = {
                        baselineApproval = tonumber(hoomRel.baselineApproval) or 0,
                        baselineRespect = tonumber(hoomRel.baselineRespect) or 0,
                        state = hoomRel.state,
                        previousState = hoomRel.previousState,
                        bond = clone(hoomRel.bond),
                        saturation = clone(hoomRel.saturation),
                        cooldowns = clone(hoomRel.cooldowns),
                        interactionJournal = clone(hoomRel.interactionJournal),
                        interactionRevision = tonumber(hoomRel.interactionRevision) or 0,
                        lastInteractionAt = tonumber(hoomRel.lastInteractionAt) or 0,
                        lastEvaluatedAt = tonumber(hoomRel.lastEvaluatedAt) or 0,
                    }

                    local relRev = tonumber(rel.revision) or 0
                    local hoomRev = tonumber(hoomRel.revision) or 0
                    if hoomRev >= relRev then
                        if hoomRel.approval ~= nil then
                            rel.approval = math.max(Social.MIN_APPROVAL or -100,
                                math.min(Social.MAX_APPROVAL or 100, tonumber(hoomRel.approval) or 0))
                        end
                        if hoomRel.respect ~= nil then
                            rel.respect = math.max(Social.MIN_RESPECT or -100,
                                math.min(Social.MAX_RESPECT or 100, tonumber(hoomRel.respect) or 0))
                        end
                        if hoomRel.familiarity ~= nil then
                            rel.familiarity = math.max(Social.MIN_FAMILIARITY or 0,
                                math.min(Social.MAX_FAMILIARITY or 100, tonumber(hoomRel.familiarity) or 0))
                        end
                    end

                    rel.lastEventAt = math.max(
                        tonumber(rel.lastEventAt) or 0,
                        tonumber(hoomRel.lastInteractionAt) or 0,
                        tonumber(hoomRel.lastEvaluatedAt) or 0
                    )

                    -- Preserve any foreign adopter extensions (e.g. DynamicTrading)
                    rel.extensions = rel.extensions or {}
                    rel.extensions.ProjectHoomans = hoomExt

                    -- Deduplicating memory merge
                    rel.memories = rel.memories or {}
                    local existingMemoryIDs = {}
                    for _, m in ipairs(rel.memories) do
                        local mid = m.id or m.eventID
                        if mid then existingMemoryIDs[mid] = true end
                    end
                    for _, m in ipairs(hoomRel.memories or {}) do
                        local mid = m.id or m.eventID
                        if mid and not existingMemoryIDs[mid] then
                            existingMemoryIDs[mid] = true
                            rel.memories[#rel.memories + 1] = clone(m)
                        end
                    end
                    while #rel.memories > (Social.MAX_MEMORIES or 32) do
                        table.remove(rel.memories, 1)
                    end

                    rel.revision = math.max(relRev, hoomRev) + 1
                end
            end
        end
    end

    currentSocial.revision = (tonumber(currentSocial.revision) or 0) + 1

    local committed, commitReason = core.Actors.DefaultRegistry:Commit(actorID, {
        social = currentSocial,
    })
    if not committed then
        return false, commitReason
    end

    local refreshed = Adapter.FromCoreSocial(committed.social or currentSocial, record.social)
    if refreshed then
        record.social = refreshed
    end

    return true
end

function Adapter.SyncFromCore(record, core)
    core = core or PsychopatzCore
    if not core or not core.Actors or not core.Actors.DefaultRegistry then
        return false, "core_registry_unavailable"
    end
    if type(record) ~= "table" then return false, "record_missing" end
    local actorID = record.coreActorID
        or (record.runtime and record.runtime.coreActorID)
        or record.id
    local actor = actorID and core.Actors.Get and core.Actors.Get(actorID)
    if not actor or not actor.social then return false, "core_actor_not_found" end
    local reconstructed = Adapter.FromCoreSocial(actor.social, record.social)
    record.social = reconstructed
    return true
end

return Adapter
