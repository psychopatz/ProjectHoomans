-- Canonical interaction structural view over Generated/Conversation/Registry.
--
-- Production definitions remain owned by the generated Conversation Registry.
-- This module adds derived lookup indexes and a disposable Lua-process overlay
-- for Semantic Lab drafts; it never copies canonical records into another
-- production registry.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConversationRegistry = require
    "PNC/Semantics/Generated/Conversation/Registry"
local Predicate = require "PNC/Semantics/PNC_SemanticPredicate"

local Catalog = PNC.Semantics.InteractionCatalog or {}
PNC.Semantics.InteractionCatalog = Catalog

Catalog.VERSION = 1
Catalog.MAX_BEHAVIORS = 64
Catalog.MAX_BEATS = 48
Catalog.MAX_MODIFIERS = 16
Catalog.MAX_CANDIDATES = 16
Catalog.Registry = ConversationRegistry

local canonicalBehaviors = {}
local canonicalBehaviorOrder = {}
local canonicalBeats = {}
local canonicalBeatOrder = {}
local behaviorOverlay = {}
local behaviorOverlayOrder = {}
local beatOverlay = {}
local beatOverlayOrder = {}
local canonicalOneShotByStimulus = {}
local overlayOneShotByStimulus = {}
local canonicalBeatByStimulus = {}
local overlayBeatByStimulus = {}
local behaviorRevision = 0
local beatRevision = 0

local function validID(value, prefix)
    prefix = tostring(prefix or "")
    return type(value) == "string"
        and #value > #prefix
        and #value <= 128
        and string.sub(value, 1, #prefix) == prefix
        and string.find(value, "[^%w_%.:%-]") == nil
end

local function validToken(value)
    return type(value) == "string"
        and #value >= 1
        and #value <= 64
        and string.match(value, "^[A-Z][A-Z0-9_]*$") ~= nil
end

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 128 then break end
        output[key] = copy(item, depth + 1)
        count = count + 1
    end
    return output
end

local function getBehavior(id)
    id = tostring(id or "")
    return behaviorOverlay[id] or canonicalBehaviors[id]
end

local function getBeat(id)
    id = tostring(id or "")
    return beatOverlay[id] or canonicalBeats[id]
end

local function combinedList(canonical, overlay)
    local output = {}
    for index = 1, #canonical do output[#output + 1] = canonical[index] end
    for index = 1, #overlay do output[#output + 1] = overlay[index] end
    return output
end

local function indexID(index, stimulus, id)
    if type(stimulus) ~= "string" or stimulus == "" then return end
    local bucket = index[stimulus]
    if type(bucket) ~= "table" then
        bucket = {}
        index[stimulus] = bucket
    end
    bucket[#bucket + 1] = id
end

local function indexedList(canonicalIndex, overlayIndex, stimulus)
    local output = {}
    local canonical = canonicalIndex[tostring(stimulus or "")] or {}
    local overlay = overlayIndex[tostring(stimulus or "")] or {}
    for index = 1, #canonical do output[#output + 1] = canonical[index] end
    for index = 1, #overlay do output[#output + 1] = overlay[index] end
    return output
end

local function normalizeContinuation(value)
    if value == nil then return true, nil end
    if type(value) ~= "table" then
        return false, "behavior_continuation_invalid"
    end
    local mode = tostring(value.mode or "")
    if mode ~= "emit" and mode ~= "wait" and mode ~= "terminate" then
        return false, "behavior_continuation_mode_invalid"
    end
    local target = tostring(
        value.target or (mode == "terminate" and "none" or "source")
    )
    if target ~= "source"
        and target ~= "other"
        and target ~= "none"
    then
        return false, "behavior_continuation_target_invalid"
    end
    if mode == "emit" and target == "none" then
        return false, "behavior_continuation_target_required"
    end
    for _, field in ipairs({ "intent", "speechAct", "expectedResponse" }) do
        if value[field] ~= nil and not validToken(value[field]) then
            return false, "behavior_continuation_" .. field .. "_invalid"
        end
    end
    local normalized = {
        mode = mode,
        target = target,
        inheritFactRefs = value.inheritFactRefs ~= false,
        inheritEventRefs = value.inheritEventRefs ~= false,
    }
    if value.intent ~= nil then normalized.intent = value.intent end
    if value.speechAct ~= nil then normalized.speechAct = value.speechAct end
    if value.expectedResponse ~= nil then
        normalized.expectedResponse = value.expectedResponse
    end
    return true, normalized
end

local function validateBehavior(definition)
    if type(definition) ~= "table" then return false, "behavior_invalid" end
    if not validID(definition.id, "behavior.") then
        return false, "behavior_id_invalid"
    end
    if not validToken(definition.act) then
        return false, "behavior_act_invalid"
    end
    local mode = tostring(definition.mode or "beat")
    if mode ~= "beat" and mode ~= "one_shot" then
        return false, "behavior_mode_invalid"
    end

    local stimuli = definition.stimuli
    if type(stimuli) ~= "table" or #stimuli < 1 or #stimuli > 16 then
        return false, "behavior_stimuli_invalid"
    end
    local normalizedStimuli = {}
    local seenStimuli = {}
    for index = 1, #stimuli do
        local stimulus = stimuli[index]
        if not validToken(stimulus) then
            return false, "behavior_stimulus_invalid"
        end
        if seenStimuli[stimulus] then
            return false, "behavior_stimulus_duplicate:" .. stimulus
        end
        seenStimuli[stimulus] = true
        normalizedStimuli[#normalizedStimuli + 1] = stimulus
    end

    local capabilities = definition.requiredCapabilities or {}
    if type(capabilities) ~= "table" or #capabilities > 8 then
        return false, "behavior_capabilities_invalid"
    end
    local normalizedCapabilities = {}
    local seenCapabilities = {}
    for index = 1, #capabilities do
        local capability = capabilities[index]
        if not validID(capability, "") then
            return false, "behavior_capability_invalid"
        end
        if seenCapabilities[capability] then
            return false, "behavior_capability_duplicate:" .. capability
        end
        seenCapabilities[capability] = true
        normalizedCapabilities[#normalizedCapabilities + 1] = capability
    end

    local outputs = definition.outputs or {}
    if type(outputs) ~= "table" then
        return false, "behavior_outputs_invalid"
    end
    local normalizedOutputs = {}
    if outputs.speech ~= nil then
        local speech = outputs.speech
        if type(speech) ~= "table"
            or not validToken(speech.dialogueAct)
            or not validID(speech.contentTemplateID, "semantic.")
        then
            return false, "behavior_speech_output_invalid"
        end
        if type(ConversationRegistry.PHRASE_FAMILIES) ~= "table"
            or type(
                ConversationRegistry.PHRASE_FAMILIES[
                    speech.contentTemplateID
                ]
            ) ~= "table"
        then
            return false,
                "behavior_content_template_unknown:"
                    .. tostring(speech.contentTemplateID)
        end
        normalizedOutputs.speech = {
            dialogueAct = speech.dialogueAct,
            contentTemplateID = speech.contentTemplateID,
        }
    end
    if outputs.emote ~= nil then
        local emote = outputs.emote
        if type(emote) ~= "table" or not validID(emote.id, "") then
            return false, "behavior_emote_output_invalid"
        end
        normalizedOutputs.emote = { id = emote.id }
    end
    if outputs.flavor ~= nil then
        local flavor = outputs.flavor
        local presentationAct = type(flavor) == "table"
            and tostring(flavor.presentationAct or "AMBIENT_FLAVOR")
            or nil
        if type(flavor) ~= "table"
            or not validToken(presentationAct)
            or not validID(flavor.contentTemplateID, "semantic.")
        then
            return false, "behavior_flavor_output_invalid"
        end
        if type(ConversationRegistry.PHRASE_FAMILIES) ~= "table"
            or type(
                ConversationRegistry.PHRASE_FAMILIES[
                    flavor.contentTemplateID
                ]
            ) ~= "table"
        then
            return false,
                "behavior_flavor_content_unknown:"
                    .. tostring(flavor.contentTemplateID)
        end
        normalizedOutputs.flavor = {
            presentationAct = presentationAct,
            contentTemplateID = flavor.contentTemplateID,
        }
    end
    if outputs.gameplayIntent ~= nil then
        local gameplay = outputs.gameplayIntent
        if type(gameplay) ~= "table" or not validID(gameplay.id, "") then
            return false, "behavior_gameplay_output_invalid"
        end
        normalizedOutputs.gameplayIntent = { id = gameplay.id }
    end
    for key in pairs(outputs) do
        if key ~= "speech" and key ~= "emote"
            and key ~= "flavor" and key ~= "gameplayIntent"
        then
            return false, "behavior_output_unknown:" .. tostring(key)
        end
    end

    if definition.when ~= nil then
        local ok, reason = Predicate.Validate(definition.when)
        if not ok then
            return false, "behavior_when_" .. tostring(reason)
        end
    end
    local base = tonumber(definition.baseRelevance)
    if not base or base < 0 or base > 1 then
        return false, "behavior_relevance_invalid"
    end
    local modifiers = definition.modifiers or {}
    if type(modifiers) ~= "table"
        or #modifiers > Catalog.MAX_MODIFIERS
    then
        return false, "behavior_modifiers_invalid"
    end
    for index = 1, #modifiers do
        local modifier = modifiers[index]
        local delta = type(modifier) == "table"
            and tonumber(modifier.delta) or nil
        if not delta or delta < -1 or delta > 1 then
            return false, "behavior_modifier_delta_invalid"
        end
        local ok, reason = Predicate.Validate(modifier.when)
        if not ok then return false, reason end
    end

    local continuationOK, continuation = normalizeContinuation(
        definition.continuation
    )
    if not continuationOK then return false, continuation end

    local output = copy(definition, 0)
    output.version = tonumber(output.version) or 1
    output.owner = tostring(output.owner or "ProjectHoomans")
    output.act = definition.act
    output.mode = mode
    output.stimuli = normalizedStimuli
    output.requiredCapabilities = normalizedCapabilities
    output.outputs = normalizedOutputs
    output.continuation = continuation
    output.baseRelevance = base
    output.modifiers = copy(modifiers, 0) or {}
    return true, output
end


local function validateBeat(definition)
    if type(definition) ~= "table" then return false, "beat_invalid" end
    if not validID(definition.id, "beat.") then
        return false, "beat_id_invalid"
    end
    local stimuli = definition.stimuli
    if type(stimuli) ~= "table" or #stimuli < 1 or #stimuli > 16 then
        return false, "beat_stimuli_invalid"
    end
    local normalizedStimuli = {}
    local seenStimuli = {}
    for index = 1, #stimuli do
        local stimulus = stimuli[index]
        if not validToken(stimulus) then
            return false, "beat_stimulus_invalid"
        end
        if seenStimuli[stimulus] then
            return false, "beat_stimulus_duplicate:" .. stimulus
        end
        seenStimuli[stimulus] = true
        normalizedStimuli[#normalizedStimuli + 1] = stimulus
    end
    for _, field in ipairs({ "entry", "maintain", "exit" }) do
        local ok, reason = Predicate.Validate(definition[field])
        if not ok then
            return false, "beat_" .. field .. "_" .. tostring(reason)
        end
    end
    local candidates = definition.candidates
    if type(candidates) ~= "table"
        or #candidates < 1
        or #candidates > Catalog.MAX_CANDIDATES
    then
        return false, "beat_candidates_invalid"
    end
    local normalizedCandidates = {}
    local seen = {}
    for index = 1, #candidates do
        local candidate = candidates[index]
        local behaviorID = type(candidate) == "table"
            and candidate.behavior or nil
        local relevance = type(candidate) == "table"
            and tonumber(candidate.relevance) or nil
        local behavior = validID(behaviorID, "behavior.")
            and getBehavior(behaviorID) or nil
        if behavior == nil then
            return false, "beat_behavior_unknown:" .. tostring(behaviorID)
        end
        if behavior.mode ~= "beat" then
            return false, "beat_behavior_mode_invalid:" .. tostring(behaviorID)
        end
        if seen[behaviorID] then
            return false, "beat_behavior_duplicate:" .. behaviorID
        end
        if not relevance or relevance < 0 or relevance > 1 then
            return false, "beat_candidate_relevance_invalid"
        end
        seen[behaviorID] = true
        normalizedCandidates[#normalizedCandidates + 1] = {
            behavior = behaviorID,
            relevance = relevance,
        }
    end
    local base = tonumber(definition.baseRelevance) or 0.5
    local cooldown = tonumber(definition.cooldownTurns) or 0
    local maxTurns = tonumber(definition.maxTurns) or 0
    if base < 0 or base > 1 then return false, "beat_relevance_invalid" end
    if cooldown < 0 or cooldown > 64
        or maxTurns < 0 or maxTurns > 64
    then
        return false, "beat_turn_policy_invalid"
    end
    local output = copy(definition, 0)
    output.version = tonumber(output.version) or 1
    output.owner = tostring(output.owner or "ProjectHoomans")
    output.stimuli = normalizedStimuli
    output.baseRelevance = base
    output.cooldownTurns = cooldown
    output.maxTurns = maxTurns
    output.candidates = normalizedCandidates
    return true, output
end

for index = 1, #(ConversationRegistry.BEHAVIORS or {}) do
    local definition = ConversationRegistry.BEHAVIORS[index]
    local ok, reason = validateBehavior(definition)
    if not ok then
        error(
            "canonical interaction behavior invalid: "
            .. tostring(definition and definition.id)
            .. " (" .. tostring(reason) .. ")"
        )
    end
    if canonicalBehaviors[definition.id] then
        error("duplicate canonical behavior: " .. tostring(definition.id))
    end
    canonicalBehaviors[definition.id] = definition
    canonicalBehaviorOrder[#canonicalBehaviorOrder + 1] = definition.id
    if definition.mode == "one_shot" then
        for stimulusIndex = 1, #(definition.stimuli or {}) do
            indexID(
                canonicalOneShotByStimulus,
                definition.stimuli[stimulusIndex],
                definition.id
            )
        end
    end
end

for index = 1, #(ConversationRegistry.BEATS or {}) do
    local definition = ConversationRegistry.BEATS[index]
    local ok, reason = validateBeat(definition)
    if not ok then
        error(
            "canonical interaction beat invalid: "
            .. tostring(definition and definition.id)
            .. " (" .. tostring(reason) .. ")"
        )
    end
    if canonicalBeats[definition.id] then
        error("duplicate canonical beat: " .. tostring(definition.id))
    end
    canonicalBeats[definition.id] = definition
    canonicalBeatOrder[#canonicalBeatOrder + 1] = definition.id
    for stimulusIndex = 1, #(definition.stimuli or {}) do
        indexID(
            canonicalBeatByStimulus,
            definition.stimuli[stimulusIndex],
            definition.id
        )
    end
end

Catalog.Behaviors = {
    Get = function(id) return getBehavior(id) end,
    List = function()
        return combinedList(canonicalBehaviorOrder, behaviorOverlayOrder)
    end,
    OneShotForStimulus = function(stimulus)
        return indexedList(
            canonicalOneShotByStimulus,
            overlayOneShotByStimulus,
            stimulus
        )
    end,
    Validate = validateBehavior,
    RegisterDraft = function(definition)
        local valid, normalized = validateBehavior(definition)
        if not valid then return false, normalized end
        if getBehavior(normalized.id) ~= nil then
            return false, "duplicate_behavior_id:" .. normalized.id
        end
        if #canonicalBehaviorOrder + #behaviorOverlayOrder
            >= Catalog.MAX_BEHAVIORS
        then
            return false, "behavior_limit"
        end
        behaviorOverlay[normalized.id] = normalized
        behaviorOverlayOrder[#behaviorOverlayOrder + 1] = normalized.id
        if normalized.mode == "one_shot" then
            for stimulusIndex = 1, #(normalized.stimuli or {}) do
                indexID(
                    overlayOneShotByStimulus,
                    normalized.stimuli[stimulusIndex],
                    normalized.id
                )
            end
        end
        behaviorRevision = behaviorRevision + 1
        return true, normalized
    end,
    GetRevision = function() return behaviorRevision end,
}

Catalog.Beats = {
    Get = function(id) return getBeat(id) end,
    List = function()
        return combinedList(canonicalBeatOrder, beatOverlayOrder)
    end,
    ForStimulus = function(stimulus)
        return indexedList(
            canonicalBeatByStimulus,
            overlayBeatByStimulus,
            stimulus
        )
    end,
    Validate = validateBeat,
    RegisterDraft = function(definition)
        local valid, normalized = validateBeat(definition)
        if not valid then return false, normalized end
        if getBeat(normalized.id) ~= nil then
            return false, "duplicate_beat_id:" .. normalized.id
        end
        if #canonicalBeatOrder + #beatOverlayOrder >= Catalog.MAX_BEATS then
            return false, "beat_limit"
        end
        beatOverlay[normalized.id] = normalized
        beatOverlayOrder[#beatOverlayOrder + 1] = normalized.id
        for stimulusIndex = 1, #(normalized.stimuli or {}) do
            indexID(
                overlayBeatByStimulus,
                normalized.stimuli[stimulusIndex],
                normalized.id
            )
        end
        beatRevision = beatRevision + 1
        return true, normalized
    end,
    GetRevision = function() return beatRevision end,
}

function Catalog.ResetDraftOverlay()
    behaviorOverlay = {}
    behaviorOverlayOrder = {}
    beatOverlay = {}
    beatOverlayOrder = {}
    overlayOneShotByStimulus = {}
    overlayBeatByStimulus = {}
    behaviorRevision = behaviorRevision + 1
    beatRevision = beatRevision + 1
end

function Catalog.IndexSnapshot(stimulus)
    stimulus = tostring(stimulus or "")
    local beats = Catalog.Beats.ForStimulus(stimulus)
    local oneShot = Catalog.Behaviors.OneShotForStimulus(stimulus)
    return {
        stimulus = stimulus,
        beatIDs = beats,
        beatCount = #beats,
        oneShotBehaviorIDs = oneShot,
        oneShotBehaviorCount = #oneShot,
        canonicalBeatCount = #canonicalBeatOrder,
        canonicalBehaviorCount = #canonicalBehaviorOrder,
        effectiveBeatCount = #canonicalBeatOrder + #beatOverlayOrder,
        effectiveBehaviorCount =
            #canonicalBehaviorOrder + #behaviorOverlayOrder,
    }
end

function Catalog.OverlaySnapshot()
    return {
        behaviorRevision = behaviorRevision,
        beatRevision = beatRevision,
        behaviorDraftCount = #behaviorOverlayOrder,
        beatDraftCount = #beatOverlayOrder,
    }
end

return Catalog
