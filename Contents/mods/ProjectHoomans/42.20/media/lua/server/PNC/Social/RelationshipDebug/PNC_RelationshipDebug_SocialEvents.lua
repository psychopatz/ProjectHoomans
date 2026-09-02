if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}
PNC.RelationshipDebug.Internal = PNC.RelationshipDebug.Internal or {}

local Debug = PNC.RelationshipDebug
local Internal = Debug.Internal
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local Core = PNC.Core
local DEBUG_EVENTS = {
    treated_wound = "health",
    saved_from_incapacitation = "health",
    protected_from_attacker = "combat",
    witnessed_player_kill = "combat",
    witnessed_player_hurt = "combat",
    player_damaged_npc = "combat",
    survived_combat_together = "combat",
    abandoned_in_combat = "combat",
}
local worldAgeHours = Internal.worldAgeHours
local resolveTarget = Internal.resolveTarget

function Debug.TriggerSocialEvent(player, args)
    local eventType = tostring(args and args.eventType or "")
    local sourceSystem = DEBUG_EVENTS[eventType]
    local at = worldAgeHours()
    local observerNPCID = args and args.observerNPCID
    local observer = Registry and Registry.Get
        and Registry.Get(tostring(observerNPCID or "")) or nil
    local targetKey
    local target
    local reason
    local processed
    if not sourceSystem then
        return nil, "unsupported_debug_event"
    end
    if not observer or observer.alive == false then
        return nil, "observer_not_found"
    end
    targetKey, target, reason = resolveTarget(player, args, at)
    if not targetKey then
        return nil, reason
    end
    if targetKey == EntityRef.ForNPC(observer.id) then
        return nil, "identical_observer_target"
    end
    if not PNC.SocialEvents or not PNC.SocialEvents.Process then
        return nil, "social_event_service_unavailable"
    end
    processed = PNC.SocialEvents.Process({
        id = "social:" .. tostring(
            Core.GenerateID("debug_relationship")
        ),
        type = eventType,
        actorKey = targetKey,
        targetKey = EntityRef.ForNPC(observer.id),
        occurredAt = at,
        sourceSystem = sourceSystem,
        context = {
            debug = true,
            requestedBy = player and player.getUsername
                and tostring(player:getUsername()) or nil,
        },
    })
    return Debug.BuildSnapshot(
        observer.id,
        targetKey,
        target,
        at,
        processed
    )
end
