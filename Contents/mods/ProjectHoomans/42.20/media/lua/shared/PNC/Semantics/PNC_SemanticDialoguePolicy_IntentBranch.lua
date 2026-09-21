-- Pure intent-to-branch routing. Policy injects its classifiers so this
-- module stays independent of parsing, response composition, and gameplay.
return function(dependencies)
    dependencies = type(dependencies) == "table" and dependencies or {}
    local commandActions = dependencies.commandActions or {}
    local isInventoryQuery = dependencies.isInventoryQuery
    local isIdentityClaim = dependencies.isIdentityClaim
    local isIdentityEvasion = dependencies.isIdentityEvasion
    local SELF_STATE_SUBJECTS = {
        HUNGER = true,
        THIRST = true,
        FATIGUE = true,
        WELLBEING = true,
    }

    local function isSelfStateReport(ir)
        local socialContext = ir and ir.socialContext
        local state = ir and ir.slots and ir.slots.state
        local subject = ir and ir.subject
        return ir and ir.intent == "INFORM"
            and type(socialContext) == "table"
            and socialContext.selfDirected == true
            and socialContext.target == "SELF"
            and SELF_STATE_SUBJECTS[subject] == true
            and type(state) == "table"
            and state.type == subject
            and type(state.value) == "string"
            and state.value ~= ""
    end

    return function(ir, state, context, giftOffer)
        local branch = "SOCIAL_ACKNOWLEDGED"
        local reason = "semantic_acknowledgement"
        -- A pending identity answer is a conversational obligation. Resolve
        -- a name claim or topic evasion before generic intent routes can
        -- consume self-state reports, questions, or other social turns.
        if isIdentityClaim(ir) then
            branch = "IDENTITY_CLAIM_RECEIVED"
            reason = "recognized_self_name_claim"
        elseif isIdentityEvasion(ir, state, context) then
            branch = "IDENTITY_NAME_EVASION"
            reason = "identity_question_evaded"
        elseif ir.intent == "GREET" or ir.speechAct == "GREET" then
            branch = "GREET_ACKNOWLEDGED"
            reason = "recognized_greeting"
        elseif ir.intent == "COMPLIMENT"
            or ir.speechAct == "COMPLIMENT"
        then
            branch = "COMPLIMENT_RECEIVED"
            reason = "recognized_compliment"
        elseif giftOffer then
            if giftOffer.mode == "selection" then
                branch = "GIFT_SELECTION_REQUIRED"
                reason = "gift_item_selection_required"
            else
                branch = "GIFT_OFFER_DISPATCHED"
                reason = "gift_item_query_ready"
            end
        elseif ir.intent == "OFFER" or ir.speechAct == "OFFER" then
            branch = "OFFER_RECEIVED"
            reason = "recognized_offer"
        elseif ir.intent == "REQUEST" then
            if commandActions[ir.action] then
                branch = ir.action == "FETCH"
                    and "REQUEST_ACKNOWLEDGED" or "COMMAND_ACCEPTED"
                if ir.action == "CAMP" then branch = "CAMP_REQUESTED" end
                reason = "recognized_request"
            else
                branch = "ASK_CLARIFICATION"
                reason = "request_without_action"
            end
        elseif ir.intent == "QUESTION" then
            if isInventoryQuery(ir) then
                branch = "INVENTORY_QUERY_RECEIVED"
                reason = "recognized_inventory_query"
            else
                branch = "QUESTION_RECEIVED"
                reason = "recognized_question"
            end
        elseif isSelfStateReport(ir) then
            branch = "SELF_STATE_RECEIVED"
            reason = "recognized_player_self_state"
        elseif ir.intent == "GOSSIP" then
            branch = "GOSSIP_RECEIVED"
            reason = "recognized_gossip"
        elseif ir.intent == "SELF_REFLECTION"
            or ir.speechAct == "SELF_REFLECTION"
        then
            branch = "SELF_REFLECTION_RECEIVED"
            reason = "recognized_self_reflection"
        elseif ir.intent == "INSULT"
            or ir.intent == "HOSTILE_REMARK"
            or ir.speechAct == "INSULT"
            or ir.speechAct == "HOSTILE_REMARK"
        then
            branch = "HOSTILE_REMARK_RECEIVED"
            reason = "recognized_hostile_social_act"
        elseif ir.intent == "THREATEN" or ir.speechAct == "THREATEN" then
            branch = "THREAT_RECEIVED"
            reason = "recognized_threat"
        elseif ir.intent == "THANK"
            or ir.intent == "ACCEPT"
            or ir.intent == "REFUSE"
            or ir.intent == "AGREE"
            or ir.intent == "DISAGREE"
            or ir.intent == "ACKNOWLEDGE"
            or ir.intent == "APOLOGIZE"
        then
            branch = "SOCIAL_ACKNOWLEDGED"
            reason = "recognized_social_act"
        end

        return branch, reason
    end
end
