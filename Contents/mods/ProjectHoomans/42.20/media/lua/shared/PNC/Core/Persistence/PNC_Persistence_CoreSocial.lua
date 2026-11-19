-- Read/project bridge for Core-owned directed social state. Hoomans remains
-- an adopter contributing social depth, while Core owns the canonical shared
-- relationship ledger and extension envelope.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreSocial or {}
Persistence.CoreSocial = Adapter

Adapter.MIGRATION_ID = "core_social_single_authority"
Adapter.MIGRATION_VERSION = 1

local function service(core)
    return core and core.Actors and core.Actors.Social
end

local function clone(val)
    if type(val) ~= "table" then return val end
    local res = {}
    for k, v in pairs(val) do res[k] = clone(v) end
    return res
end

local function hasEntries(value)
    if type(value) ~= "table" then return false end
    for _ in pairs(value) do return true end
    return false
end

function Adapter.ResolveCoreActorID(record)
    if type(record) ~= "table" then return nil end
    local id = record.coreActorID
        or (type(record.runtime) == "table" and record.runtime.coreActorID)
        or record.id
    if id == nil or tostring(id) == "" then return nil end
    return tostring(id)
end

function Adapter.ResolveCoreActor(record, core)
    core = core or PsychopatzCore
    if type(core) ~= "table" or type(core.Actors) ~= "table"
        or type(core.Actors.DefaultRegistry) ~= "table"
    then
        return nil, "core_registry_unavailable"
    end
    local actorID = Adapter.ResolveCoreActorID(record)
    if not actorID then
        return nil, "actor_id_missing"
    end
    local reg = core.Actors.DefaultRegistry
    if type(reg.Has) ~= "function" or not reg:Has(actorID) then
        return nil, "core_actor_not_found"
    end
    local actor = (type(core.Actors.Get) == "function" and core.Actors.Get(actorID))
        or (type(reg.Get) == "function" and reg:Get(actorID))
    if type(actor) ~= "table" then
        return nil, "core_actor_not_found"
    end
    return actor, actorID
end

function Adapter.IsCoreBacked(record, core)
    local actor = Adapter.ResolveCoreActor(record, core)
    return actor ~= nil
end

function Adapter.HasGenericSocialPayload(social)
    if type(social) ~= "table" or social.authority == "core" then
        return false
    end
    if hasEntries(social.recentEventIDs)
        or hasEntries(social.personality)
        or (type(social.memoryBank) == "table" and #social.memoryBank > 0)
    then
        return true
    end
    if type(social.relationships) == "table" then
        for _, rel in pairs(social.relationships) do
            if type(rel) == "table" then
                if (tonumber(rel.approval) or 0) ~= 0
                    or (tonumber(rel.respect) or 0) ~= 0
                    or (tonumber(rel.familiarity) or 0) ~= 0
                    or (tonumber(rel.baselineApproval) or 0) ~= 0
                    or (tonumber(rel.baselineRespect) or 0) ~= 0
                    or (type(rel.memories) == "table" and #rel.memories > 0)
                    or hasEntries(rel.cooldowns)
                    or hasEntries(rel.saturation)
                    or (rel.state ~= nil and rel.state ~= "unknown")
                then
                    return true
                end
            end
        end
    end
    return false
end

function Adapter.ToCoreSocial(recordSocial, core)
    local Social = service(core or PsychopatzCore)
    if not Social or type(Social.NewState) ~= "function" then
        return nil, "core_social_unavailable"
    end
    if type(recordSocial) ~= "table" then
        return nil, "source_social_missing"
    end

    local conductCopy = clone(recordSocial.conduct)
    if type(conductCopy) == "table" then
        conductCopy.scores = nil
    end

    local existingExt = type(recordSocial.extensions) == "table"
        and clone(recordSocial.extensions) or {}
    existingExt.ProjectHoomans = {
        morale = tonumber(recordSocial.morale) or 0,
        moraleBaseline = tonumber(recordSocial.moraleBaseline) or 0,
        conduct = conductCopy,
        lastEvaluatedAt = tonumber(recordSocial.lastEvaluatedAt) or 0,
    }

    local relationships = {}
    local memoryBank = {}
    if type(recordSocial.relationships) == "table" then
        for targetKey, rel in pairs(recordSocial.relationships) do
            if type(targetKey) == "string" and type(rel) == "table" then
                local relExt = type(rel.extensions) == "table"
                    and clone(rel.extensions) or {}
                relExt.ProjectHoomans = {
                    bond = clone(rel.bond),
                    interactionRevision = tonumber(rel.interactionRevision) or 0,
                    interactionJournal = recordSocial.runtimeView == true
                        and clone(rel.interactionJournal) or nil,
                }
                relationships[targetKey] = {
                    targetKey = targetKey,
                    approval = tonumber(rel.approval) or 0,
                    respect = tonumber(rel.respect) or 0,
                    familiarity = tonumber(rel.familiarity) or 0,
                    baselineApproval = tonumber(rel.baselineApproval) or 0,
                    baselineRespect = tonumber(rel.baselineRespect) or 0,
                    state = rel.state,
                    previousState = rel.previousState,
                    cooldowns = clone(rel.cooldowns),
                    saturation = clone(rel.saturation),
                    revision = tonumber(rel.revision) or 0,
                    lastEventAt = rel.lastInteractionAt or rel.lastEvaluatedAt,
                    lastEvaluatedAt = tonumber(rel.lastEvaluatedAt) or 0,
                    extensions = relExt,
                }
                for _, mem in ipairs(rel.memories or {}) do
                    if type(mem) == "table" then
                        local mCopy = clone(mem)
                        mCopy.aboutKey = targetKey
                        memoryBank[#memoryBank + 1] = mCopy
                    end
                end
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
        memoryBank = memoryBank,
        extensions = existingExt,
    })
end

function Adapter.FromCoreSocial(coreSocial, fallbackSocial)
    if type(coreSocial) ~= "table" then return nil, "core_social_missing" end
    fallbackSocial = type(fallbackSocial) == "table" and fallbackSocial or {}
    local Social = service(PsychopatzCore)

    local hoomansExt = coreSocial.extensions
        and coreSocial.extensions.ProjectHoomans or {}
    local Types = PNC.RelationshipTypes
    local Constants = PNC.RelationshipConstants
    local extMap = type(fallbackSocial.relationshipExtensions) == "table"
        and fallbackSocial.relationshipExtensions or nil
    local relMap = type(fallbackSocial.relationships) == "table"
        and fallbackSocial.relationships or nil
    local isCoreEnvelope = fallbackSocial.authority == "core"

    local relationships = {}
    if type(coreSocial.relationships) == "table" then
        for targetKey, coreRel in pairs(coreSocial.relationships) do
            if type(targetKey) == "string" and type(coreRel) == "table" then
                local extEntry = extMap and type(extMap[targetKey]) == "table"
                    and extMap[targetKey] or nil
                local relEntry = relMap and type(relMap[targetKey]) == "table"
                    and relMap[targetKey] or nil
                local fallbackRel = relEntry or extEntry or {}
                if relEntry and extEntry then
                    local relHasBond = type(relEntry.bond) == "table"
                        and tostring(relEntry.bond.class or "none") ~= "none"
                    local relHasJournal = type(relEntry.interactionJournal) == "table"
                        and #relEntry.interactionJournal > 0
                    if relHasBond or relHasJournal
                        or (tonumber(relEntry.interactionRevision) or 0) > 0
                    then
                        fallbackRel = relEntry
                    else
                        fallbackRel = extEntry
                    end
                end
                local relExt = coreRel.extensions
                    and coreRel.extensions.ProjectHoomans or {}

                local state = coreRel.state or relExt.state or fallbackRel.state
                if not state or state == "" then
                    if PNC.RelationshipStates
                        and type(PNC.RelationshipStates.ResolveState) == "function"
                    then
                        state = PNC.RelationshipStates.ResolveState(coreRel)
                    else
                        state = Constants and Constants.STATE_UNKNOWN or "unknown"
                    end
                end

                local targetMemories
                if Social and type(Social.GetMemoriesForTarget) == "function"
                    and type(coreSocial.memoryBank) == "table"
                then
                    targetMemories = Social.GetMemoriesForTarget(coreSocial, targetKey)
                else
                    targetMemories = clone(coreRel.memories or {})
                end

                local baseApp = coreRel.baselineApproval
                if baseApp == nil then baseApp = relExt.baselineApproval end
                local baseResp = coreRel.baselineRespect
                if baseResp == nil then baseResp = relExt.baselineRespect end
                if baseApp == nil or baseResp == nil then
                    local memApp, memResp = 0, 0
                    for _, m in ipairs(targetMemories) do
                        memApp = memApp + (tonumber(m.approvalEffect) or 0)
                        memResp = memResp + (tonumber(m.respectEffect) or 0)
                    end
                    if baseApp == nil then
                        baseApp = fallbackRel.baselineApproval ~= nil
                            and tonumber(fallbackRel.baselineApproval)
                            or ((tonumber(coreRel.approval) or 0) - memApp)
                    end
                    if baseResp == nil then
                        baseResp = fallbackRel.baselineRespect ~= nil
                            and tonumber(fallbackRel.baselineRespect)
                            or ((tonumber(coreRel.respect) or 0) - memResp)
                    end
                end

                local fallbackBond = fallbackRel.bond
                local fallbackHasBond = type(fallbackBond) == "table"
                    and (tostring(fallbackBond.class or "none") ~= "none"
                        or isCoreEnvelope)
                local bondValue = fallbackHasBond and fallbackBond
                    or (relExt.bond or fallbackBond)

                local fallbackJournal = fallbackRel.interactionJournal
                local fallbackHasJournal = type(fallbackJournal) == "table"
                    and (#fallbackJournal > 0 or isCoreEnvelope)
                local journalValue = fallbackHasJournal and fallbackJournal
                    or (relExt.interactionJournal or fallbackJournal or {})

                local fallbackIntRev = tonumber(fallbackRel.interactionRevision)
                local interactionRev
                if (fallbackIntRev and fallbackIntRev > 0) or isCoreEnvelope then
                    interactionRev = fallbackIntRev or 0
                else
                    interactionRev = tonumber(relExt.interactionRevision)
                        or fallbackIntRev or 0
                end

                local lastIntAt = tonumber(fallbackRel.lastInteractionAt)
                if not lastIntAt or lastIntAt == 0 then
                    lastIntAt = tonumber(relExt.lastInteractionAt)
                        or tonumber(coreRel.lastEventAt) or 0
                end

                relationships[targetKey] = {
                    targetKey = targetKey,
                    approval = tonumber(coreRel.approval) or 0,
                    respect = tonumber(coreRel.respect) or 0,
                    familiarity = tonumber(coreRel.familiarity) or 0,
                    revision = tonumber(coreRel.revision) or 0,
                    baselineApproval = tonumber(baseApp) or 0,
                    baselineRespect = tonumber(baseResp) or 0,
                    state = state,
                    previousState = coreRel.previousState
                        or relExt.previousState
                        or fallbackRel.previousState
                        or Constants and Constants.STATE_UNKNOWN or "unknown",
                    bond = clone(bondValue),
                    saturation = clone(coreRel.saturation or relExt.saturation or fallbackRel.saturation or {}),
                    cooldowns = clone(coreRel.cooldowns or relExt.cooldowns or fallbackRel.cooldowns or {}),
                    interactionJournal = clone(journalValue),
                    interactionRevision = interactionRev,
                    lastInteractionAt = lastIntAt,
                    lastEvaluatedAt = tonumber(coreRel.lastEvaluatedAt
                        or relExt.lastEvaluatedAt or fallbackRel.lastEvaluatedAt) or 0,
                    memories = targetMemories,
                    extensions = clone(coreRel.extensions or {}),
                }
            end
        end
    end

    if type(extMap) == "table" then
        for targetKey, extRel in pairs(extMap) do
            if type(targetKey) == "string" and relationships[targetKey] == nil
                and type(extRel) == "table"
            then
                relationships[targetKey] = {
                    targetKey = targetKey,
                    approval = 0,
                    respect = 0,
                    familiarity = 0,
                    revision = 0,
                    baselineApproval = 0,
                    baselineRespect = 0,
                    state = Constants and Constants.STATE_UNKNOWN or "unknown",
                    previousState = Constants and Constants.STATE_UNKNOWN or "unknown",
                    bond = clone(extRel.bond),
                    saturation = {},
                    cooldowns = {},
                    interactionJournal = clone(extRel.interactionJournal or {}),
                    interactionRevision = tonumber(extRel.interactionRevision) or 0,
                    lastInteractionAt = tonumber(extRel.lastInteractionAt) or 0,
                    lastEvaluatedAt = 0,
                    memories = {},
                    extensions = {},
                }
            end
        end
    end

    local moraleVal
    if isCoreEnvelope or (tonumber(fallbackSocial.morale) ~= nil and tonumber(fallbackSocial.morale) ~= 0) then
        moraleVal = tonumber(fallbackSocial.morale) or 0
    else
        moraleVal = tonumber(hoomansExt.morale) or tonumber(fallbackSocial.morale) or 0
    end

    local moraleBaseVal
    if isCoreEnvelope or (tonumber(fallbackSocial.moraleBaseline) ~= nil and tonumber(fallbackSocial.moraleBaseline) ~= 0) then
        moraleBaseVal = tonumber(fallbackSocial.moraleBaseline) or 0
    else
        moraleBaseVal = tonumber(hoomansExt.moraleBaseline) or tonumber(fallbackSocial.moraleBaseline) or 0
    end

    local lastEvalVal
    if isCoreEnvelope or (tonumber(fallbackSocial.lastEvaluatedAt) ~= nil and tonumber(fallbackSocial.lastEvaluatedAt) ~= 0) then
        lastEvalVal = tonumber(fallbackSocial.lastEvaluatedAt) or 0
    else
        lastEvalVal = tonumber(hoomansExt.lastEvaluatedAt) or tonumber(fallbackSocial.lastEvaluatedAt) or 0
    end

    local fallbackHasConduct = type(fallbackSocial.conduct) == "table"
        and (isCoreEnvelope
            or (type(fallbackSocial.conduct.evidence) == "table" and #fallbackSocial.conduct.evidence > 0)
            or (tonumber(fallbackSocial.conduct.revision) or 0) > 0)
    local conductVal = fallbackHasConduct and fallbackSocial.conduct
        or (hoomansExt.conduct or fallbackSocial.conduct)

    local personalityVal = hasEntries(coreSocial.personality)
        and coreSocial.personality or (fallbackSocial.personality or {})
    local overridesVal = hasEntries(fallbackSocial.personalityOverrides)
        and fallbackSocial.personalityOverrides
        or (hasEntries(coreSocial.personalityOverrides) and coreSocial.personalityOverrides or {})

    local reconstructed = {
        schemaVersion = Constants and Constants.SOCIAL_SCHEMA_VERSION or 4,
        revision = tonumber(coreSocial.revision) or 0,
        morale = moraleVal,
        moraleBaseline = moraleBaseVal,
        conduct = clone(conductVal),
        lastEvaluatedAt = lastEvalVal,
        personality = clone(personalityVal),
        personalityOverrides = clone(overridesVal),
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

function Adapter.SyncToCore(record, core, changeSpec)
    core = core or PsychopatzCore
    if not core or not core.Actors or not core.Actors.DefaultRegistry then
        return false, "core_registry_unavailable"
    end
    if type(record) ~= "table" or type(record.social) ~= "table" then
        return false, "record_social_missing"
    end
    local actorID = Adapter.ResolveCoreActorID(record)
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

    local isTransientView = record.runtimeView == true and record.persist == false

    -- Non-destructive Core-first mutation: operate on existing Core social state
    local currentSocial = actor.social and clone(actor.social) or Social.NewState()

    -- A newly registered Core actor may legitimately have an empty social
    -- personality while the existing Hoomans record already carries the
    -- authored/generated profile. Seed that empty Core slot once; never let a
    -- stale Hoomans projection replace a non-empty Core-owned personality.
    if not hasEntries(currentSocial.personality)
        and hasEntries(record.social.personality)
    then
        currentSocial.personality = clone(record.social.personality)
    end
    if not hasEntries(currentSocial.personalityOverrides)
        and hasEntries(record.social.personalityOverrides)
    then
        currentSocial.personalityOverrides = clone(record.social.personalityOverrides)
    end

    -- 1. Preserve foreign top-level extensions, update ProjectHoomans top-level
    local conductCopy = clone(record.social.conduct)
    if type(conductCopy) == "table" then
        conductCopy.scores = nil
    end
    currentSocial.extensions = currentSocial.extensions or {}
    currentSocial.extensions.ProjectHoomans = {
        morale = tonumber(record.social.morale) or 0,
        moraleBaseline = tonumber(record.social.moraleBaseline) or 0,
        conduct = conductCopy,
        lastEvaluatedAt = tonumber(record.social.lastEvaluatedAt) or 0,
    }

    if type(changeSpec) == "table"
        and changeSpec.kind == "relationship_key_migrated"
        and type(changeSpec.legacyTargetKey) == "string"
        and type(currentSocial.relationships) == "table"
    then
        currentSocial.relationships[changeSpec.legacyTargetKey] = nil
    end

    -- 2. Non-destructively merge relationships and actor-level memoryBank
    currentSocial.memoryBank = currentSocial.memoryBank or {}
    if type(changeSpec) == "table"
        and changeSpec.kind == "memory_removed"
        and type(changeSpec.memoryID) == "string"
    then
        if type(Social.RemoveMemory) == "function" then
            Social.RemoveMemory(currentSocial, changeSpec.memoryID, "server")
        else
            local filtered = {}
            for _, m in ipairs(currentSocial.memoryBank) do
                local mid = m.id or m.eventID
                if mid ~= changeSpec.memoryID then
                    filtered[#filtered + 1] = m
                end
            end
            currentSocial.memoryBank = filtered
        end
    end

    local existingMemoryIDs = {}
    for _, m in ipairs(currentSocial.memoryBank) do
        local mid = m.id or m.eventID
        if mid then existingMemoryIDs[mid] = true end
    end
    local maxWorldAge = nil

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
                        bond = clone(hoomRel.bond),
                        interactionRevision = tonumber(hoomRel.interactionRevision) or 0,
                    }
                    if isTransientView then
                        hoomExt.interactionJournal = clone(hoomRel.interactionJournal)
                    end

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
                        if hoomRel.baselineApproval ~= nil then
                            rel.baselineApproval = tonumber(hoomRel.baselineApproval) or 0
                        end
                        if hoomRel.baselineRespect ~= nil then
                            rel.baselineRespect = tonumber(hoomRel.baselineRespect) or 0
                        end
                        if hoomRel.state ~= nil then rel.state = hoomRel.state end
                        if hoomRel.previousState ~= nil then rel.previousState = hoomRel.previousState end
                        if hoomRel.cooldowns ~= nil then rel.cooldowns = clone(hoomRel.cooldowns) end
                        if hoomRel.saturation ~= nil then rel.saturation = clone(hoomRel.saturation) end
                        if hoomRel.lastEvaluatedAt ~= nil then
                            rel.lastEvaluatedAt = tonumber(hoomRel.lastEvaluatedAt) or 0
                        end
                    end

                    rel.lastEventAt = math.max(
                        tonumber(rel.lastEventAt) or 0,
                        tonumber(hoomRel.lastInteractionAt) or 0,
                        tonumber(hoomRel.lastEvaluatedAt) or 0
                    )

                    -- Preserve any foreign adopter extensions (e.g. DynamicTrading)
                    rel.extensions = rel.extensions or {}
                    if hoomRev >= relRev or not rel.extensions.ProjectHoomans then
                        rel.extensions.ProjectHoomans = hoomExt
                    end

                    rel.memories = nil
                    local ageCandidate = tonumber(hoomRel.lastEvaluatedAt) or tonumber(rel.lastEvaluatedAt)
                    if ageCandidate ~= nil and (maxWorldAge == nil or ageCandidate > maxWorldAge) then
                        maxWorldAge = ageCandidate
                    end

                    -- Deduplicating memory merge into Core actor-level memoryBank
                    for _, m in ipairs(hoomRel.memories or {}) do
                        local mid = m.id or m.eventID
                        if mid and not existingMemoryIDs[mid] then
                            existingMemoryIDs[mid] = true
                            local cloned = clone(m)
                            cloned.id = mid
                            cloned.aboutKey = resolvedKey
                            if Social.ConsolidateOrInsertMemory then
                                Social.ConsolidateOrInsertMemory(currentSocial, cloned, {
                                    consolidate = false,
                                    worldAgeHours = ageCandidate,
                                })
                            else
                                currentSocial.memoryBank[#currentSocial.memoryBank + 1] = cloned
                            end
                        end
                    end

                    rel.revision = math.max(relRev, hoomRev) + 1
                end
            end
        end
    end

    if Social.PruneMemories then
        Social.PruneMemories(currentSocial, maxWorldAge)
    else
        local maxActorMemories = Social.MAX_ACTOR_MEMORIES or Social.MAX_MEMORIES or 96
        while #currentSocial.memoryBank > maxActorMemories do
            table.remove(currentSocial.memoryBank, 1)
        end
    end
    if type(Social.InvalidateMemoryIndex) == "function" then
        Social.InvalidateMemoryIndex(currentSocial)
    end

    currentSocial.recentEventIDs = currentSocial.recentEventIDs or {}
    local seenRecent = {}
    for _, eid in ipairs(currentSocial.recentEventIDs) do
        seenRecent[eid] = true
    end
    for _, eid in ipairs(record.social.recentEventIDs or {}) do
        if type(eid) == "string" and eid ~= "" and not seenRecent[eid] then
            seenRecent[eid] = true
            currentSocial.recentEventIDs[#currentSocial.recentEventIDs + 1] = eid
        end
    end
    local maxRecent = Social.MAX_RECENT_EVENTS or 128
    while #currentSocial.recentEventIDs > maxRecent do
        table.remove(currentSocial.recentEventIDs, 1)
    end

    currentSocial.revision = (tonumber(currentSocial.revision) or 0) + 1

    local authority = core.Actors.SocialAuthority
    if not authority or type(authority.CommitSocial) ~= "function" then
        return false, "core_social_authority_unavailable"
    end
    local committed, commitReason = authority.CommitSocial(
        actorID,
        currentSocial,
        core,
        actor.revision
    )
    if not committed then
        return false, commitReason
    end

    record.persistenceRepairVersions = type(record.persistenceRepairVersions) == "table"
        and record.persistenceRepairVersions or {}
    record.persistenceRepairVersions[Adapter.MIGRATION_ID] = Adapter.MIGRATION_VERSION
    if type(record.runtime) == "table" then
        record.runtime.coreSocialHydrationPending = nil
    end

    local refreshed = Adapter.FromCoreSocial(committed.social or currentSocial, record.social)
    if refreshed then
        record.social = refreshed
    end

    return true
end

function Adapter.SyncFromCore(record, core)
    core = core or PsychopatzCore
    if type(record) ~= "table" then return false, "record_missing" end
    local actor, actorReason = Adapter.ResolveCoreActor(record, core)
    if not actor then
        return false, actorReason == "core_registry_unavailable"
            and "core_registry_unavailable" or "core_actor_not_found"
    end
    if type(actor.social) ~= "table" then return false, "core_actor_not_found" end
    local reconstructed = Adapter.FromCoreSocial(actor.social, record.social)
    record.social = reconstructed
    if type(record.runtime) == "table" then
        record.runtime.coreSocialHydrationPending = nil
    end
    return true
end

function Adapter.EnsureRuntimeView(record, core)
    core = core or PsychopatzCore
    local actor = Adapter.ResolveCoreActor(record, core)
    if not actor or type(actor.social) ~= "table" then
        return record and record.social or nil
    end
    local current = type(record.social) == "table" and record.social or nil
    local pending = (type(record.runtime) == "table"
        and record.runtime.coreSocialHydrationPending == true)
        or (current and current.authority == "core")
    local coreRev = tonumber(actor.social.revision) or 0
    local localRev = tonumber(current and current.revision) or -1
    if not current or pending or coreRev > localRev then
        Adapter.SyncFromCore(record, core)
    end
    return record.social
end

function Adapter.BuildExtensionEnvelope(record, actorID)
    local Constants = PNC.RelationshipConstants
    local Types = PNC.RelationshipTypes
    local social = type(record) == "table" and type(record.social) == "table"
        and record.social or {}

    local conduct = nil
    if PNC.ConductTypes and type(PNC.ConductTypes.NormalizeConductRecord) == "function" then
        conduct = PNC.ConductTypes.NormalizeConductRecord(social.conduct)
    elseif type(social.conduct) == "table" then
        conduct = clone(social.conduct)
    end
    if type(conduct) == "table" then
        conduct.scores = nil
    end

    local relationshipExtensions = {}
    local function mergeRelExt(targetKey, rel)
        if type(targetKey) ~= "string" or type(rel) ~= "table" then return end
        local bond = Types and type(Types.NormalizeBond) == "function"
            and Types.NormalizeBond(rel.bond) or clone(rel.bond)
        local journal = Types and type(Types.NormalizeInteractionJournal) == "function"
            and Types.NormalizeInteractionJournal(rel.interactionJournal)
            or clone(rel.interactionJournal or {})
        local interactionRev = math.max(0, math.floor(tonumber(rel.interactionRevision) or 0))
        local lastInteractionAt = math.max(0, tonumber(rel.lastInteractionAt) or 0)
        local hasBond = type(bond) == "table" and tostring(bond.class or "none") ~= "none"
        local hasJournal = type(journal) == "table" and #journal > 0
        if hasBond or hasJournal or interactionRev > 0 or lastInteractionAt > 0 then
            relationshipExtensions[targetKey] = {
                bond = hasBond and bond or nil,
                interactionJournal = hasJournal and journal or nil,
                interactionRevision = interactionRev > 0 and interactionRev or nil,
                lastInteractionAt = lastInteractionAt > 0 and lastInteractionAt or nil,
            }
        end
    end

    if type(social.relationshipExtensions) == "table" then
        for targetKey, rel in pairs(social.relationshipExtensions) do
            mergeRelExt(targetKey, rel)
        end
    end
    if type(social.relationships) == "table" then
        for targetKey, rel in pairs(social.relationships) do
            mergeRelExt(targetKey, rel)
        end
    end

    return {
        schemaVersion = Constants and Constants.SOCIAL_SCHEMA_VERSION or 4,
        authority = "core",
        coreSocialMigrationVersion = Adapter.MIGRATION_VERSION,
        coreActorID = tostring(actorID),
        morale = tonumber(social.morale) or 0,
        moraleBaseline = tonumber(social.moraleBaseline) or 0,
        lastEvaluatedAt = tonumber(social.lastEvaluatedAt) or 0,
        personalityOverrides = hasEntries(social.personalityOverrides)
            and clone(social.personalityOverrides) or nil,
        conduct = conduct,
        relationshipExtensions = relationshipExtensions,
    }
end

function Adapter.MigrateLegacyRecordToCore(record, rawSocial, core)
    core = core or PsychopatzCore
    if type(record) ~= "table" then
        return false, "record_missing"
    end
    local actor = Adapter.ResolveCoreActor(record, core)
    if not actor then
        return false, "core_actor_not_found"
    end
    record.persistenceRepairVersions = type(record.persistenceRepairVersions) == "table"
        and record.persistenceRepairVersions or {}
    local version = tonumber(record.persistenceRepairVersions[Adapter.MIGRATION_ID])
        or (type(record.runtime) == "table" and tonumber(record.runtime.coreSocialMigratedVersion))
        or 0
    local sourceSocial = type(rawSocial) == "table" and rawSocial or record.social
    if version >= Adapter.MIGRATION_VERSION
        or (type(sourceSocial) == "table" and sourceSocial.authority == "core")
    then
        record.persistenceRepairVersions[Adapter.MIGRATION_ID] =
            math.max(version, Adapter.MIGRATION_VERSION)
        Adapter.SyncFromCore(record, core)
        return false, "already_migrated"
    end

    if type(sourceSocial) == "table" and sourceSocial ~= record.social then
        if PNC.RelationshipTypes
            and type(PNC.RelationshipTypes.NormalizeSocialState) == "function"
        then
            record.social = PNC.RelationshipTypes.NormalizeSocialState(
                sourceSocial,
                record.identitySeed,
                record.archetypeID
            )
        else
            record.social = clone(sourceSocial)
        end
    end

    if type(record.social) == "table" then
        local ok, reason = Adapter.SyncToCore(record, core)
        if not ok then
            return false, reason
        end
    else
        Adapter.SyncFromCore(record, core)
    end

    record.persistenceRepairVersions[Adapter.MIGRATION_ID] = Adapter.MIGRATION_VERSION
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    record.runtime.coreSocialMigratedVersion = Adapter.MIGRATION_VERSION
    record.runtime.coreSocialHydrationPending = nil
    if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
        PNC.Registry.MarkDirty(record, Adapter.MIGRATION_ID)
    end
    return true, "migrated_to_core"
end

function Adapter.SerializeRecord(record, core)
    core = core or PsychopatzCore
    local actor, actorID = Adapter.ResolveCoreActor(record, core)
    if not actor then
        return nil, "not_core_backed"
    end
    record.persistenceRepairVersions = type(record.persistenceRepairVersions) == "table"
        and record.persistenceRepairVersions or {}
    local migratedVersion = tonumber(record.persistenceRepairVersions[Adapter.MIGRATION_ID]) or 0
    local localSocial = type(record.social) == "table" and record.social or {}
    local coreSocial = type(actor.social) == "table" and actor.social or {}
    local localRev = tonumber(localSocial.revision) or 0
    local coreRev = tonumber(coreSocial.revision) or 0
    local needsSync = (migratedVersion < Adapter.MIGRATION_VERSION
            and Adapter.HasGenericSocialPayload(localSocial))
        or (localSocial.authority ~= "core" and localRev > coreRev)
        or (localSocial.authority ~= "core"
            and hasEntries(localSocial.relationships)
            and not hasEntries(coreSocial.relationships))
    if needsSync then
        Adapter.SyncToCore(record, core)
    end
    record.persistenceRepairVersions[Adapter.MIGRATION_ID] = Adapter.MIGRATION_VERSION
    return Adapter.BuildExtensionEnvelope(record, actorID)
end

function Adapter.RestoreRecord(record, raw, core)
    core = core or PsychopatzCore
    if type(record) ~= "table" then
        return false, "record_missing"
    end
    local rawSocial = type(raw) == "table" and raw.social or nil
    if type(rawSocial) == "table" and rawSocial.authority == "core" then
        if type(rawSocial.coreActorID) == "string" and rawSocial.coreActorID ~= "" then
            record.coreActorID = record.coreActorID or rawSocial.coreActorID
        end
        record.persistenceRepairVersions = type(record.persistenceRepairVersions) == "table"
            and record.persistenceRepairVersions or {}
        record.persistenceRepairVersions[Adapter.MIGRATION_ID] = math.max(
            tonumber(record.persistenceRepairVersions[Adapter.MIGRATION_ID]) or 0,
            tonumber(rawSocial.coreSocialMigrationVersion) or Adapter.MIGRATION_VERSION
        )
        record.social = type(record.social) == "table" and record.social or {}
        record.social.authority = "core"
        record.social.relationshipExtensions = clone(rawSocial.relationshipExtensions or {})
        record.social.relationships = type(record.social.relationships) == "table"
            and record.social.relationships or {}
        local Types = PNC.RelationshipTypes
        for targetKey, extRel in pairs(record.social.relationshipExtensions) do
            if type(targetKey) == "string" and type(extRel) == "table" then
                if Types and type(Types.NormalizeRelationship) == "function" then
                    record.social.relationships[targetKey] =
                        Types.NormalizeRelationship(extRel, targetKey)
                else
                    record.social.relationships[targetKey] = clone(extRel)
                end
            end
        end
        if Adapter.IsCoreBacked(record, core) then
            Adapter.SyncFromCore(record, core)
            return true, "hydrated_from_core"
        end
        record.runtime = type(record.runtime) == "table" and record.runtime or {}
        record.runtime.coreSocialHydrationPending = true
        return true, "core_hydration_deferred"
    elseif type(rawSocial) == "table" then
        local migratedVersion = tonumber(
            record.persistenceRepairVersions
                and record.persistenceRepairVersions[Adapter.MIGRATION_ID]
        ) or 0
        if Adapter.IsCoreBacked(record, core) then
            if migratedVersion >= Adapter.MIGRATION_VERSION then
                Adapter.SyncFromCore(record, core)
                return true, "already_migrated_hydrated"
            end
            return Adapter.MigrateLegacyRecordToCore(record, rawSocial, core)
        end
        return false, "standalone_record"
    end
    return false, "social_missing"
end

return Adapter
