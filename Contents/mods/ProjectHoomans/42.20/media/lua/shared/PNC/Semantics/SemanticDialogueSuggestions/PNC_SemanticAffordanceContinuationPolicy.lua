-- Ephemeral generated-affordance recurrence policy.
--
-- This policy never rejects typed NLU. It only keeps the generated button
-- frontier from proposing the same conversational move in a tight loop.
local Policy = {}

Policy.DEFAULT_COOLDOWN_PLAYER_TURNS = 1
Policy.RULES = {
    DOUBLE_DOWN = { cooldownPlayerTurns = 2 },
    CLAIM_JOKE = { cooldownPlayerTurns = 2 },
    CHALLENGE = { cooldownPlayerTurns = 1 },
    CALL_BLUFF = { cooldownPlayerTurns = 2 },
    DISMISS = { cooldownPlayerTurns = 1 },
    ASK_WHY = { cooldownPlayerTurns = 1 },
    ASK_FOLLOWUP = { cooldownPlayerTurns = 1 },
    APOLOGIZE = { cooldownPlayerTurns = 1 },
    DEESCALATE = { cooldownPlayerTurns = 1 },
}

local function recentTurns(context)
    context = type(context) == "table" and context or {}
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
        cooldownPlayerTurns = Policy.DEFAULT_COOLDOWN_PLAYER_TURNS,
    }
    local remaining = math.max(0,
        math.floor(tonumber(rule.cooldownPlayerTurns)
            or Policy.DEFAULT_COOLDOWN_PLAYER_TURNS))
    if remaining <= 0 then return true, "no_cooldown" end

    for _, turn in ipairs(recentTurns(context)) do
        if tostring(turn.speaker or "") == "player" then
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
