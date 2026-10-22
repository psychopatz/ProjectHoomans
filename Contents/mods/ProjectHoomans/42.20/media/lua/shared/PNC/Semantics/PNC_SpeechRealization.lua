-- Shared SpeechRealization registry, resolver, and fallback boundary.
--
-- Built-in phrase content lives in cohesive domain packs. This file owns the
-- one registry and the one application path used by semantic responses.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Realization = PNC.Semantics.SpeechRealization or {}
PNC.Semantics.SpeechRealization = Realization

Realization.VERSION = 1
Realization.MAX_FAMILY_APPLICATIONS = 8

local Style = PNC.Semantics.SpeechStyleContext
    or require "PNC/Semantics/PNC_SpeechStyleContext"
local FAMILIES = {}

local function mergePack(pack)
    if type(pack) ~= "table" then return end
    for templateID, family in pairs(pack) do
        FAMILIES[templateID] = family
    end
end

mergePack(require "PNC/Semantics/SpeechRealization/Families/Status")
mergePack(require "PNC/Semantics/SpeechRealization/Families/Social")
mergePack(require "PNC/Semantics/SpeechRealization/Families/Knowledge")
mergePack(require "PNC/Semantics/SpeechRealization/Families/Actions")

local COVERAGE = {
    { family = "greeting", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "wellbeing", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "needs", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "medical", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "identity", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "knowledge", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "acknowledgement", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "apology", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "offer_help", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "dispute_refusal", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "threat_hostility", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "gossip_event", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "companion_action", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "trading_entry", supported = { "neutral", "warm", "terse", "guarded" } },
    { family = "quest_commitment", supported = { "neutral", "warm", "terse", "guarded" } },
}

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 12 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 128 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

function Realization.Register(templateID, family)
    templateID = tostring(templateID or "")
    if templateID == "" or type(family) ~= "table" then
        return false, "realization_family_invalid"
    end
    FAMILIES[templateID] = copy(family)
    return true, templateID
end

function Realization.Families()
    return copy(FAMILIES)
end

function Realization.Coverage()
    return copy(COVERAGE)
end

local function relationshipArgument(style, argument)
    if argument ~= "familyAddress" then return nil end
    local bond = type(style) == "table" and style.bond or nil
    local term = type(bond) == "table" and bond.term or nil
    local translation = PNC.Translation
    if type(term) == "table" and term.addressKey
        and translation and type(translation.GetKey) == "function"
    then
        local value = translation.GetKey(
            term.addressKey, tostring(bond.kind or "family")
        )
        if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    return term and tostring(bond.kind or "") or nil
end

function Realization.Resolve(templateID, style, semanticFallback)
    local family = FAMILIES[tostring(templateID or "")]
    if not family then return nil, "realization_family_unavailable" end
    style = type(style) == "table" and style or {}
    local selectedFamily = family
    local bond = type(style.bond) == "table" and style.bond or nil
    local bondFamily = bond and family.bond and family.bond.any or nil
    if type(bondFamily) == "table" and tostring(bond.class or "") ~= "" then
        selectedFamily = bondFamily
    end
    local selected = tostring(style.variant or "neutral")
    local value = selectedFamily[selected]
    local reason
    if type(value) ~= "table" then
        value = selectedFamily.neutral or family.neutral
        reason = "neutral_fallback"
    end
    if type(value) ~= "table" then
        return nil, "realization_neutral_unavailable"
    end
    if selected == "neutral" and not value.forceKey then
        return {
            templateID = tostring(templateID),
            fallback = tostring(semanticFallback or value.fallback or ""),
            family = tostring(templateID),
            variant = "neutral",
            fallbackReason = nil,
        }
    end
    return {
        templateID = tostring(value.key or templateID),
        fallback = tostring(value.fallback or ""),
        family = tostring(templateID),
        variant = type(selectedFamily[selected]) == "table"
            and selected or "neutral",
        fallbackReason = reason,
        argument = value.argument,
    }
end

local function applySegment(segment, style, blocked)
    if type(segment) ~= "table" or segment.kind ~= "translation" then
        return segment, nil
    end
    if type(blocked) == "table" and blocked[segment.templateID] then
        return segment, nil
    end
    local resolved = Realization.Resolve(
        segment.templateID, style, segment.fallback
    )
    if not resolved then return segment, nil end
    local output = copy(segment)
    output.args = copy(segment.args or {})
    output.semanticTemplateID = segment.templateID
    output.templateID = resolved.templateID
    output.fallback = resolved.fallback
    output.realizationFamily = resolved.family
    output.realizationVariant = resolved.variant
    output.realizationFallbackReason = resolved.fallbackReason
    if resolved.argument then
        output.args[resolved.argument] = relationshipArgument(style, resolved.argument)
    end
    return output, resolved
end

function Realization.Apply(response, context)
    if type(response) ~= "table" then return response end
    local style = Style.Resolve(context)
    local output = copy(response)
    local applications = 0
    local fallbackCount = 0
    local first
    local resolved
    local segment
    local turn
    local blocked = {}

    if response.selectionID == "semantic.refuse.default" then
        blocked["semantic.social.acknowledged"] = true
    end

    output.speechStyleContext = Style.PublicView(style)
    if type(output.plan) == "table" and type(output.plan.turns) == "table" then
        for index = 1, math.min(#output.plan.turns, 4) do
            turn = output.plan.turns[index]
            for segmentIndex = 1, math.min(#(turn.segments or {}), 6) do
                segment, resolved = applySegment(
                    turn.segments[segmentIndex], style, blocked
                )
                turn.segments[segmentIndex] = segment
                if resolved then
                    applications = applications + 1
                    first = first or resolved
                    if resolved.fallbackReason then fallbackCount = fallbackCount + 1 end
                end
            end
        end
    end
    segment, resolved = applySegment({
        kind = "translation",
        templateID = output.templateID,
        fallback = output.fallback,
        args = output.args,
    }, style, blocked)
    if resolved then
        output.args = segment.args
        output.semanticTemplateID = output.templateID
        output.renderTemplateID = resolved.templateID
        output.fallback = resolved.fallback
        output.realizationFamily = resolved.family
        output.realizationVariant = resolved.variant
        output.realizationFallbackReason = resolved.fallbackReason
        applications = applications + 1
        first = first or resolved
        if resolved.fallbackReason then fallbackCount = fallbackCount + 1 end
    end
    output.realization = {
        family = first and first.family or nil,
        variant = first and first.variant or style.variant,
        applied = applications > 0,
        applicationCount = applications,
        neutralFallbackCount = fallbackCount,
        maxApplications = Realization.MAX_FAMILY_APPLICATIONS,
    }
    return output
end

return Realization
