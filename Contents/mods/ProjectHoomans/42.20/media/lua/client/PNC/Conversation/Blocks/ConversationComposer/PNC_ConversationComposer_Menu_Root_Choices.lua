-- Client-side conversation root choice composition provider.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Loader = Conversation.TextLoader
local Internal = Composer.Internal
local Choices = {}
local CompanionChoices = Internal.MenuRootCompanionChoices

local SYSTEM_SOURCE = Internal.MenuSystemSource
local conversationDebugEnabled = Internal.MenuConversationDebugEnabled
local dialoguePayload = Internal.MenuDialoguePayload
local payload = Internal.MenuPayload
local RECRUIT_SYSTEM_KEYS = Internal.MenuRecruitSystemKeys or {}
local GOODBYE_SOURCE = Internal.MenuGoodbyeSource

local function categoryChoices(context)
    local choices = {}
    local diagnostics = context.categoryDiagnostics
    if type(diagnostics) ~= "table" then
        diagnostics = Composer.BuildCategoryDiagnostics(context)
        context.categoryDiagnostics = diagnostics
    end
    for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.visible or diagnostic.unavailable then
            local selectedCategory = Registry.GetCategory(diagnostic.id)
            local label = payload(
                selectedCategory.textSource,
                selectedCategory.labelKey
            )
            local choicesEntry = {
                id = selectedCategory.id,
                text = label,
                -- Ask About is a topic browser and stays out of the
                -- transcript; ordinary categories are player lines.
                log = selectedCategory.id
                    ~= "projecthoomans:ask_about",
                action = function()
                    Composer.RequestCategory(context.npcID, selectedCategory.id)
                end,
            }
            if diagnostic.unavailable then
                choicesEntry.enabled = false
                choicesEntry.tooltip = diagnostic.unavailableText
                if diagnostic.unavailableText then
                    choicesEntry.text = label
                        .. " (" .. tostring(diagnostic.unavailableText) .. ")"
                end
            end
            choices[#choices + 1] = choicesEntry
        end
    end
    return choices
end

local function addDebugChoice(choices, context)
    if not conversationDebugEnabled() then return end
    choices[#choices + 1] = {
        id = "show_debug_text",
        text = dialoguePayload(
            SYSTEM_SOURCE, "choice.show_debug_text", context
        ),
        log = false,
        next = "menu",
        action = function()
            local debugUI = PNC.ConversationDebugUI
            if debugUI and type(debugUI.Open) == "function" then
                debugUI.Open(context)
            end
        end,
    }
end

function Choices.Build(context, options, greetingBlock)
    options = type(options) == "table" and options or {}
    local choices = {}
    if context.audiences.hostile then
        local choice = greetingBlock and greetingBlock.nodes.opening
            and greetingBlock.nodes.opening.choices[1] or nil
        if choice then
            choices[#choices + 1] = {
                id = "ceasefire",
                text = dialoguePayload(
                    greetingBlock.textSource, choice.textKey, context
                ),
                action = function()
                    Composer.RequestCategory(
                        context.npcID,
                        "projecthoomans:greetings",
                        choice.id
                    )
                end,
            }
        end
    else
        choices = categoryChoices(context)
        if options.askNameChoice then
            table.insert(choices, 1, options.askNameChoice)
        end
        if options.dossierChoice then choices[#choices + 1] = options.dossierChoice end
        if CompanionChoices then
            CompanionChoices.Append(choices, context)
        end
    end

    local requiredSystemKeys = {
        "status.block_unavailable", "status.choice_rejected",
        "choice.show_debug_text", "choice.settlement_admission",
        "choice.ambient_visit",
    }
    for _, key in ipairs(RECRUIT_SYSTEM_KEYS) do
        requiredSystemKeys[#requiredSystemKeys + 1] = key
    end
    Loader.EnsureSource(SYSTEM_SOURCE, requiredSystemKeys)
    local goodbyeValid = Loader.EnsureSource(GOODBYE_SOURCE, {
        "choice.goodbye", "response.goodbye",
    })
    if goodbyeValid then
        choices[#choices + 1] = {
            id = "goodbye",
            text = dialoguePayload(
                GOODBYE_SOURCE, "choice.goodbye", context
            ),
            response = dialoguePayload(
                GOODBYE_SOURCE, "response.goodbye", context
            ),
            close = true,
            closeReason = "goodbye",
        }
    end
    addDebugChoice(choices, context)
    return choices
end

Internal.MenuRootChoices = Choices

return Choices
