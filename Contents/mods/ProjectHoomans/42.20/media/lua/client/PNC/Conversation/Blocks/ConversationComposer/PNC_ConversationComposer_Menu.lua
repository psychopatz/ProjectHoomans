local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Selector = Conversation.Selector
local Loader = Conversation.TextLoader
local Relationship = Conversation.Relationship
local Internal = Composer.Internal

local SYSTEM_SOURCE = Internal.SYSTEM_SOURCE
local conversationDebugEnabled = Internal.ConversationDebugEnabled
local dialoguePayload = Internal.DialoguePayload
local ensureBlockText = Internal.EnsureBlockText
local payload = Internal.Payload
local selectedTextKey = Internal.SelectedTextKey

local RECRUIT_SYSTEM_KEYS = {
    "choice.recruit",
    "response.recruit.admire.1",
    "response.recruit.admire.2",
    "response.recruit.admire.3",
    "response.recruit.fear.1",
    "response.recruit.fear.2",
    "response.recruit.fear.3",
    "response.recruit.reject.relationship.1",
    "response.recruit.reject.relationship.2",
    "response.recruit.reject.relationship.3",
    "response.recruit.reject.leader.1",
    "response.recruit.reject.leader.2",
    "response.recruit.reject.cooldown.1",
    "response.recruit.reject.cooldown.2",
    "response.recruit.reject.general.1",
    "response.recruit.reject.general.2",
    "response.recruit.reject.general.3",
}

local GOODBYE_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/goodbye/shared/{language}/goodbye.json",
    domain = "pnc.goodbye.shared.goodbye",
}

local function categoryChoices(context)
    local choices = {}
    for _, category in ipairs(Registry.ListCategories()) do
        local categoryEligible = Selector.IsCategoryEligible(
            category.id, context, false
        )
        local categoryTextValid = Loader.EnsureSource(
            category.textSource,
            { category.labelKey }
        )
        local selected = Selector.SelectBlock(category.id, context)
        local textValid = selected and ensureBlockText(selected)
        if categoryEligible and selected and textValid and categoryTextValid then
            local selectedCategory = category
            choices[#choices + 1] = {
                id = selectedCategory.id,
                text = payload(
                    selectedCategory.textSource,
                    selectedCategory.labelKey
                ),
                -- Ask About is a topic browser and stays out of the
                -- transcript; ordinary categories are player lines so
                -- the NPC never appears to start a one-sided exchange.
                log = selectedCategory.id
                    ~= "projecthoomans:ask_about",
                action = function()
                    Composer.RequestCategory(context.npcID, selectedCategory.id)
                end,
            }
        end
    end
    return choices
end

local function addDebugChoice(choices, context)
    if not conversationDebugEnabled() then return end
    choices[#choices + 1] = {
        id = "show_debug_text",
        text = dialoguePayload(
            SYSTEM_SOURCE,
            "choice.show_debug_text",
            context
        ),
        log = false,
        -- Return to the current category menu after the debugger is closed.
        next = "menu",
        action = function()
            local debugUI = PNC.ConversationDebugUI
            if debugUI and type(debugUI.Open) == "function" then
                debugUI.Open(context)
            end
        end,
    }
end

function Composer.BuildGreeting(context)
    local categoryEligible = Selector.IsCategoryEligible(
        "projecthoomans:greetings", context, true
    )
    if not categoryEligible then return nil, "greeting_category_unavailable" end
    local block = Selector.SelectBlock("projecthoomans:greetings", context)
    if not block then return nil, "no_greeting" end
    local valid, reason = ensureBlockText(block)
    if not valid then return nil, reason end
    local node = block.nodes[block.entryNode]
    return dialoguePayload(
        block.textSource,
        selectedTextKey(block, block.entryNode, node, context),
        context
    ), block
end

function Composer.BuildRootNode(context, options)
    options = type(options) == "table" and options or {}
    local greeting, greetingBlock = Composer.BuildGreeting(context)
    local choices = {}
    if context.audiences.hostile then
        local choice = greetingBlock and greetingBlock.nodes.opening
            and greetingBlock.nodes.opening.choices[1] or nil
        if choice then
            choices[#choices + 1] = {
                id = "ceasefire",
                text = dialoguePayload(
                    greetingBlock.textSource,
                    choice.textKey,
                    context
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
        local record = context.npcRecord or {}
        local verifier = PNC.Identity and PNC.Identity.Verifier or nil
        local ownership = verifier
            and verifier.BuildOwnershipSummary
            and verifier.BuildOwnershipSummary(context.entry)
            or nil
        local recruited = ownership
            and (ownership.recruited or ownership.colonyOwned)
            or record.recruited == true
        if not recruited
        then
            choices[#choices + 1] = {
                id = "recruit",
                text = dialoguePayload(
                    SYSTEM_SOURCE, "choice.recruit", context
                ),
                action = function()
                    if Relationship and Relationship.SetPreviewRequirement then
                        Relationship.SetPreviewRequirement(
                            context.npcID,
                            "recruit"
                        )
                    end
                    Composer.RequestRecruit(context.npcID)
                end,
            }
        end
    end
    local requiredSystemKeys = {
        "status.block_unavailable", "status.choice_rejected",
        "choice.show_debug_text",
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
    return { npc = greeting, choices = choices }
end

function Composer.BuildMenuNode(context, options)
    local node = Composer.BuildRootNode(context, options)
    node.npc = nil
    return node
end

return Composer
