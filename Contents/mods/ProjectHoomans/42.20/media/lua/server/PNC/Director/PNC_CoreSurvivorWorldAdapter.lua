if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.CoreSurvivorWorldAdapter =
    PNC.CoreSurvivorWorldAdapter or {}

local Adapter = PNC.CoreSurvivorWorldAdapter
local Authority = PNC.CoreSurvivorWorldAuthority
    or require "PNC/Director/PNC_CoreSurvivorWorldAuthority"
local World = Authority.World
local FactionService = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldFactionService"

local function registry()
    local current = Authority.Registry
    if current then return current end
    return Authority.Activate()
end

function Adapter.EnsureCanonical()
    local current, reason = registry()
    if not current then return nil, reason end
    Authority.RefreshStatus()
    return current
end

local function dirty(reason)
    local ok, failure = World.RuntimeStore.MarkDirty(reason)
    if not ok then return nil, failure end
    return true
end

local function listRecords(service, methodName, options)
    if type(service) ~= "table"
        or type(service[methodName]) ~= "function"
    then
        return {}
    end
    local records = service[methodName](options)
    return type(records) == "table" and records or {}
end

-- Repair saves that already passed through the Hoomans cutover while Core's
-- SurvivorWorld registry was only partially populated. This is deliberately
-- one-way and additive: Core remains authoritative for records it already
-- owns, while missing provider records are normalized through Core's public
-- registry contract in dependency order.
function Adapter.ReconcileExistingWorld()
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end

    local added = {
        factions = 0,
        locations = 0,
        communities = 0,
        groups = 0,
    }
    local failures = {}

    local function add(kind, value, getter, upserter)
        if type(value) ~= "table" then return end
        local id = value.id
            or value.factionID
            or value.communityID
            or value.locationID
            or value.groupID
        if not id or current[getter](current, id) then return end
        local canonical, reason = current[upserter](current, value)
        if canonical then
            added[kind] = added[kind] + 1
        else
            failures[#failures + 1] = {
                kind = kind,
                id = tostring(id),
                reason = tostring(reason or "upsert_failed"),
            }
        end
    end

    for _, faction in ipairs(listRecords(PNC.Factions, "List", {
        includeProvisional = true,
    })) do
        add("factions", faction, "GetFaction", "UpsertFaction")
    end
    for _, location in ipairs(listRecords(PNC.AbstractLocations, "List")) do
        add("locations", location, "GetLocation", "UpsertLocation")
    end
    for _, community in ipairs(listRecords(PNC.Communities, "List")) do
        add("communities", community, "GetCommunity", "UpsertCommunity")
    end
    for _, group in ipairs(listRecords(PNC.AbstractGroups, "List")) do
        add("groups", group, "GetGroup", "UpsertGroup")
    end

    local total = added.factions + added.locations
        + added.communities + added.groups
    if total > 0 then
        local ok, reason = dirty("pnc_survivor_world_reconcile")
        if not ok then return nil, reason end
    end

    return {
        added = total,
        factions = added.factions,
        locations = added.locations,
        communities = added.communities,
        groups = added.groups,
        failures = failures,
    }, #failures > 0 and "partial" or "reconciled"
end

local function ensureFactionDependency(current, value, kind)
    local factionID = type(value) == "table"
        and (value.factionID or value.factionId) or nil
    if not factionID or current:GetFaction(factionID) then
        return current
    end

    local report, reason = Adapter.ReconcileExistingWorld()
    if not report then
        return nil, "core_" .. tostring(kind)
            .. "_reconcile_failed:" .. tostring(reason)
    end
    current = registry()
    if not current or not current:GetFaction(factionID) then
        return nil, "survivor_world_" .. tostring(kind)
            .. "_faction_missing"
    end
    return current
end

function Adapter.CommitFaction(faction, reason)
    if type(faction) ~= "table" then
        return nil, "faction_required"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local canonical
    canonical, failure = FactionService.Upsert(current, faction)
    if not canonical then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_faction_mutation")
    if not ok then return nil, failure end
    return canonical
end

local function commitFactionCommand(command, reason)
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local canonical, commandReason = command(current)
    if not canonical then return nil, commandReason end
    if commandReason == "unchanged" then
        return canonical, commandReason
    end
    local ok
    ok, failure = dirty(reason)
    if not ok then return nil, failure end
    return canonical, commandReason
end

function Adapter.AddFactionMember(factionID, actorID, reason)
    return commitFactionCommand(
        function(current)
            return FactionService.AddMember(current, factionID, actorID)
        end,
        reason or "pnc_faction_member_added"
    )
end

function Adapter.RemoveFactionMember(factionID, actorID, reason)
    return commitFactionCommand(
        function(current)
            return FactionService.RemoveMember(current, factionID, actorID)
        end,
        reason or "pnc_faction_member_removed"
    )
end

function Adapter.SetFactionLeader(factionID, actorID, reason)
    return commitFactionCommand(
        function(current)
            return FactionService.SetLeader(current, factionID, actorID)
        end,
        reason or "pnc_faction_leader_changed"
    )
end

function Adapter.TransferFactionMember(
    sourceFactionID,
    destinationFactionID,
    actorID,
    reason
)
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local source, destination, commandReason = FactionService.TransferMember(
        current,
        sourceFactionID,
        destinationFactionID,
        actorID
    )
    if not source then return nil, destination end
    if commandReason == "unchanged" then
        return source, destination, commandReason
    end
    local ok
    ok, failure = dirty(reason or "pnc_faction_member_transferred")
    if not ok then return nil, failure end
    return source, destination, commandReason
end

function Adapter.CommitCommunity(community, reason)
    if type(community) ~= "table" then
        return nil, "community_required"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    current, failure = ensureFactionDependency(
        current, community, "community")
    if not current then return nil, failure end
    local canonical
    canonical, failure = current:UpsertCommunity(community)
    if not canonical then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_community_mutation")
    if not ok then return nil, failure end
    return canonical
end

function Adapter.CommitLocation(location, reason)
    if type(location) ~= "table" then
        return nil, "location_required"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local canonical
    canonical, failure = current:UpsertLocation(location)
    if not canonical then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_location_mutation")
    if not ok then return nil, failure end
    return canonical
end

function Adapter.CommitGroup(group, reason)
    if type(group) ~= "table" then
        return nil, "group_required"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    current, failure = ensureFactionDependency(current, group, "group")
    if not current then return nil, failure end
    local payload = group
    if reason == "group_members_reconciled" or reason == "dissolved_empty_group" then
        payload = {}
        for k, v in pairs(group) do payload[k] = v end
        payload.allowEmptyMembers = true
    end
    local canonical
    canonical, failure = current:UpsertGroup(payload)
    if not canonical then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_group_mutation")
    if not ok then return nil, failure end
    return canonical
end

function Adapter.RemoveGroup(groupID, reason)
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local removed
    removed, failure = current:RemoveGroup(groupID)
    if not removed and failure ~= "group_not_found" then
        return nil, failure
    end
    if removed then
        local ok
        ok, failure = dirty(reason or "pnc_group_removed")
        if not ok then return nil, failure end
    end
    return true
end

local function generatedPlanActorRegistry()
    local actors = PsychopatzCore and PsychopatzCore.Actors or nil
    return actors and actors.DefaultRegistry or nil
end

local function refreshGeneratedViews()
    local extensions = PNC.SurvivorWorldExtensions
    if not extensions or extensions.Active ~= true
        or type(extensions.RefreshFromCore) ~= "function"
    then
        return nil, "survivor_world_extensions_inactive"
    end
    local refreshed, reason = extensions.RefreshFromCore()
    if not refreshed then return nil, reason end
    return true
end

function Adapter.CanCommitGeneratedPlans()
    local extensions = PNC.SurvivorWorldExtensions
    if extensions and extensions.Active ~= true
        and type(extensions.ActivateCutover) == "function"
    then
        -- Self-heal if early f:0 boot ran before ModData was ready so
        -- PopulationDirector never gets permanently stuck on CORE_GENERATION_REQUIRED.
        pcall(extensions.ActivateCutover)
    end
    return World and World.Bootstrap
        and type(World.Bootstrap.CommitCommunityPlan) == "function"
        and type(World.Bootstrap.CommitGroupPlan) == "function"
        and extensions and extensions.Active == true
        and generatedPlanActorRegistry() ~= nil
end

-- Unified Core-first group creation entrypoint for ProjectHoomans (used by
-- Population Director, Debug Spawns, and Caravans so every group originates
-- in PsychopatzCore.SurvivorWorld and promotes through the exact same seam).
function Adapter.CreateUnifiedGroup(spec, reason)
    if type(spec) ~= "table" then return nil, "spec_required" end
    if not Adapter.CanCommitGeneratedPlans()
        or type(World.Bootstrap.CreateUnifiedGroup) ~= "function"
    then
        return nil, "core_unified_group_unavailable"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    local actorReg = generatedPlanActorRegistry()
    local canonical, plan = World.Bootstrap.CreateUnifiedGroup(current, spec, actorReg)
    if not canonical then return nil, plan end

    local okDirty
    okDirty, failure = dirty(reason or "pnc_unified_group_created")
    if not okDirty then return nil, failure end

    refreshGeneratedViews()
    local viewGroup = PNC.AbstractGroups
        and type(PNC.AbstractGroups.Get) == "function"
        and PNC.AbstractGroups.Get(canonical.id) or canonical

    if spec.materializeImmediate == true and type(canonical.memberActorIDs) == "table" then
        local provider = PNC.Persistence and PNC.Persistence.CoreProvider or nil
        local pos = spec.location or spec.position or canonical.location or {}
        for i = 1, #canonical.memberActorIDs do
            local actorID = tostring(canonical.memberActorIDs[i])
            local rec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(actorID) or nil
            if not rec and provider and type(provider.PromoteActor) == "function" then
                local okP, promoted = pcall(provider.PromoteActor, actorID, PsychopatzCore, {
                    x = pos.x,
                    y = pos.y,
                    z = pos.z or 0,
                    forceLive = true,
                })
                if okP and type(promoted) == "table" then rec = promoted end
            end
            if rec then
                rec.x = tonumber(pos.x) or rec.x
                rec.y = tonumber(pos.y) or rec.y
                rec.z = tonumber(pos.z) or rec.z or 0
                rec.runtime = rec.runtime or {}
                rec.runtime.forceLive = true
                rec.runtime.forcePresenceCheck = true
                if PNC.SpatialIndex and type(PNC.SpatialIndex.UpdateNPC) == "function" then
                    PNC.SpatialIndex.UpdateNPC(rec)
                end
                if PNC.Presence and type(PNC.Presence.Reconcile) == "function" then
                    pcall(PNC.Presence.Reconcile, rec)
                end
            end
        end
    end

    return viewGroup, canonical, plan
end

local function ensureGeneratedPlanFaction(current, plan)
    local factionID = type(plan) == "table" and plan.factionID or nil
    if not factionID or current:GetFaction(factionID) then
        return current
    end
    local report, reason = Adapter.ReconcileExistingWorld()
    if not report then
        return nil, "core_generation_reconcile_failed:" .. tostring(reason)
    end
    current = registry()
    if not current or not current:GetFaction(factionID) then
        return nil, "core_generated_plan_faction_missing"
    end
    return current
end

function Adapter.CommitGeneratedCommunityPlan(plan, reason)
    if not Adapter.CanCommitGeneratedPlans() then
        return nil, "core_generated_plan_commit_unavailable"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    current, failure = ensureGeneratedPlanFaction(current, plan)
    if not current then return nil, failure end
    local community
    community, failure = World.Bootstrap.CommitCommunityPlan(
        current,
        plan,
        generatedPlanActorRegistry()
    )
    if not community then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_generated_community")
    if not ok then return nil, failure end
    ok, failure = refreshGeneratedViews()
    if not ok then return nil, failure end
    return current:GetCommunity(plan.communityID)
end

function Adapter.CommitGeneratedGroupPlan(plan, reason)
    if not Adapter.CanCommitGeneratedPlans() then
        return nil, "core_generated_plan_commit_unavailable"
    end
    local current, failure = Adapter.EnsureCanonical()
    if not current then return nil, failure end
    current, failure = ensureGeneratedPlanFaction(current, plan)
    if not current then return nil, failure end
    local group
    group, failure = World.Bootstrap.CommitGroupPlan(
        current,
        plan,
        generatedPlanActorRegistry()
    )
    if not group then return nil, failure end
    local ok
    ok, failure = dirty(reason or "pnc_generated_group")
    if not ok then return nil, failure end
    ok, failure = refreshGeneratedViews()
    if not ok then return nil, failure end
    return current:GetGroup(plan.groupID)
end

function Adapter.GetFaction(factionID)
    local current = registry()
    return current and current:GetFaction(factionID) or nil
end

function Adapter.GetCommunity(communityID)
    local current = registry()
    return current and current:GetCommunity(communityID) or nil
end

function Adapter.GetLocation(locationID)
    local current = registry()
    return current and current:GetLocation(locationID) or nil
end

function Adapter.GetGroup(groupID)
    local current = registry()
    return current and current:GetGroup(groupID) or nil
end

return Adapter
