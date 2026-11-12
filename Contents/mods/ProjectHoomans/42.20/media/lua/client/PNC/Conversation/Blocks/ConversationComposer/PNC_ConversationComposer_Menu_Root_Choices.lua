-- Client-side conversation root choice composition provider.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = PsychopatzCore.Conversation.Registry
local Loader = PsychopatzCore.Conversation.TextCatalog
local Internal = Composer.Internal
local Choices = {}
local CompanionChoices = Internal.MenuRootCompanionChoices

local conversationDebugEnabled = Internal.MenuConversationDebugEnabled
local dialoguePayload = Internal.MenuDialoguePayload
local payload = Internal.MenuPayload
local RECRUIT_RESPONSE_KEYS = Internal.MenuRecruitResponseKeys or {}
local RECRUITMENT_SOURCE = Internal.MenuRecruitmentSource
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
                semantic = {
                    route = "conversation_category",
                    categoryID = selectedCategory.id,
                    topic = string.gsub(
                        tostring(selectedCategory.id),
                        "^projecthoomans:",
                        ""
                    ),
                    groupID = "topic:" .. string.gsub(
                        tostring(selectedCategory.id),
                        "^projecthoomans:",
                        ""
                    ),
                },
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
            nil, "UI_PsychopatzConversation_Choice_ShowDebugText", context
        ),
        semantic = {
            route = "conversation_root_choice",
            actionID = "show_debug_text",
            groupID = "conversation_utilities",
        },
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
        local opening = greetingBlock and greetingBlock.nodes
            and greetingBlock.nodes.opening or nil
        local choice = opening and opening.choices
            and opening.choices[1] or nil
        if choice then
            choices[#choices + 1] = {
                id = "ceasefire",
                text = dialoguePayload(
                    greetingBlock.textSource, choice.textKey, context
                ),
                semantic = {
                    route = "conversation_category",
                    categoryID = "projecthoomans:greetings",
                    topic = "greeting",
                    choiceID = choice.id,
                    groupID = "topic:greeting",
                },
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

    Loader.EnsureSource(RECRUITMENT_SOURCE, RECRUIT_RESPONSE_KEYS)
    local goodbyeValid = Loader.EnsureSource(GOODBYE_SOURCE, {
        "choice.goodbye", "response.goodbye",
    })
    if goodbyeValid then
        local goodbyeKey = "response.goodbye"
        local salt = context and (context.phraseSalt or context.caseID or context.utterancePlanSalt)
        if salt then
            local saltHash = 0
            local saltStr = tostring(salt)
            for i = 1, #saltStr do
                saltHash = (saltHash * 31 + string.byte(saltStr, i)) % 2147483647
            end
            goodbyeKey = "response.goodbye." .. tostring((saltHash % 10) + 1)
        end
        choices[#choices + 1] = {
            id = "goodbye",
            text = dialoguePayload(
                GOODBYE_SOURCE, "choice.goodbye", context
            ),
            semantic = {
                route = "conversation_root_choice",
                actionID = "goodbye",
                groupID = "conversation_utilities",
            },
            response = dialoguePayload(
                GOODBYE_SOURCE, goodbyeKey, context
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
