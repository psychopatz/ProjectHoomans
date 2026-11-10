-- Bounded interaction-structure authoring seam over production semantic registries.
-- Python/Tk presents data only; validation, registration and draft preview
-- are owned by the same Lua contracts used by production interaction.
local InteractionEditor = {}

local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Director = require "PNC/Semantics/PNC_SemanticInteractionDirector"

local function catalog(context)
    local Values = context.Values
    local behaviors = {}
    for _, id in ipairs(Catalog.Behaviors.List()) do
        local value = Catalog.Behaviors.Get(id)
        if type(value) == "table" then
            behaviors[#behaviors + 1] = Values.copy(value)
        end
    end
    local beats = {}
    for _, id in ipairs(Catalog.Beats.List()) do
        local value = Catalog.Beats.Get(id)
        if type(value) == "table" then
            beats[#beats + 1] = Values.copy(value)
        end
    end
    return {
        ok = true,
        type = "beat_catalog",
        schemaVersion = 1,
        beatRegistryRevision = Catalog.Beats.GetRevision(),
        behaviorRegistryRevision = Catalog.Behaviors.GetRevision(),
        beatCount = #beats,
        behaviorCount = #behaviors,
        beats = beats,
        behaviors = behaviors,
    }
end

function InteractionEditor.catalog(context)
    return catalog(context)
end

function InteractionEditor.validateBeat(context, definition)
    local valid, normalized = Catalog.Beats.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "beat_validation",
            schemaVersion = 1,
            valid = false,
            reason = tostring(normalized),
        }
    end
    return {
        ok = true,
        type = "beat_validation",
        schemaVersion = 1,
        valid = true,
        definition = context.Values.copy(normalized),
    }
end

function InteractionEditor.validateBehavior(context, definition)
    local valid, normalized = Catalog.Behaviors.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "behavior_validation",
            schemaVersion = 1,
            valid = false,
            reason = tostring(normalized),
        }
    end
    return {
        ok = true,
        type = "behavior_validation",
        schemaVersion = 1,
        valid = true,
        definition = context.Values.copy(normalized),
    }
end

function InteractionEditor.registerBeat(context, definition)
    local valid, normalized = Catalog.Beats.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "beat_registration",
            schemaVersion = 1,
            valid = false,
            registered = false,
            reason = tostring(normalized),
        }
    end
    local registered, result = Catalog.Beats.RegisterDraft(definition)
    if not registered then
        return {
            ok = true,
            type = "beat_registration",
            schemaVersion = 1,
            valid = true,
            registered = false,
            reason = tostring(result),
        }
    end
    local output = catalog(context)
    output.type = "beat_registration"
    output.valid = true
    output.registered = true
    output.definition = context.Values.copy(result)
    return output
end

function InteractionEditor.registerBehavior(context, definition)
    local valid, normalized = Catalog.Behaviors.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "behavior_registration",
            schemaVersion = 1,
            valid = false,
            registered = false,
            reason = tostring(normalized),
        }
    end
    local registered, result = Catalog.Behaviors.RegisterDraft(definition)
    if not registered then
        return {
            ok = true,
            type = "behavior_registration",
            schemaVersion = 1,
            valid = true,
            registered = false,
            reason = tostring(result),
        }
    end
    local output = catalog(context)
    output.type = "behavior_registration"
    output.valid = true
    output.registered = true
    output.definition = context.Values.copy(result)
    return output
end

function InteractionEditor.previewInteraction(context, stimulus)
    if type(stimulus) ~= "table" then
        return {
            ok = false,
            type = "interaction_preview",
            schemaVersion = 1,
            error = "interaction_stimulus_must_be_object",
        }
    end
    local view = context.Runtime.view
    local session = view and view.session
    local state = session and session.semanticDialogueState
    local router = session and session.semanticDialogueRouter
    local projection = router and router.context
        or view and view.spec and view.spec.context
        or {}
    local preview, reason = Director.PreviewStimulus(
        stimulus, state, projection
    )
    if not preview then
        return {
            ok = true,
            type = "interaction_preview",
            schemaVersion = 1,
            previewed = false,
            reason = tostring(reason),
            mutatedConversation = false,
        }
    end
    return {
        ok = true,
        type = "interaction_preview",
        schemaVersion = 1,
        previewed = true,
        preview = context.Values.copy(preview),
        mutatedConversation = false,
    }
end

function InteractionEditor.previewBeat(context, request)
    request = type(request) == "table" and request or {}
    local definition = request.definition
    local text = tostring(request.text or "")
    if type(definition) ~= "table" then
        return {
            ok = false,
            type = "beat_preview",
            schemaVersion = 1,
            error = "beat_definition_must_be_object",
        }
    end
    if text == "" or #text > 512 then
        return {
            ok = false,
            type = "beat_preview",
            schemaVersion = 1,
            error = "preview_text_invalid",
        }
    end
    local valid, normalized = Catalog.Beats.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "beat_preview",
            schemaVersion = 1,
            valid = false,
            previewed = false,
            reason = tostring(normalized),
        }
    end

    -- Run the ordinary production parser/policy preview first. This does not
    -- record a turn or dispatch an action. The draft beat is then evaluated
    -- against the exact router context produced by that preview.
    local production = context.Conversation.preview(context, text)
    local result = type(production.result) == "table" and production.result or {}
    local ir = type(result.ir) == "table" and result.ir or nil
    if not ir then
        return {
            ok = true,
            type = "beat_preview",
            schemaVersion = 1,
            valid = true,
            previewed = false,
            reason = production.reason or "semantic_ir_unavailable",
            production = production.observation,
        }
    end

    local view = context.Runtime.view
    local session = view and view.session
    local state = session and session.semanticDialogueState
    local router = session and session.semanticDialogueRouter
    local projection = router and router.context
        or view and view.spec and view.spec.context
        or {}
    local draft, reason = Director.PreviewBeatDefinition(
        normalized,
        ir,
        state,
        projection
    )
    if not draft then
        return {
            ok = true,
            type = "beat_preview",
            schemaVersion = 1,
            valid = true,
            previewed = false,
            reason = tostring(reason),
            production = production.observation,
        }
    end
    return {
        ok = true,
        type = "beat_preview",
        schemaVersion = 1,
        valid = true,
        previewed = true,
        input = text,
        definition = context.Values.copy(normalized),
        draft = context.Values.copy(draft),
        production = context.Values.copy(production.observation),
        mutatedConversation = false,
        registered = false,
    }
end

return InteractionEditor
