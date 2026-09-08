local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Selector = Conversation.Selector
local Loader = Conversation.TextLoader
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

local function evaluateCategory(context, category)
    local categoryEligible, categoryReason = Selector.IsCategoryEligible(
        category.id, context, false
    )
    local categoryTextValid, categoryTextReason = Loader.EnsureSource(
        category.textSource,
        { category.labelKey }
    )
    local selected, selection = Selector.SelectBlock(category.id, context)
    local textValid
    local textReason
    if selected then
        textValid, textReason = ensureBlockText(selected)
    end

    local visible = categoryEligible and selected and textValid
        and categoryTextValid or false
    local reason = "visible"
    if not categoryEligible then
        reason = categoryReason or "category_ineligible"
    elseif not categoryTextValid then
        reason = categoryTextReason or "category_text_invalid"
    elseif not selected then
        reason = "no_eligible_block"
        for _, candidate in ipairs(selection and selection.candidates or {}) do
            if candidate.reason then
                reason = candidate.reason
                break
            end
        end
    elseif not textValid then
        reason = textReason or "block_text_invalid"
    end

    return {
        category = category,
        categoryEligible = categoryEligible == true,
        categoryReason = categoryReason,
        selected = selected,
        selection = selection,
        textValid = textValid == true,
        categoryTextValid = categoryTextValid == true,
        visible = visible == true,
        reason = reason,
    }
end

function Composer.BuildCategoryDiagnostics(context)
    local diagnostics = {}
    for _, category in ipairs(Registry.ListCategories()) do
        local result = evaluateCategory(context, category)
        local candidates = result.selection
            and result.selection.candidates or {}
        diagnostics[#diagnostics + 1] = {
            id = category.id,
            labelKey = category.labelKey,
            visible = result.visible,
            reason = result.reason,
            categoryEligible = result.categoryEligible,
            categoryReason = result.categoryReason,
            categoryTextValid = result.categoryTextValid,
            selectedBlockID = result.selected and result.selected.id or nil,
            blockEligibleCount = result.selection
                and result.selection.eligibleCount or 0,
            candidates = candidates,
        }
    end
    return diagnostics
end

local function categoryChoices(context)
    local choices = {}
    local diagnostics = context.categoryDiagnostics
    if type(diagnostics) ~= "table" then
        diagnostics = Composer.BuildCategoryDiagnostics(context)
        context.categoryDiagnostics = diagnostics
    end
    for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.visible then
            local selectedCategory = Registry.GetCategory(diagnostic.id)
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
    context.categoryDiagnostics = Composer.BuildCategoryDiagnostics(context)
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
            local function setRecruitPreview(highlighted)
                local relationship = Conversation.Relationship
                    or PNC.Conversation.Relationship
                if relationship and relationship.SetPreviewRequirement then
                    local ok, reason = relationship.SetPreviewRequirement(
                        context.npcID,
                        highlighted and "recruit" or "inspect"
                    )
                    if not ok and PNC.Core and PNC.Core.LogWarn then
                        PNC.Core.LogWarn(
                            "Conversation relationship preview unavailable npc="
                                .. tostring(context.npcID or "")
                                .. " reason=" .. tostring(reason or "unknown")
                        )
                    end
                end
            end
            choices[#choices + 1] = {
                id = "recruit",
                text = dialoguePayload(
                    SYSTEM_SOURCE, "choice.recruit", context
                ),
                onHighlightChanged = function(_, highlighted)
                    setRecruitPreview(highlighted)
                end,
                action = function()
                    setRecruitPreview(true)
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
