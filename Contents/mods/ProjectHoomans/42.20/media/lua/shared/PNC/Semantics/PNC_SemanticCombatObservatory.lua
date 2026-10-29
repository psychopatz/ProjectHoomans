-- Bounded read-only explanation surface for semantic combat speech.
-- It composes snapshots from existing production owners and never decides,
-- dispatches, persists, or scans combat state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Observatory = PNC.Semantics.CombatObservatory or {}
PNC.Semantics.CombatObservatory = Observatory

local Moment = PNC.Semantics.CombatMoment
    or require "PNC/Semantics/PNC_SemanticCombatMoment"
local Arbiter = PNC.Semantics.CombatBanterArbiter
    or require "PNC/Semantics/PNC_SemanticCombatBanterArbiter"
local Encounter = PNC.Semantics.CombatEncounterIntent
    or require "PNC/Semantics/PNC_SemanticCombatEncounterIntent"
local Catalog = PNC.Semantics.ResponseCatalog
    or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"

Observatory.VERSION = 1
Observatory.SCHEMA = "semantic.combat.observatory.v1"
Observatory.MAX_DECISIONS = 8
Observatory.MAX_OFFERS = 8

local function clean(value)
    if value == nil then return nil end
    value = tostring(value)
    return value ~= "" and value or nil
end

local function number(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return nil end
    return value
end

local function copyRow(source)
    if type(source) ~= "table" then return nil end
    local output = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            local nested = {}
            for nestedKey, nestedValue in pairs(value) do
                if type(nestedValue) ~= "table" then
                    nested[nestedKey] = nestedValue
                end
            end
            output[key] = nested
        else
            output[key] = value
        end
    end
    return output
end

local function hordeEpisode(record)
    local state = record and record.runtime
        and record.runtime.zombieHordeAwareness or nil
    if type(state) ~= "table" then return nil end
    return {
        active = state.active == true,
        sequence = math.max(0, math.floor(number(state.sequence) or 0)),
        phase = clean(state.lastPhase),
        episodeID = clean(state.episodeID),
        lastEpisodeID = clean(state.lastEpisodeID),
        countBand = clean(state.lastBand),
        nearbyCount = number(state.lastCount),
        startedAt = number(state.startedAt),
        clearedAt = number(state.clearedAt),
        lastObservedAt = number(state.lastObservedAt),
    }
end

local function decisionMatches(row, npcID, eventRef)
    if type(row) ~= "table" then return false end
    if eventRef and clean(row.eventRef) == eventRef then return true end
    if npcID then
        if clean(row.speakerID) == npcID then return true end
        local moment = type(row.moment) == "table" and row.moment or nil
        if moment and clean(moment.actorID) == npcID then return true end
    end
    return npcID == nil and eventRef == nil
end

local function relevantDecisions(snapshot, npcID, eventRef, limit)
    local source = type(snapshot) == "table" and snapshot.decisions or {}
    local output = {}
    for index = #source, 1, -1 do
        local row = source[index]
        if decisionMatches(row, npcID, eventRef) then
            table.insert(output, 1, copyRow(row))
            if #output >= limit then break end
        end
    end
    return output
end

local function latestByStage(decisions, stage)
    for index = #decisions, 1, -1 do
        local row = decisions[index]
        if stage == nil or tostring(row.stage or "") == stage then
            return row
        end
    end
    return nil
end

local function latestGate(decisions)
    for index = #decisions, 1, -1 do
        local row = decisions[index]
        if tostring(row.stage or "") ~= "presentation" then
            return row
        end
    end
    return nil
end

local function boundedOffers(planID, realizationID)
    local output = {}
    if not planID or not realizationID
        or not Catalog or type(Catalog.OffersForSelection) ~= "function"
    then
        return output
    end
    local offers = Catalog.OffersForSelection(planID, realizationID) or {}
    for index = 1, math.min(#offers, Observatory.MAX_OFFERS) do
        local offer = offers[index]
        local frame = type(offer) == "table"
            and type(offer.frame) == "table" and offer.frame or {}
        output[#output + 1] = {
            id = clean(offer and offer.id),
            visibility = clean(offer and offer.visibility) or "player",
            labelKey = clean(offer and offer.labelKey),
            labelFallback = clean(offer and offer.labelFallback),
            action = clean(frame.action),
            intent = clean(frame.intent),
            speechAct = clean(frame.speechAct),
            subject = clean(frame.subject),
            target = clean(frame.target),
        }
    end
    return output
end

local function tacticalProjection(presentation, gate, options)
    options = type(options) == "table" and options or {}
    local spatial = options.tacticalSpatial
        or presentation and presentation.tacticalSpatial
        or gate and gate.tacticalSpatial
    local realized = options.tacticalPresentation
        or presentation and presentation.tacticalPresentation
        or gate and gate.tacticalPresentation
    spatial = copyRow(spatial)
    realized = copyRow(realized)

    local mode = clean(
        realized and realized.mode
            or spatial and spatial.presentationMode
    )
    local reason = clean(
        realized and realized.reason
            or spatial and spatial.presentationReason
    )
    if not mode and not spatial and not realized then
        return {
            available = false,
            presentationMode = "omitted",
            suppressionReason = "tactical_spatial_unavailable",
        }
    end
    return {
        available = spatial ~= nil,
        targetKind = clean(spatial and spatial.targetKind),
        targetRef = clean(spatial and spatial.targetRef),
        targetPositionSource = clean(
            spatial and spatial.targetPositionSource
        ),
        headingSource = clean(spatial and spatial.headingSource),
        clockToken = clean(spatial and spatial.clockToken),
        relativeSector8 = clean(spatial and spatial.relativeSector8),
        distanceBand = clean(spatial and spatial.distanceBand),
        freshnessMs = number(spatial and spatial.freshnessMs),
        presentationMode = mode or "omitted",
        presentationReason = reason,
        presentationTemplateID = clean(realized and realized.templateID),
        presentationTranslationKey = clean(
            realized and realized.translationKey
        ),
        suppressionReason = (mode == "omitted" or mode == nil)
            and reason or nil,
    }
end

local function weaponPredicates(moment)
    moment = type(moment) == "table" and moment or {}
    local family = clean(moment.weaponFamily)
    local skill = clean(moment.weaponSkill)
    local band = clean(moment.weaponSkillBand)
    local displayName = clean(moment.weaponDisplayName)
    return {
        attackType = clean(moment.attackType),
        attackKind = clean(moment.attackKind),
        family = family,
        familyKnown = family ~= nil and family ~= "unknown",
        skill = skill,
        skillKnown = skill ~= nil,
        skillLevel = number(moment.weaponSkillLevel),
        skillBand = band,
        highSkill = band == "high" or band == "expert",
        nameEligible = moment.weaponNameEligible == true,
        nameAvailable = moment.weaponNameEligible == true
            and displayName ~= nil,
        displayName = moment.weaponNameEligible == true
            and displayName or nil,
        hitZone = clean(moment.hitZone),
        headNeckResult = clean(moment.hitZone) == "head_neck",
        woundType = clean(moment.woundType),
    }
end

local function explanation(gate, presentation, class, offers)
    local outcome = "unknown"
    local reason = "no_combat_decision"
    local stage
    if presentation then
        stage = "presentation"
        reason = clean(presentation.reason) or "presentation_unknown"
        if presentation.accepted == true then
            outcome = class == "TACTICAL_PROMPT" and "asked" or "spoke"
        else
            outcome = "silent"
        end
    elseif gate then
        stage = clean(gate.stage)
        reason = clean(gate.reason) or "arbiter_unknown"
        outcome = gate.accepted == true and "eligible" or "silent"
    end
    return {
        outcome = outcome,
        reason = reason,
        stage = stage,
        presentationClass = class,
        responseRequired = class == "TACTICAL_PROMPT",
        offerCount = #offers,
        chosenLine = presentation and clean(presentation.realizationID) or nil,
    }
end

function Observatory.Inspect(record, options)
    options = type(options) == "table" and options or {}
    local npcID = clean(options.npcID or record and record.id)
    local eventRef = clean(options.eventRef)
    local limit = math.max(
        1,
        math.min(
            Observatory.MAX_DECISIONS,
            math.floor(number(options.limit) or Observatory.MAX_DECISIONS)
        )
    )
    local arbiterSnapshot = Arbiter and type(Arbiter.Snapshot) == "function"
        and Arbiter.Snapshot(math.max(limit, 16)) or { decisions = {} }
    local decisions = relevantDecisions(
        arbiterSnapshot, npcID, eventRef, limit
    )
    local presentation = latestByStage(decisions, "presentation")
    local gate = latestGate(decisions)
    local moment = options.moment
        or presentation and presentation.moment
        or gate and gate.moment
    moment = Moment and type(Moment.Snapshot) == "function"
        and Moment.Snapshot(moment) or copyRow(moment)
    local responsePlanID = clean(
        options.responsePlanID
            or presentation and presentation.responsePlanID
    )
    local realizationID = clean(
        options.realizationID
            or presentation and presentation.realizationID
    )
    local presentationClass = clean(
        options.presentationClass
            or presentation and presentation.presentationClass
            or moment and moment.presentationClass
    )
    local offers = boundedOffers(responsePlanID, realizationID)
    local encounter = Encounter and type(Encounter.Snapshot) == "function"
        and record and Encounter.Snapshot(record) or nil

    return {
        schema = Observatory.SCHEMA,
        schemaVersion = Observatory.VERSION,
        npcID = npcID,
        eventRef = eventRef
            or presentation and presentation.eventRef
            or gate and gate.eventRef,
        hordeEpisode = hordeEpisode(record),
        encounterIntent = encounter,
        combatMoment = moment,
        arbiter = {
            decisionSequence = arbiterSnapshot.decisionSequence,
            latestGate = copyRow(gate),
            latestPresentation = copyRow(presentation),
            decisions = decisions,
            decisionLimit = limit,
        },
        presentation = {
            class = presentationClass,
            responsePlanID = responsePlanID,
            realizationID = realizationID,
            offerCount = #offers,
            offers = offers,
        },
        weapon = weaponPredicates(moment),
        tacticalSpatial = tacticalProjection(
            presentation, gate, options
        ),
        explanation = explanation(
            gate, presentation, presentationClass, offers
        ),
    }
end

return Observatory
