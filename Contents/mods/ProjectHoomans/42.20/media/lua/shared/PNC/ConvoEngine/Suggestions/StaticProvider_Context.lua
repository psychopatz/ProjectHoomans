-- Context gates for static suggestion definitions.

local function hostileActor(actor)
    local roles = type(actor.roles) == "table" and actor.roles or {}
    local relationship = type(actor.relationship) == "table"
        and actor.relationship or {}
    local state = string.lower(tostring(relationship.state or ""))
    local role = string.lower(tostring(roles.role or ""))
    return roles.hostile == true or role == "enemy"
        or state == "enemy" or state == "rival"
end

local function ownedCompanion(actor)
    local roles = type(actor.roles) == "table" and actor.roles or {}
    return roles.companion == true and roles.owned == true
        and roles.authorityEligible == true
end

local function hasSafeGossip(context)
    local gossip = type(context.npcGossip) == "table"
        and context.npcGossip or nil
    if not gossip then
        local cognitionClient = PNC.Semantics.CognitionClient
        local npcID = tostring(context.npcID or "")
        if cognitionClient
            and type(cognitionClient.GetGossipContext) == "function"
            and npcID ~= ""
        then
            local ok, value = pcall(
                cognitionClient.GetGossipContext, npcID, "self"
            )
            if ok and type(value) == "table" then gossip = value end
        end
    end
    if not gossip or gossip.private == true or gossip.secret == true then
        return false
    end
    local visibility = string.lower(tostring(
        gossip.visibility or gossip.privacy or ""
    ))
    if visibility == "private" or visibility == "secret" then return false end
    local statements = type(gossip.statements) == "table"
        and gossip.statements or {}
    for index = 1, math.min(#statements, 4) do
        if type(statements[index]) == "string"
            and statements[index] ~= ""
        then
            return true
        end
    end
    return false
end

return {
    hostileActor = hostileActor,
    ownedCompanion = ownedCompanion,
    hasSafeGossip = hasSafeGossip,
}
