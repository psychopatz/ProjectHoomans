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
    "choice.disband", "choice.disband_confirm", "choice.disband_cancel",
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
    "response.departure.warning", "response.departure.confirmed",
    "response.departure.rejected",
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

    -- A category may declare the optional companion mod it depends on. When
    -- that mod is absent the entry stays in the menu but disabled, so the player
    -- learns why the feature is missing instead of it silently disappearing.
    local unavailable = false
    local unavailableText
    local requiredModID = category.requiresModID
    if type(requiredModID) == "string" and requiredModID ~= "" then
        local compatibility = PNC.Compatibility
        local hasMod = compatibility
            and type(compatibility.HasMod) == "function"
            and compatibility.HasMod(requiredModID)
        if not hasMod then
            unavailable = true
            unavailableText = category.unavailableTextKey
                and payload(category.textSource, category.unavailableTextKey)
                or nil
        end
    end

    local visible = categoryEligible and selected and textValid
        and categoryTextValid or false
    local reason = "visible"
    if unavailable then
        reason = "integration_unavailable"
        visible = false
    elseif not categoryEligible then
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
        -- Disabled-but-shown: the integration is missing, nothing else failed.
        unavailable = unavailable,
        unavailableText = unavailableText,
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


Internal.MenuSystemSource = SYSTEM_SOURCE
Internal.MenuConversationDebugEnabled = conversationDebugEnabled
Internal.MenuDialoguePayload = dialoguePayload
Internal.MenuPayload = payload
Internal.MenuRecruitSystemKeys = RECRUIT_SYSTEM_KEYS
Internal.MenuGoodbyeSource = GOODBYE_SOURCE

require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Menu_Root_Choices_Companion"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Menu_Root_Choices"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Menu_Root"

function Composer.BuildMenuNode(context, options)
    local node = Composer.BuildRootNode(context, options)
    node.npc = nil
    return node
end

return Composer
