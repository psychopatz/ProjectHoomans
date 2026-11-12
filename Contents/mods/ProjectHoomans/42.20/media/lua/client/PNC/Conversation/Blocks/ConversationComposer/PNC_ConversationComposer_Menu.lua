local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = PsychopatzCore.Conversation.Registry
local Selector = Conversation.Selector
local Loader = PsychopatzCore.Conversation.TextCatalog
local Internal = Composer.Internal

local RECRUITMENT_SOURCE = Internal.RecruitmentSource
local conversationDebugEnabled = Internal.ConversationDebugEnabled
local dialoguePayload = Internal.DialoguePayload
local ensureBlockText = Internal.EnsureBlockText
local payload = Internal.Payload
local selectedTextKey = Internal.SelectedTextKey

local RECRUIT_RESPONSE_KEYS = {
    "recruitment.admire.1",
    "recruitment.admire.2",
    "recruitment.admire.3",
    "recruitment.fear.1",
    "recruitment.fear.2",
    "recruitment.fear.3",
    "recruitment.reject.relationship.1",
    "recruitment.reject.relationship.2",
    "recruitment.reject.relationship.3",
    "recruitment.reject.relationship.4",
    "recruitment.reject.relationship.5",
    "recruitment.reject.relationship.6",
    "recruitment.reject.relationship.7",
    "recruitment.reject.relationship.8",
    "recruitment.reject.relationship.9",
    "recruitment.reject.relationship.10",
    "recruitment.reject.leader.1",
    "recruitment.reject.leader.2",
    "recruitment.reject.cooldown.1",
    "recruitment.reject.cooldown.2",
    "recruitment.reject.member.1",
    "recruitment.reject.member.2",
    "recruitment.reject.hostile.1",
    "recruitment.reject.hostile.2",
    "recruitment.reject.unavailable.1",
    "recruitment.reject.unavailable.2",
    "recruitment.reject.general.1",
    "recruitment.reject.general.2",
    "recruitment.reject.general.3",
}

local GOODBYE_SOURCE = {
    modID = "PsychopatzCore",
    pathPattern = "media/translation/{language}/Conversation/Text/social/goodbye/closing.json",
    domain = "pnc.social.goodbye.closing",
}

local function evaluateCategory(context, category)
    local categoryEligible, categoryReason = Selector.IsCategoryEligible(
        category.id, context, false
    )
    local categoryTextValid, categoryTextReason = Loader.ValidateSource(
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


Internal.MenuConversationDebugEnabled = conversationDebugEnabled
Internal.MenuDialoguePayload = dialoguePayload
Internal.MenuPayload = payload
Internal.MenuRecruitmentSource = RECRUITMENT_SOURCE
Internal.MenuRecruitResponseKeys = RECRUIT_RESPONSE_KEYS
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
