-- Project Hoomans relationship consumer for PsychopatzCore's detector.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local Detector = require
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector"

local function call(object, method, ...)
    if not object or not object[method] then
        return nil
    end
    local ok, value = pcall(object[method], object, ...)
    if ok then
        return value
    end
    return nil
end

local function audit(fields)
    local message = "[ZombieKillAudit] " .. table.concat(fields, " ")
    if Core and Core.LogInfo then
        Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
end

function Hooks.HandleClientZombieKill(player, zombie, context)
    local threatID = context and context.threatID
        or H.ThreatIDFor(zombie)
    local result
    local reason
    if Hooks.ThreatAttributions[threatID] then
        result, reason = Hooks.OnThreatDied(zombie)
    else
        result, reason = Hooks.OnPlayerWeaponHitThreat(player, zombie)
        -- A pure-MP report arrives after the client observes the death. The
        -- server may not have observed the preceding hit, so complete the
        -- same attribution immediately when the target is already dead.
        if result == true and reason == "threat_hit_recorded"
            and (call(zombie, "isDead") == true
                or (tonumber(call(zombie, "getHealth")) or 1) <= 0)
        then
            result, reason = Hooks.OnThreatDied(zombie)
        end
    end
    audit({
        "luaSide=server",
        "event=ZombieKillReport",
        "phase=relationship_dispatch",
        "result=" .. tostring(result),
        "reason=" .. tostring(reason or "nil"),
        "playerKey=" .. tostring(Hooks.ResolvePlayerKey(player)),
        "threatID=" .. tostring(threatID),
        "killerOnlineID="
            .. tostring(call(player, "getOnlineID") or "nil"),
        "serverNativeZombieKills="
            .. tostring(call(player, "getZombieKills") or "nil"),
        "clientNativeZombieKills="
            .. tostring(context and context.nativeZombieKills or "nil"),
        "source=" .. tostring(context and context.source or "unknown"),
    })
    return result, reason
end

local registered, reason = Detector.RegisterConsumer(
    "ProjectHoomans.SocialCombat",
    {
        findZombieByOnlineID = PNC.Network
            and PNC.Network.FindZombieByOnlineID or nil,
        onServerHit = H.OnWeaponHitCharacter,
        onServerKill = H.OnZombieDead,
    }
)

audit({
    "luaSide=server",
    "event=consumer_registration",
    "consumer=ProjectHoomans.SocialCombat",
    "result=" .. tostring(registered),
    "reason=" .. tostring(reason or "nil"),
})

return Hooks
