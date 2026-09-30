-- Bandits foreign-actor compatibility entry point.
--
-- This hub only bootstraps the namespace, loads the cohesive spokes in
-- dependency order, and registers the capability adapter. Public contract:
--
--   PNC.Compatibility.Bandits.Internal     -- ownership + cache access
--   PNC.Compatibility.Bandits.Targeting    -- actor refs + discovery
--   PNC.Compatibility.Bandits.Relationships-- attack permission
--   PNC.Compatibility.Bandits.Combat       -- damage delivery
--   PNC.Compatibility.Bandits.Flavor       -- native presentation
--   returns the PNC.Compatibility.Bandits namespace table
--
-- PNC_Bandits_AnimPathCompat is deliberately NOT required here: it must patch
-- PZ's animation file map before any other shared module reads it, so it is
-- loaded from PNC/00_PNC_Init.lua instead.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.Bandits or {}
Bridge.Internal = Bridge.Internal or {}
PNC.Compatibility.Bandits = Bridge

local ActorOwnership = PNC.Compatibility.ActorOwnership
    or require "PNC/Core/Compatibility/PNC_ActorOwnership"

require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Access"
require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Targeting"
require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Relationships"
require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Combat"
require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Flavor"

local Access = Bridge.Internal
local Targeting = Bridge.Targeting
local Relationships = Bridge.Relationships
local Combat = Bridge.Combat
local Flavor = Bridge.Flavor

-- Inbound provider events. Single consumer: the registration spec below.
local function onEvent(context)
    local eventName = context and context.event
    local payload = context and context.context or {}
    local target = payload.target
    local body = target and target.worldObject
    if eventName ~= "foreign_damage_applied"
        or not body
        or not Flavor
        or type(Flavor.Say) ~= "function"
    then
        return false
    end
    return Flavor.Say(body, "HOOMANS_HIT") == true
end

if not ActorOwnership
    or type(ActorOwnership.RegisterAdapter) ~= "function"
then
    return Bridge
end

ActorOwnership.RegisterAdapter({
    id = "Bandits",
    version = "Bandits2-B42.20",
    apiVersion = 1,
    detect = Access.IsBanditBody,
    capabilities = {
        targeting = true,
        relationships = true,
        damage = true,
        events = true,
        flavor = false,
    },
    getActorRef = Targeting.GetActorRef,
    resolveTarget = Targeting.ResolveTarget,
    enumerateTargets = Targeting.EnumerateTargets,
    canAttack = Relationships.CanAttack,
    applyDamage = Combat.ApplyDamage,
    onEvent = onEvent,
})

return Bridge
