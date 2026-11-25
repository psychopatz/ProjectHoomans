-- Small deterministic response composer for high-confidence semantic turns.
--
-- This is intentionally a response-layer extension, not parser logic. It
-- reads an observation snapshot and produces a presentation-safe fallback;
-- it does not mutate the world or perform an NPC action.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Response = PNC.ConvoEngine.LocalResponse or {}
PNC.ConvoEngine.LocalResponse = Response

Response.VERSION = 1
Response.Internal = Response.Internal or {}

require "PNC/ConvoEngine/Dialogue/LocalResponse_SelectorContext"

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" then
    local loaded = require
        "PNC/ConvoEngine/Dialogue/ResponseCatalog"
    Catalog = type(loaded) == "table" and loaded or nil
end
local Lexicon = PNC.ConvoEngine.Lexicon
if type(Lexicon) ~= "table" then
    local loaded = require "PNC/ConvoEngine/Lexicon"
    Lexicon = type(loaded) == "table" and loaded or nil
end

local function identityKnown(context)
    context = type(context) == "table" and context or {}
    if context.identityState == "known"
        or context.identityKnown == true
    then
        return true
    end
    local actor = type(context.actorConversationContext) == "table"
        and context.actorConversationContext or {}
    local identity = type(actor.identity) == "table"
        and actor.identity or {}
    if identity.state == "known" then return true end
    local clientState = PNC.Network and PNC.Network.ClientState or nil
    local presentations = clientState and clientState.npcPresentations
        or nil
    local presentation = presentations
        and presentations[tostring(context.npcID or "")] or nil
    return type(presentation) == "table"
        and (presentation.state == "known"
            or presentation.canAskName == false)
end

Response.Internal.IdentityKnown = identityKnown
local ResponsePlan = PNC.ConvoEngine.ResponsePlan
if type(ResponsePlan) ~= "table" then
    local loaded = require
        "PNC/ConvoEngine/Dialogue/ResponsePlan"
    ResponsePlan = type(loaded) == "table" and loaded or nil
end

local function copyArgs(values)
    local output = {}
    if type(values) ~= "table" then return output end
    local key
    local value
    for key, value in pairs(values) do output[key] = value end
    return output
end

local function copyList(values)
    local output = {}
    if type(values) ~= "table" then return output end
    for index = 1, #values do output[index] = values[index] end
    return output
end

local FALLBACK_ARGUMENT_ORDER = {
    "content", "topic", "location", "npcName", "playerName", "activity",
    "kind", "factStatus", "weather", "needType", "hour", "minute",
    "gameDay", "state", "role", "destination", "direction", "eta",
}

local function renderFallback(fallback, args, translationArgs)
    local values = {}
    local index
    local key
    local value
    if type(fallback) ~= "string" or type(args) ~= "table" then
        return fallback
    end
    for index = 1, #FALLBACK_ARGUMENT_ORDER do
        key = FALLBACK_ARGUMENT_ORDER[index]
        value = args[key]
        if value ~= nil then values[index] = tostring(value) end
    end
    if type(translationArgs) == "table" then
        for key, _ in pairs(translationArgs) do
            if type(key) == "string" and args[key] ~= nil then
                for index = 1, #FALLBACK_ARGUMENT_ORDER do
                    if FALLBACK_ARGUMENT_ORDER[index] == key then
                        values[index] = tostring(args[key])
                        break
                    end
                end
            end
        end
    end
    return string.gsub(fallback, "%%([1-9][0-9]*)", function(number)
        local position = tonumber(number)
        return values[position] or "%" .. tostring(number)
    end)
end

local selectorContext = Response.Internal.SelectorContext

local function catalogResponse(poolID, ir, state, context, args)
    if not Catalog or type(Catalog.Select) ~= "function" then return nil end
    local selCtx = selectorContext(ir, state, context)
    local salt = tostring(state and state.sequence or 0) .. ":"
        .. tostring(ir and ir.rawText or "")
    local selected = Catalog.Select(poolID, selCtx, salt)
    if type(selected) ~= "table" then return nil end
    local rawFallback = selected.fallback
    local tid = selected.templateID or selected.id
    if type(tid) == "string" and tid ~= ""
        and PNC and PNC.Translation and type(PNC.Translation.GetKey) == "function"
    then
        local translated = PNC.Translation.GetKey(tid, rawFallback)
        if type(translated) == "string" and translated ~= "" and translated ~= tid then
            rawFallback = translated
        end
    end
    local fallback = renderFallback(
        rawFallback, args, selected.translationArgs
    )
    if type(fallback) == "string" and string.find(fallback, "{", 1, true)
        and Lexicon and type(Lexicon.Expand) == "function"
    then
        fallback = Lexicon.Expand(fallback, selCtx, args, { salt = salt })
    end
    local plan
    if type(selected.plan) == "table"
        and ResponsePlan and type(ResponsePlan.Build) == "function"
    then
        local valid, normalized = ResponsePlan.Build(selected.plan)
        if valid then plan = normalized end
    end
    return {
        templateID = selected.templateID or selected.id,
        fallback = fallback,
        args = copyArgs(args),
        sourcePoolID = poolID,
        plan = plan,
        dialogueAct = selected.dialogueAct,
        topic = selected.topic,
        groundedFactRefs = copyList(selected.groundedFactRefs),
        uncertainty = selected.uncertainty,
        tone = selected.tone,
        personalityStyle = selected.personalityStyle,
        translationArgs = copyArgs(selected.translationArgs),
        selectionSource = "catalog",
        selectionID = selected.id,
    }
end

local Internal = Response.Internal
Internal.CopyArgs = copyArgs
Internal.CopyList = copyList
Internal.RenderFallback = renderFallback
Internal.CatalogResponse = catalogResponse
Internal.ResponsePlan = ResponsePlan

return Response
