-- Keep Project A-Life from treating managed Hoomans bodies as ordinary zombies.
-- This is a runtime bridge owned by Hoomans; the Workshop copy is untouched.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local Bridge = PNC.Compatibility.ProjectALifeReverseBridge
    or { installAttempts = 0 }
PNC.Compatibility.ProjectALifeReverseBridge = Bridge
Bridge.installAttempts = tonumber(Bridge.installAttempts) or 0

local function isHoomansBody(body)
    local ownership = PNC.Compatibility.ActorOwnership
    if not ownership or type(ownership.IsHoomansOwned) ~= "function" then
        return false
    end
    local ok, owned = pcall(ownership.IsHoomansOwned, body)
    return ok and owned == true
end

local function adapter()
    return PNC.Compatibility.ProjectALifeAdapter
end

local function canProjectALifeAttack(actor, body, phase)
    local integration = adapter()
    if not integration or type(integration.CanProjectALifeAttack) ~= "function" then
        return false, "projectalife_adapter_unavailable"
    end
    local ok, allowed, reason = pcall(
        integration.CanProjectALifeAttack,
        actor,
        body,
        { phase = phase }
    )
    if not ok then return false, "projectalife_relation_failed" end
    return allowed == true, reason
end

local function installReverseBridge()
    local alife = ProjectALife
    local perception = alife and alife.Perception
    local combat = alife and alife.Combat
    if not perception or type(perception.findThreat) ~= "function"
        or not combat or type(combat.friendlyBody) ~= "function"
    then
        return false
    end

    if Bridge.perception == perception
        and perception.findThreat == Bridge.findThreatWrapper
        and Bridge.combat == combat
        and combat.friendlyBody == Bridge.friendlyBodyWrapper
        and (type(combat.kindOf) ~= "function"
            or combat.kindOf == Bridge.kindOfWrapper)
        and (type(combat.peekKind) ~= "function"
            or combat.peekKind == Bridge.peekKindWrapper)
        and (type(combat.targetIsHuman) ~= "function"
            or combat.targetIsHuman == Bridge.targetIsHumanWrapper)
    then
        return true
    end

    local originalFindThreat = perception.findThreat
    local originalFriendlyBody = combat.friendlyBody
    local originalKindOf = combat.kindOf
    local originalPeekKind = combat.peekKind
    local originalTargetIsHuman = combat.targetIsHuman

    local findThreatWrapper
    findThreatWrapper = function(actor, shell, mode)
        local target, distance, kind = originalFindThreat(actor, shell, mode)
        if target and isHoomansBody(target) then
            local allowed = canProjectALifeAttack(actor, target, "perception")
            if not allowed then
                local engagements = perception.engagements
                if type(engagements) == "table" and type(actor) == "table" then
                    engagements[actor.uid] = nil
                end
                return nil, math.huge, nil
            end
            kind = "actor"
        end
        return target, distance, kind
    end

    local friendlyBodyWrapper
    friendlyBodyWrapper = function(actor, shell, body)
        if isHoomansBody(body) then
            local allowed, reason = canProjectALifeAttack(
                actor, body, "damage")
            if not allowed then return true, reason end
            return false
        end
        return originalFriendlyBody(actor, shell, body)
    end

    local kindOfWrapper
    if type(originalKindOf) == "function" then
        kindOfWrapper = function(body)
            if isHoomansBody(body) then return "actor" end
            return originalKindOf(body)
        end
        combat.kindOf = kindOfWrapper
    end

    local peekKindWrapper
    if type(originalPeekKind) == "function" then
        peekKindWrapper = function(body)
            if isHoomansBody(body) then return "actor" end
            return originalPeekKind(body)
        end
        combat.peekKind = peekKindWrapper
    end

    local targetIsHumanWrapper
    if type(originalTargetIsHuman) == "function" then
        targetIsHumanWrapper = function(body)
            if isHoomansBody(body) then return true end
            return originalTargetIsHuman(body)
        end
        combat.targetIsHuman = targetIsHumanWrapper
    end

    perception.findThreat = findThreatWrapper
    combat.friendlyBody = friendlyBodyWrapper
    Bridge.perception = perception
    Bridge.findThreatWrapper = findThreatWrapper
    Bridge.combat = combat
    Bridge.friendlyBodyWrapper = friendlyBodyWrapper
    Bridge.kindOfWrapper = kindOfWrapper
    Bridge.peekKindWrapper = peekKindWrapper
    Bridge.targetIsHumanWrapper = targetIsHumanWrapper
    return true
end

local function removeRetry()
    if Bridge.retry and Events and Events.OnTick
        and Events.OnTick.Remove
    then
        Events.OnTick.Remove(Bridge.retry)
    end
end

local function retryInstall()
    Bridge.installAttempts = Bridge.installAttempts + 1
    if installReverseBridge() or Bridge.installAttempts >= 120 then
        removeRetry()
    end
end

if not installReverseBridge() and Events and Events.OnTick
    and Events.OnTick.Add
then
    Bridge.retry = retryInstall
    Events.OnTick.Add(retryInstall)
end

return installReverseBridge
