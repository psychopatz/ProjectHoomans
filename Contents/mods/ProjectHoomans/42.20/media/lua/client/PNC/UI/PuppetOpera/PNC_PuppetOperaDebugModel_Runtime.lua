-- Read-only runtime status and preflight access for the Puppet Opera model.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local Client = Internal.Client

function Model.RefreshPreflight(force)
    if not Client or not Client.Preflight then
        return false, "puppet_opera_preflight_unavailable"
    end
    local schemaOK, runtimeReason, normalized = Model.GetValidation()
    if not schemaOK then return false, runtimeReason end
    local bindings = Model.GetRuntimeActorBindings() or {}
    local key = Model.GetBlueprintID() .. ":"
        .. tostring(Model.GetChangeSerial())
    return Client.Preflight(
        Model.GetBlueprintID(),
        normalized,
        bindings,
        key,
        force == true
    )
end

function Model.GetPreflight()
    return Client and Client.GetPreflight and Client.GetPreflight() or nil
end

function Model.GetLiveActorReadiness(id)
    id = id and tostring(id) or nil
    if not id then return nil end
    local preflight = Model.GetPreflight()
    for actorID, readiness in pairs(preflight and preflight.actors or {}) do
        if readiness
            and ((readiness.kind == "local_player"
                and id == Internal.LIVE_PLAYER_ID)
                or tostring(readiness.bindingID or "") == id)
        then
            return readiness
        end
    end
    return nil
end

function Model.GetSnapshot()
    return Client and Client.GetSnapshot and Client.GetSnapshot() or nil
end

function Model.GetTrace()
    return Client and Client.GetTrace and Client.GetTrace() or {}
end

function Model.GetStatus()
    local status = "idle"
    local errorText = nil
    if Client and Client.GetStatus then status, errorText = Client.GetStatus() end
    return status, errorText or State.editorError
end

function Model.GetEditorStatus()
    return State.editorError
end

return Model
