-- Canonical semantic-to-realization boundary.
--
-- A caller resolves meaning through ResponseCatalog before it reaches any
-- Flavor/SocialFlavor renderer.  Renderers may translate, format, queue, or
-- speak the returned plan, but they must not choose a response family.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Authority = PNC.Semantics.RealizationAuthority or {}
PNC.Semantics.RealizationAuthority = Authority

local Catalog = PNC.Semantics.ResponseCatalog
    or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
local ResponsePlan = PNC.Semantics.ResponsePlan
    or require "PNC/Semantics/PNC_SemanticDialogueResponsePlan"

Authority.VERSION = 1
Authority.SCHEMA = "semantic.dialogue.realization.v1"
Authority.SELECTION_SOURCE = "semantic_response_catalog"
Authority.MAX_FACT_REFS = 8

local function clean(value, limit)
    if value == nil then return nil end
    value = tostring(value)
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    return string.sub(value, 1, limit or 128)
end

local function copyList(value, limit)
    local output = {}
    local seen = {}
    if type(value) ~= "table" then return output end
    for index = 1, math.min(#value, limit or Authority.MAX_FACT_REFS) do
        local item = clean(value[index], 128)
        if item and not seen[item] then
            seen[item] = true
            output[#output + 1] = item
        end
    end
    return output
end

local function responsePlan(selected, act, poolID)
    if type(selected) ~= "table" then return nil, "response_invalid" end
    if type(selected.plan) == "table"
        and ResponsePlan.Validate(selected.plan)
    then
        return selected.plan
    end
    return ResponsePlan.FromResponse(selected, act or "REPLY", poolID)
end

function Authority.Resolve(spec)
    spec = type(spec) == "table" and spec or {}
    local poolID = clean(
        spec.poolID or spec.responsePlanID or spec.realizationFamily,
        128
    )
    local act = clean(spec.act or spec.dialogueAct or "REPLY", 48)
    local topic = clean(spec.topic, 96)
    local context = type(spec.context) == "table" and spec.context or {}
    local selected
    local reason
    local plan
    local planReason
    if not poolID then return nil, "realization_pool_required" end
    if not Catalog or type(Catalog.Select) ~= "function" then
        return nil, "response_catalog_unavailable"
    end
    selected, reason = Catalog.Select(
        poolID,
        context,
        spec.salt or spec.seed or spec.eventID or spec.npcID
    )
    if not selected then return nil, reason or "response_unavailable" end
    plan, planReason = responsePlan(selected, act, poolID)
    if not plan then return nil, planReason or "response_plan_unavailable" end
    return {
        schema = Authority.SCHEMA,
        schemaVersion = Authority.VERSION,
        semanticAct = act,
        topic = topic or selected.topic,
        responsePlanID = clean(spec.responsePlanID or poolID, 128),
        responsePlan = plan,
        realizationFamily = clean(
            spec.realizationFamily or poolID,
            128
        ),
        realizationID = clean(selected.id, 128),
        templateID = clean(selected.templateID, 128),
        fallback = clean(selected.fallback, 256),
        compatibilityFlavorID = clean(
            selected.compatibilityFlavorID,
            128
        ),
        groundedFactRefs = copyList(
            spec.groundedFactRefs or selected.groundedFactRefs
        ),
        uncertainty = selected.uncertainty,
        tone = selected.tone,
        personalityStyle = selected.personalityStyle,
        translationArgs = selected.translationArgs,
        selectionSource = Authority.SELECTION_SOURCE,
    }
end

function Authority.AttachProvenance(input, realization)
    if type(input) ~= "table" or type(realization) ~= "table" then
        return input
    end
    input.provenance = type(input.provenance) == "table"
        and input.provenance or {}
    input.provenance.responsePlanID = realization.responsePlanID
    input.provenance.realizationFamily = realization.realizationFamily
    input.provenance.realizationID = realization.realizationID
    input.provenance.factRefs = realization.groundedFactRefs
    input.responsePlanID = realization.responsePlanID
    input.realizationFamily = realization.realizationFamily
    input.realizationID = realization.realizationID
    input.factRefs = realization.groundedFactRefs
    return input
end

return Authority
