if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local EntityRef = PNC.EntityRef
local Core = PNC.Core

function H.OnWeaponHitCharacter(attacker, target)
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "OnWeaponHitCharacter",
            event = "weapon_hit",
            worldAgeHours = H.WorldAgeHours(),
            onlineID = attacker and attacker.getOnlineID
                and attacker:getOnlineID() or nil,
            result = "received",
        })
    end
    Hooks.OnPlayerWeaponHitThreat(attacker, target)
end

function H.OnZombieDead(zombie)
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "OnZombieDead",
            event = "zombie_death",
            worldAgeHours = H.WorldAgeHours(),
            threatID = H.ThreatIDFor(zombie),
            result = "received",
        })
    end
    Hooks.OnThreatDied(zombie)
end

if Events and Events.OnWeaponHitCharacter
    and not Hooks.WeaponHitHookRegistered
then
    Events.OnWeaponHitCharacter.Add(H.OnWeaponHitCharacter)
    Hooks.WeaponHitHookRegistered = true
end

if Events and Events.OnZombieDead
    and not Hooks.ZombieDeadHookRegistered
then
    Events.OnZombieDead.Add(H.OnZombieDead)
    Hooks.ZombieDeadHookRegistered = true
end

return Hooks
