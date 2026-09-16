-- Bandits relationship policy. No Bandit actor is treated as hostile merely
-- because its brain is unavailable; unknown state fails closed.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}
PNC.Compatibility.Bandits.Relationships =
    PNC.Compatibility.Bandits.Relationships or {}

local Relationships = PNC.Compatibility.Bandits.Relationships

local function banditBody(target)
    if not target then return nil end
    if target.worldObject then return target.worldObject end
    if target.body then return target.body end
    return nil
end

local function banditBrain(body)
    if not body then return nil end
    if BanditBrain and type(BanditBrain.Get) == "function" then
        return BanditBrain.Get(body)
    end
    return body.brain
end

local function playerAligned(record)
    local verifier = PNC.Identity and PNC.Identity.Verifier
    if not record then return false end
    if record.recruited == true
        or record.ownerOnlineID ~= nil
        or (record.ownerUsername ~= nil
            and tostring(record.ownerUsername) ~= "")
    then
        return true
    end
    if verifier and verifier.IsPlayerFaction then
        return verifier.IsPlayerFaction(record) == true
    end
    if verifier and verifier.IsColonyOwnedNPC then
        return verifier.IsColonyOwnedNPC(record) == true
    end
    return false
end

local function isLiveHooman(record)
    return record ~= nil
        and record.id ~= nil
        and record.alive ~= false
end

function Relationships.CanHoomanAttackBandit(context)
    local target = context and context.target
    local source = context and context.attacker
    local brain = banditBrain(banditBody(target))
    if not brain then return false, "bandit_brain_unavailable" end
    if brain.hostile == true then return true, "bandit_hostile" end
    if brain.hostileP == true
        and (playerAligned(source) or isLiveHooman(source))
    then
        return true, "bandit_hostile_to_hooman"
    end
    return false, "bandit_not_hostile_to_source"
end

function Relationships.CanBanditAttackHooman(context)
    local attacker = context and context.attacker
    local target = context and context.target
    local brain = banditBrain(attacker and attacker.worldObject)
    if not brain then return false, "bandit_brain_unavailable" end
    if brain.hostile == true then return true, "bandit_hostile" end
    if brain.hostileP == true
        and (playerAligned(target) or isLiveHooman(target))
    then
        return true, "bandit_hostile_to_hooman"
    end
    return false, "bandit_not_hostile_to_source"
end

return Relationships
