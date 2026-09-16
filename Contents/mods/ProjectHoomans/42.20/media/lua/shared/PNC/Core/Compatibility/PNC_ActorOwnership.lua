-- Cross-mod actor ownership boundary.
--
-- Hoomans and other NPC/zombie mods operate on the same IsoZombie class.
-- Keep foreign ownership detection in one small module so behavior lanes can
-- opt out without importing another mod's implementation details.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ActorOwnership =
    PNC.Compatibility.ActorOwnership or {}

local ActorOwnership = PNC.Compatibility.ActorOwnership
local Core = PNC.Core
local foreignPredicates = ActorOwnership.ForeignPredicates
    or {}
local adapters = ActorOwnership.Adapters or {}

ActorOwnership.ForeignPredicates = foreignPredicates
ActorOwnership.Adapters = adapters

local function modDataOf(body)
    return body and body.getModData and body:getModData() or nil
end

local function variableBoolean(body, name)
    if not body or not body.getVariableBoolean then
        return false
    end
    return body:getVariableBoolean(name) == true
end

function ActorOwnership.ReadVariableBoolean(body, name)
    return variableBoolean(body, name)
end

function ActorOwnership.IsHoomansOwned(body)
    if not body then return false end
    if Core and Core.IsManagedNPCBody
        and Core.IsManagedNPCBody(body) == true
    then
        return true
    end
    local modData = modDataOf(body)
    return modData and modData.PNC_Owner == "ProjectHoomans"
        or false
end

function ActorOwnership.MarkHoomansOwned(body)
    local modData
    if not body or not body.getModData then
        return false
    end
    modData = body:getModData()
    if not modData then return false end
    modData.PNC_Owner = "ProjectHoomans"
    modData.PNC_OwnerVersion = 1
    return true
end

function ActorOwnership.RegisterForeignOwner(name, predicate)
    if name == nil or type(predicate) ~= "function" then
        return false
    end
    foreignPredicates[tostring(name)] = predicate
    return true
end

function ActorOwnership.RegisterAdapter(specification)
    local id
    local api = PNC.Compatibility.API
    if type(specification) ~= "table"
        or specification.id == nil
        or type(specification.detect) ~= "function"
    then
        return false
    end
    id = tostring(specification.id)
    if api and api.RegisterAdapter
        and api.RegisterAdapter(specification) ~= true
    then
        return false
    end
    adapters[id] = specification
    return ActorOwnership.RegisterForeignOwner(id, specification.detect)
end

function ActorOwnership.GetAdapter(name)
    local api = PNC.Compatibility.API
    return api and api.GetAdapter
        and api.GetAdapter(name)
        or adapters[tostring(name or "")]
end

function ActorOwnership.IsForeignOwner(name, body)
    local predicate = foreignPredicates[tostring(name or "")]
    return predicate and predicate(body) == true or false
end

function ActorOwnership.GetForeignOwner(body)
    local name
    local predicate
    local ok
    local owned
    if not body or ActorOwnership.IsHoomansOwned(body) then
        return nil
    end
    for name, predicate in pairs(foreignPredicates) do
        -- Adapter predicates are addon-owned code. Keep a broken optional
        -- integration from taking down Hoomans' zombie update loop.
        ok, owned = pcall(predicate, body)
        if ok and owned == true then
            return name
        end
    end
    return nil
end

function ActorOwnership.IsForeignOwned(body)
    return ActorOwnership.GetForeignOwner(body) ~= nil
end

function ActorOwnership.IsBanditOwned(body)
    return ActorOwnership.IsForeignOwner("Bandits", body)
end

function ActorOwnership.ShouldHoomansIgnore(body)
    return ActorOwnership.IsHoomansOwned(body)
        or ActorOwnership.IsForeignOwned(body)
end

return ActorOwnership
