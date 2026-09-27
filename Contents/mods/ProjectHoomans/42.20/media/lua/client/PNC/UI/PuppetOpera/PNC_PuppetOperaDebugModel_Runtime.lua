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

local function preflightActorRows(preflight)
    local rows = {}
    if Model.GetActorRows then
        local projected = Model.GetActorRows(Model.GetSnapshot())
        for _, row in ipairs(projected or {}) do
            rows[#rows + 1] = row
        end
    end
    if #rows == 0 then
        for actorID in pairs(preflight and preflight.actors or {}) do
            rows[#rows + 1] = { id = actorID, label = actorID }
        end
        table.sort(rows, function(left, right)
            return tostring(left.id) < tostring(right.id)
        end)
    end
    return rows
end

-- Return the latest server admission result in a form the debug window can
-- act on without guessing from the rendered status text.  A nil readiness is
-- deliberately distinct from false: the request may still be in flight.
function Model.GetPreflightReadiness()
    local status = Client and Client.GetStatus and Client.GetStatus() or nil
    if status == "preflight" or status == "requesting" then
        return nil, "preflight_pending"
    end

    local preflight = Model.GetPreflight()
    if type(preflight) ~= "table" then
        return nil, "preflight_missing"
    end
    if preflight.ready == true then return true, "ready" end

    local rows = preflightActorRows(preflight)
    for _, row in ipairs(rows) do
        local actorID = tostring(row.id or "")
        local readiness = preflight.actors
            and preflight.actors[actorID] or nil
        if readiness and readiness.ready ~= true then
            local label = readiness.bindingID
                and (row.liveName or row.label)
                or row.label
                or actorID
            return false,
                tostring(readiness.reasonDetail
                    or readiness.reason
                    or preflight.reason
                    or "preflight_blocked"),
                actorID,
                tostring(label or actorID)
        end
    end

    return false, tostring(preflight.reason or "preflight_blocked")
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
