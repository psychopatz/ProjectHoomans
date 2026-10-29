-- Ephemeral generated-affordance recurrence policy.
--
-- This policy never rejects typed NLU. It only keeps the generated button
-- frontier from proposing the same conversational move in a tight loop.
local Responder = require
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticAffordanceResponder"

local Policy = {}

Policy.DEFAULT_COOLDOWN_RESPONDER_TURNS = 1
-- Compatibility alias for older tests/callers.
Policy.DEFAULT_COOLDOWN_PLAYER_TURNS =
    Policy.DEFAULT_COOLDOWN_RESPONDER_TURNS
Policy.RULES = {
    DOUBLE_DOWN = { cooldownResponderTurns = 2 },
    CLAIM_JOKE = { cooldownResponderTurns = 2 },
    CHALLENGE = { cooldownResponderTurns = 1 },
    CALL_BLUFF = { cooldownResponderTurns = 2 },
    DISMISS = { cooldownResponderTurns = 1 },
    ASK_WHY = { cooldownResponderTurns = 1 },
    ASK_FOLLOWUP = { cooldownResponderTurns = 1 },
    APOLOGIZE = { cooldownResponderTurns = 1 },
    DEESCALATE = { cooldownResponderTurns = 1 },
}

local function recentTurns(context)
    context = type(context) == "table" and context or {}
    if type(context.affordanceRecentTurns) == "table" then
        return context.affordanceRecentTurns
    end
    local live = context.semanticContextState
    if live and type(live.RecentTurns) == "function" then
        return live:RecentTurns(12, true)
    end
    local snapshot = type(context.semanticDialogueContext) == "table"
        and context.semanticDialogueContext or {}
    return type(snapshot.recentTurns) == "table" and snapshot.recentTurns or {}
end

function Policy.Allowed(strategy, context)
    strategy = string.upper(tostring(strategy or ""))
    if strategy == "" then return false, "strategy_required" end
    local rule = Policy.RULES[strategy] or {
        cooldownResponderTurns =
            Policy.DEFAULT_COOLDOWN_RESPONDER_TURNS,
    }
    local configured = rule.cooldownResponderTurns
        or rule.cooldownPlayerTurns
        or Policy.DEFAULT_COOLDOWN_RESPONDER_TURNS
    local remaining = math.max(0, math.floor(tonumber(configured)
        or Policy.DEFAULT_COOLDOWN_RESPONDER_TURNS))
    if remaining <= 0 then return true, "no_cooldown" end

    for _, turn in ipairs(recentTurns(context)) do
        if Responder.MatchesTurnSpeaker(context, turn.speaker) then
            if string.upper(tostring(turn.strategy or "")) == strategy then
                return false, "recent_generated_strategy"
            end
            remaining = remaining - 1
            if remaining <= 0 then break end
        end
    end
    return true, "eligible"
end

return Policy
