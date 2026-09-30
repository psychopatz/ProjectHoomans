-- Project A-Life ownership, damage, and world-event compatibility entry point.
--
-- Project A-Life remains responsible for its actors and world simulation. This
-- hub only bootstraps the namespace, loads the cohesive spokes in dependency
-- order, and registers the capability adapter.
--
-- Public contract (unchanged):
--   PNC.Compatibility.ProjectALifeAdapter  -- capability adapter table
--   PNC.Compatibility.ProjectALifePolicy   -- directed stance policy
--   returns the PNC.Compatibility.ProjectALifeAdapter namespace table

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.ProjectALifeAdapter or {}
PNC.Compatibility.ProjectALifeAdapter = Bridge
PNC.Compatibility.ProjectALifeEvents =
    PNC.Compatibility.ProjectALifeEvents or {}

require "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_Access"
require "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_Policy"
require "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_Targeting"
require "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_Combat"

local Adapter = Bridge

-- Inbound provider events. This lives on the hub because the registration spec
-- below is its only consumer.
local function onEvent(eventContext)
    if type(eventContext) ~= "table" then return false end

    local eventName = eventContext.event
    local events = PNC.Compatibility.ProjectALifeEvents

    if eventName == "projectalife_encounter"
        or eventName == "projectalife_faction_stance"
        or eventName == "projectalife_faction_conflict"
    then
        local server = events.Server
        if server and type(server.Publish) == "function" then
            return server.Publish(eventName, eventContext.context) == true
        end
        return false
    end

    if eventName == "projectalife_meta_event"
        or eventName == "projectalife_client_flavor"
    then
        local client = events.Client
        if client and type(client.HandleAdapterEvent) == "function" then
            return client.HandleAdapterEvent(eventContext) == true
        end
    end

    return false
end

local ActorOwnership = PNC.Compatibility.ActorOwnership
if not ActorOwnership
    or type(ActorOwnership.RegisterAdapter) ~= "function"
then
    return Bridge
end

ActorOwnership.RegisterAdapter({
    id = "ProjectALifeNPCs",
    version = "ProjectALifeNPCs-B42.20",
    apiVersion = 1,
    detect = Adapter.IsProjectALifeBody,
    capabilities = {
        events = true,
        targeting = true,
        relationships = true,
        damage = true,
    },
    onEvent = onEvent,
    enumerateTargets = Adapter.enumerateTargets,
    getActorRef = Adapter.getActorRef,
    resolveTarget = Adapter.resolveTarget,
    canAttack = Adapter.CanHoomansAttack,
    applyDamage = Adapter.applyDamage,
})

require "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_DamageBridge"
require "PNC/Core/Compatibility/Mods/ProjectALife/PNC_ProjectALife_ReverseBridge"

return Bridge
