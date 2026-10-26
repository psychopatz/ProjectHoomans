-- Conversation-owned semantic runtime façade.
--
-- Conversation owns the integration contract while PNC.Semantics continues
-- to own the reusable semantic mechanisms.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Semantics = PNC.Semantics or {}

local Conversation = PNC.Conversation
local Semantics = PNC.Semantics
local Runtime = Conversation.Semantic or {}

Conversation.Semantic = Runtime

local groupCoordinator

local function ensureDependencies()
    if type(Semantics.DialogueInput) ~= "table" then
        local loaded, loadError = pcall(require,
            "PNC/Semantics/PNC_SemanticDialogueInput")
        if not loaded or type(Semantics.DialogueInput) ~= "table" then
            return false, loadError or "dialogue_input_unavailable"
        end
    end
    if type(Semantics.WorldContext) ~= "table" then
        pcall(require, "PNC/Semantics/PNC_SemanticWorldContext")
    end
    return true
end

local function inputAvailable()
    local input = Semantics.DialogueInput
    if type(input) ~= "table" then return false end
    if type(input.IsAvailable) == "function" then
        return input.IsAvailable() == true
    end
    return type(input.CreatePart) == "function"
end

function Runtime.HasDialogueInput()
    local loaded = ensureDependencies()
    return loaded and inputAvailable() or false
end

function Runtime.CreateInput(bounds, options)
    if not Runtime.HasDialogueInput() then return nil end
    return Semantics.DialogueInput.CreatePart(bounds, options)
end

function Runtime.Register(conversation, group, time)
    local loaded = ensureDependencies()
    if not loaded or not inputAvailable() then
        return false, "dialogue_input_unavailable"
    end
    if type(conversation) ~= "table" then
        return false, "conversation_unavailable"
    end

    conversation.CreateSemanticDialogueInput = Runtime.CreateInput
    if type(group) == "table" and type(group.Create) == "function" then
        groupCoordinator = group
    end

    local worldContext = Semantics.WorldContext
    if worldContext and type(worldContext.SetTimeBandResolver) == "function"
        and type(time) == "table" and type(time.Resolve) == "function"
    then
        worldContext.SetTimeBandResolver(time.Resolve)
    end
    return groupCoordinator ~= nil
end

local function copyOptions(options)
    local copy = {}
    if type(options) == "table" then
        for key, value in pairs(options) do copy[key] = value end
    end
    return copy
end

function Runtime.CreateGroup(primaryHost, hosts, entries, player, options)
    if not groupCoordinator then
        return nil, "group_coordinator_unavailable"
    end
    local groupOptions = copyOptions(options)
    groupOptions.dialogueInput = Semantics.DialogueInput
    groupOptions.semanticDiagnostics = Semantics.SemanticDiagnostics
    groupOptions.entityResolver = Semantics.EntityResolver
    return groupCoordinator.Create(
        primaryHost, hosts, entries, player, groupOptions)
end

return Runtime
