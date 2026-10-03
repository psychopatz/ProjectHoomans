-- Puppet Opera NPC ownership readiness and safety checks.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Override = PNC.PuppetOpera.Override or {}

local Override = PNC.PuppetOpera.Override
local Internal = Override.Internal or {}
local OVERRIDE_KEY = Internal.OverrideKey

function Override.IsOwned(record, sessionID)
    local value = record and record.runtime
        and record.runtime[OVERRIDE_KEY] or nil
    return value ~= nil
        and tostring(value.sessionId or "") == tostring(sessionID or "")
end

function Override.GetState(record)
    return record and record.runtime
        and record.runtime[OVERRIDE_KEY] or nil
end

function Override.GetReadiness(record, body, options)
    options = type(options) == "table" and options or {}
    local runtime = Internal.RuntimeOf(record)
    local current = runtime and runtime[OVERRIDE_KEY] or nil
    local lease = runtime and runtime.puppetOperaLease or nil
    local actionState
    local context
    local ownerKind
    local suspendable
    local bumpReplaceable = false
    if not record then return false, "npc_record_missing" end
    if not body then return false, "npc_body_unavailable" end
    if record.alive == false or body.isDead and body:isDead() then
        return false, "npc_dead"
    end
    if body.getVehicle and body:getVehicle() then
        return false, "npc_in_vehicle"
    end
    if body.isSeatedInVehicle and body:isSeatedInVehicle() then
        return false, "npc_seated"
    end
    if current and tostring(current.sessionId or "")
        ~= tostring(options.sessionId or "")
    then
        return false, "npc_owned_by_other_puppet_override"
    end
    if lease and tostring(lease.sessionId or "")
        ~= tostring(options.sessionId or "")
    then
        return false, "npc_owned_by_other_puppet_session"
    end
    actionState = Internal.ActionStateOf(body)
    if actionState == "bumped" then
        bumpReplaceable = Internal.ReplaceableBump(body)
        if not bumpReplaceable then
            return false, "npc_action_state_busy"
        end
    end
    if Internal.UnsafeActionStates[actionState] == true then
        return false, "npc_action_state_busy"
    end
    local pathService = Internal.PathService
    if pathService and pathService.IsTraversalActive
        and pathService.IsTraversalActive(record, body)
    then
        return false, "npc_traversal_active"
    end
    if PNC.Compatibility and PNC.Compatibility.ActorOwnership
        and PNC.Compatibility.ActorOwnership.IsForeignOwned
        and PNC.Compatibility.ActorOwnership.IsForeignOwned(body)
    then
        return false, "npc_owned_by_foreign_mod"
    end

    context = Internal.ContextOf(record)
    ownerKind = context and tostring(context.ownerKind or "") or "idle"
    -- Non-combat Hoomans behavior is resumable at this boundary. The control
    -- lease prevents its provider from writing over the scene while the
    -- original runtime remains available for restoration.
    suspendable = context ~= nil
        or Internal.PathIsActive(runtime)
        or runtime and runtime.animationScene ~= nil
        or record.activeJob ~= nil
        or false
    return true, {
        ownerKind = ownerKind,
        ownerToken = context and context.token or nil,
        context = context,
        suspendable = suspendable,
        reason = suspendable and "suspendable" or "ready",
        actionState = actionState,
        bumpReplaceable = bumpReplaceable,
    }
end

function Override.CanAcquire(record, body, options)
    return Override.GetReadiness(record, body, options)
end

return Override
