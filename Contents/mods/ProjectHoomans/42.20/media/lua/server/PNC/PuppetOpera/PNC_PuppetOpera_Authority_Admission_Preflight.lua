-- Server-authoritative Puppet Opera resolution and preflight readiness.
--
-- This provider owns blueprint/NPC resolution, actor compatibility checks,
-- ownership descriptions, and bounded readiness reporting.  Session creation
-- is kept in the sibling admission session provider.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal
local Blueprints = Internal.Blueprints or Opera.Blueprints
local Anchors = Internal.Anchors or Opera.Anchors
local NPCOverride = Internal.NPCOverride or Opera.Override
local Registry = Internal.Registry or PNC.Registry

local now = Internal.now
local ownerID = Internal.ownerID
local distanceSquared = Internal.distanceSquared
local inRange = Internal.inRange
local hasValue = Internal.hasValue
local npcActionState = Internal.npcActionState
local npcActionContextState = Internal.npcActionContextState
local actorFailureReason = Internal.actorFailureReason
local invalidPlayer = Internal.invalidPlayer

local function resolveNPC(npcID)
    local id = tostring(npcID or "")
    if id == "" or not Registry then return nil, nil, "npc_id_missing" end
    local record = Registry.Get and Registry.Get(id) or nil
    local body = Registry.GetLiveZombie and Registry.GetLiveZombie(id) or nil
    if not record then return nil, nil, "npc_not_registered" end
    if not body then return record, nil, "npc_not_live" end
    return record, body, nil
end

local function resolveBlueprint(args)
    args = type(args) == "table" and args or {}
    local blueprintID = tostring(args.blueprintId or "social.kiss_player_npc")
    local blueprint = Blueprints.Get(blueprintID)
    if type(args.definition) ~= "table" then
        if not blueprint then return nil, "blueprint_not_found" end
        return blueprint
    end
    local normalized, reason = Blueprints.Normalize(
        blueprintID,
        args.definition
    )
    if not normalized then
        return nil, "blueprint_definition_invalid:" .. tostring(reason)
    end
    return normalized
end

local function ownerDescription(record, body)
    local runtime = record and record.runtime or {}
    local lease = runtime.puppetOperaLease
    if lease and lease.sessionId then
        return "puppet_opera:" .. tostring(lease.sessionId)
    end
    local movement = runtime.puppetOperaMovement
    if movement and movement.sessionId then
        return "puppet_movement:" .. tostring(movement.sessionId)
    end
    local ownerFields = {
        { "animationScene", "animation_scene" },
        { "conversationLease", "conversation" },
        { "taskLeaseId", "task" },
        { "orderLeaseId", "order" },
        { "facilityActivity", "facility" },
        { "workOrderId", "work_order" },
        { "medicalCare", "medical" },
        { "treatment", "treatment" },
        { "roamAmbient", "ambient" },
    }
    for _, field in ipairs(ownerFields) do
        if hasValue(runtime[field[1]]) then return field[2] end
    end
    if PNC.Compatibility and PNC.Compatibility.ActorOwnership
        and PNC.Compatibility.ActorOwnership.GetForeignOwner
    then
        local foreign = PNC.Compatibility.ActorOwnership.GetForeignOwner(body)
        if foreign then return "foreign:" .. tostring(foreign) end
    end
    if runtime.moveIntent and runtime.moveIntent.kind == "move" then
        return "movement"
    end
    return nil
end

local function validatePlan(plan)
    if type(plan) ~= "table" or type(plan.actors) ~= "table" then
        return false, "anchor_plan_missing"
    end
    if type(getCell) ~= "function" then return true end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return true end
    local actorID
    local target
    for actorID, target in pairs(plan.actors) do
        if not cell:getGridSquare(target.x, target.y, target.z) then
            return false, "anchor_square_unloaded:" .. tostring(actorID)
        end
    end
    return true
end

local function supportedActors(blueprint)
    local actorID
    local definition
    for actorID, definition in pairs(blueprint.actors or {}) do
        local allowed = definition.kind and { definition.kind }
            or definition.allowedKinds or {}
        local hasRuntimeKind = false
        for _, actorKind in ipairs(allowed) do
            if actorKind == "local_player"
                or actorKind == "nearby_live_npc"
            then
                hasRuntimeKind = true
                break
            end
        end
        if not hasRuntimeKind then
            return false, "actor_kind_not_supported:" .. tostring(actorID)
        end
    end
    return true
end

local function actorAllowsKind(definition, actorKind)
    if not definition then return false end
    if definition.kind then return definition.kind == actorKind end
    for _, allowedKind in ipairs(definition.allowedKinds or {}) do
        if allowedKind == actorKind then return true end
    end
    return false
end

local function requestedBinding(args, actorID, definition)
    local bindings = type(args) == "table"
        and type(args.actors) == "table" and args.actors or {}
    local binding = bindings[actorID]
    if not binding and tostring(actorID) == "npc"
        and type(args) == "table"
    then
        binding = args.npcID
    end
    if not binding and definition and definition.kind == "local_player" then
        binding = "__local_player__"
    end
    if binding == nil or tostring(binding) == "" then return nil end
    return tostring(binding)
end

local function playerReadiness(player, actorID, playerReason)
    return {
        actorID = tostring(actorID),
        bindingID = "__local_player__",
        kind = "local_player",
        ready = playerReason == nil,
        reason = playerReason,
        reasonDetail = playerReason or "ready",
    }
end

local function buildNPCReadiness(player, actorID, npcID, allowedSession)
    local result = {
        actorID = tostring(actorID),
        kind = "nearby_live_npc",
        bindingID = npcID and tostring(npcID) or nil,
        ready = false,
        actionState = "",
        actionContextState = "",
        owner = nil,
        distance = nil,
        reason = nil,
        reasonDetail = nil,
        suspendable = false,
        overrideOwnerKind = nil,
    }
    if not npcID or tostring(npcID) == "" then
        result.reason = "npc_binding_missing"
        result.reasonDetail = "npc_binding_missing:" .. tostring(actorID)
        return result
    end

    local record, body, resolveReason = resolveNPC(npcID)
    if not record or not body then
        result.reason = resolveReason or "npc_unavailable"
        result.reasonDetail = actorFailureReason(
            result.reason,
            actorID,
            body
        )
        return result
    end

    result.bindingID = tostring(record.id or npcID)
    result.actionState = npcActionState(body)
    result.actionContextState = npcActionContextState(body)
    result.owner = ownerDescription(record, body)
    local distance = distanceSquared(player, body)
    result.distance = distance and math.sqrt(distance) or nil

    local overrideReady
    local overrideInfo
    overrideReady, overrideInfo = NPCOverride.GetReadiness(record, body, {
        sessionId = allowedSession and allowedSession.sessionId or nil,
    })
    if overrideReady then
        result.suspendable = overrideInfo.suspendable == true
        result.overrideOwnerKind = overrideInfo.ownerKind
        result.reasonDetail = overrideInfo.suspendable
            and "suspendable:" .. tostring(overrideInfo.ownerKind or "idle")
            or "ready"
    end

    local reason
    if not overrideReady then reason = overrideInfo end
    if not reason and not inRange(
        player,
        body,
        tonumber(Opera.Config.runtimeActorRange) or 12
    ) then
        reason = "npc_out_of_range"
    end
    if not reason and Authority.ByActor[result.bindingID]
        and Authority.ByActor[result.bindingID] ~= allowedSession
    then
        reason = "npc_session_already_active"
    end
    if reason then
        result.reason = reason
        result.reasonDetail = actorFailureReason(reason, actorID, body)
        return result
    end

    result.ready = true
    result.reason = nil
    if not result.reasonDetail then result.reasonDetail = "ready" end
    return result
end

local function buildPreflight(player, args)
    local blueprint, reason = resolveBlueprint(args)
    if not blueprint then return nil, reason end
    local runtimeOK
    runtimeOK, reason = Blueprints.ValidateRuntime(blueprint)
    if not runtimeOK then return nil, reason end
    local actorOK
    actorOK, reason = supportedActors(blueprint)
    if not actorOK then return nil, reason end

    local result = {
        blueprintId = blueprint.id,
        checkedAt = now(),
        ready = true,
        actors = {},
        runtimeRange = tonumber(Opera.Config.runtimeActorRange) or 12,
    }
    local playerReason = invalidPlayer(player)
    local ownerSession = Authority.ByOwner[ownerID(player)]
    local allowedSession = ownerSession and ownerSession.previewOnly
        and ownerSession or nil
    local npcCount = 0
    for actorID, definition in pairs(blueprint.actors or {}) do
        local binding = requestedBinding(args, actorID, definition)
        if binding == "__local_player__" then
            if not actorAllowsKind(definition, "local_player") then
                result.ready = false
                result.reason = result.reason
                    or "actor_kind_not_allowed:local_player:"
                        .. tostring(actorID)
            else
                result.actors[actorID] = playerReadiness(
                    player,
                    actorID,
                    playerReason
                )
                if playerReason then result.ready = false end
            end
        elseif binding then
            if not actorAllowsKind(definition, "nearby_live_npc") then
                result.ready = false
                result.reason = result.reason
                    or "actor_kind_not_allowed:nearby_live_npc:"
                        .. tostring(actorID)
            else
                local npcID = binding
                local readiness = buildNPCReadiness(
                    player,
                    actorID,
                    npcID,
                    allowedSession
                )
                readiness.required = definition.required ~= false
                result.actors[actorID] = readiness
                npcCount = npcCount + 1
                if readiness.required and readiness.ready ~= true then
                    result.ready = false
                    result.reason = result.reason or readiness.reasonDetail
                end
            end
        elseif definition.required ~= false then
            result.ready = false
            result.reason = result.reason
                or "actor_binding_missing:" .. tostring(actorID)
        end
    end
    if npcCount == 0 then
        result.ready = false
        result.reason = result.reason or "runtime_actor_missing"
    end

    if playerReason == nil then
        local plan, planReason = Anchors.BuildPlan(blueprint, player)
        if not plan then
            result.ready = false
            result.reason = planReason
        else
            local planOK, planValidationReason = validatePlan(plan)
            if not planOK then
                result.ready = false
                result.reason = planValidationReason
            end
        end
    end
    return result
end

Internal.resolveNPC = resolveNPC
Internal.resolveBlueprint = resolveBlueprint
Internal.ownerDescription = ownerDescription
Internal.validatePlan = validatePlan
Internal.supportedActors = supportedActors
Internal.actorAllowsKind = actorAllowsKind
Internal.requestedBinding = requestedBinding
Internal.buildPreflight = buildPreflight

return Authority
