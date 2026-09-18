-- Catalog filter state for the Puppet Opera model.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local touch = Internal.touch

function Model.GetPlayerSource()
    return State.playerSource
end

function Model.SetPlayerSource(source)
    if source == "zombie" then source = "bridge" end
    if source ~= "player" and source ~= "bridge" then return false end
    State.playerSource = source
    touch()
    return true
end

function Model.GetPlayerQuery()
    return State.playerQuery
end

function Model.SetPlayerQuery(query)
    State.playerQuery = tostring(query or "")
end

function Model.GetNPCQuery()
    return State.npcQuery
end

function Model.SetNPCQuery(query)
    State.npcQuery = tostring(query or "")
end

function Model.GetNPCState()
    return State.npcState
end

function Model.SetNPCState(state)
    State.npcState = state and tostring(state) or nil
    touch()
end

return Model
