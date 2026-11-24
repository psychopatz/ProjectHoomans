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
    local block = nil
    local categoryEligible = Selector.IsCategoryEligible(
        "projecthoomans:greetings", context, true
    )
    if categoryEligible then
        block = Selector.SelectBlock("projecthoomans:greetings", context)
        if block then
            local valid = ensureBlockText(block)
            if not valid then block = nil end
        end
    end
    local ok, ctrl = pcall(require, "PNC/ConvoEngine/Dialogue/ConversationSwitchAndFarewell")
    local switchCtrl = (ok and type(ctrl) == "table" and ctrl)
        or (PNC.ConvoEngine and PNC.ConvoEngine.ConversationSwitchAndFarewell)
    if type(switchCtrl) == "table" and type(switchCtrl.ResolveOpeningLine) == "function" then
        local entry = context and context.entry or nil
        local actor = type(entry) == "table" and entry or {
            id = context and context.npcID,
            name = context and context.npcName,
            npcType = context and context.npcType,
        }
        local resolvedTimeBand = context and (context.time or context.conversationTimeID or context.timeID) or nil
        if not resolvedTimeBand and context and tonumber(context.hour) ~= nil then
            local h = tonumber(context.hour) % 24
            if h >= 5 and h < 8 then resolvedTimeBand = "dawn"
            elseif h >= 8 and h < 17 then resolvedTimeBand = "day"
            elseif h >= 17 and h < 20 then resolvedTimeBand = "dusk"
            else resolvedTimeBand = "night" end
        end
        local baseCtx = {
            actorRole = context and (context.npcType or (context.audiences and context.audiences.hostile and "bandit")) or nil,
            relationshipState = context and (context.relationshipID or context.conversationRelationshipID or context.relationship) or nil,
            timeBand = resolvedTimeBand,
        }
        local salt = tostring(context and (context.phraseSalt or context.npcID) or "greet")
            .. ":" .. tostring(context and (context.timeID or "") or "")
        local dynamicLine = switchCtrl.ResolveOpeningLine(nil, actor, nil, baseCtx, salt)
        if type(dynamicLine) == "string" and dynamicLine ~= "" then
            return { fallback = dynamicLine, text = dynamicLine }, block
        end
    end
    if not categoryEligible then return nil, "greeting_category_unavailable" end
    if not block then return nil, "no_greeting" end
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
