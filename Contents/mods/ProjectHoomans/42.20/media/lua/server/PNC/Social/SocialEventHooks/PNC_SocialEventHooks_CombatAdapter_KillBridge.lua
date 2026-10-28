-- Server kill bridge consumed by PsychopatzCore's ZombieKillDetector.
--
-- This bridge records authoritative threat/encounter meaning and then hands
-- routine presentation to the ephemeral semantic combat-reaction service.
-- It does not create per-kill relationship or conduct memories.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local ReactionService = PNC.SemanticCombatReactionService
    or PNC.Semantics and PNC.Semantics.CombatReactionService
if not ReactionService then
    local ok, loaded = pcall(
        require, "PNC/Semantics/PNC_SemanticCombatReactionService"
    )
    ReactionService = ok and loaded or nil
end

local call = H.CombatCall or function(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end
local audit = H.CombatAudit or function() end

function H.OnWeaponHitCharacter(attacker, target, context)
    local result, reason = Hooks.OnPlayerWeaponHitThreat(attacker, target)
    audit({
        "luaSide=server",
        "runtime=" .. tostring(context and context.runtime or "unknown"),
        "event=OnWeaponHitCharacter",
        "result=" .. tostring(result),
        "reason=" .. tostring(reason or "nil"),
        "attackerOnlineID="
            .. tostring(call(attacker, "getOnlineID") or "nil"),
        "zombieOnlineID="
            .. tostring(call(target, "getOnlineID") or "nil"),
    })
    return result, reason
end

function H.OnZombieDead(killer, zombie, context)
    local threatID = context and context.threatID
        or tostring(call(zombie, "getOnlineID") or "nil")
    local result, reason = Hooks.HandleClientZombieKill(
        killer, zombie, context
    )
    local reactions = 0
    local reactionReason = "kill_not_dispatched"
    if result == true and ReactionService
        and type(ReactionService.OnPlayerKill) == "function"
    then
        reactions, reactionReason = ReactionService.OnPlayerKill(
            killer, zombie, {
                source = context and (
                    context.killerSource or context.source
                ) or "zombie_kill_detector",
            }
        )
    end
    audit({
        "luaSide=server",
        "event=PlayerKillSemanticReaction",
        "phase=ephemeral_presentation",
        "result=" .. tostring(reactions > 0),
        "reason=" .. tostring(reactionReason),
        "threatID=" .. tostring(threatID),
        "reactionCount=" .. tostring(reactions),
    })
    return result, reason
end

return Hooks
