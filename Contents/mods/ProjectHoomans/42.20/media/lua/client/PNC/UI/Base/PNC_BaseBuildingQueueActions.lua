local Actions = {}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key or value == "" then return fallback end
    return value
end

local function orderId(order)
    return tostring(order and order.id or "")
end

local function pendingFor(window)
    if not window then return {} end
    window.pncBuildingCancelPending =
        window.pncBuildingCancelPending or {}
    return window.pncBuildingCancelPending
end

local function resultFor(window, order)
    local result = window and window.snapshot
        and window.snapshot.actionResult or nil
    if result and result.action == "work_cancel"
        and tostring(result.requestId or "") == orderId(order)
    then
        return result
    end
    local failure = window and window.pncBuildingCancelFailure or nil
    if failure and tostring(failure.orderId or "") == orderId(order) then
        return { ok = false, reason = failure.reason }
    end
    if order and order.cancellationFailureReason then
        return { ok = false, reason = order.cancellationFailureReason }
    end
    return nil
end

function Actions.Reconcile(window, snapshot, queue)
    if not window then return end
    snapshot = snapshot or window.snapshot or {}
    window.snapshot = snapshot
    local pending = pendingFor(window)
    local result = snapshot.actionResult
    if result and result.action == "work_cancel" and result.requestId then
        local id = tostring(result.requestId)
        pending[id] = nil
        if result.ok == true then
            window.pncBuildingCancelFailure = nil
        else
            window.pncBuildingCancelFailure = {
                orderId = id, reason = result.reason,
            }
        end
    end
    local present = {}
    for _, order in ipairs(queue or {}) do
        local id = orderId(order)
        present[id] = order
        if order.status == "CANCELLED" then pending[id] = nil end
    end
    for id, _ in pairs(pending) do
        if not present[id] then pending[id] = nil end
    end
end

function Actions.CanCancel(window, order)
    if not order or not order.id then return false end
    local pending = pendingFor(window)
    if pending[orderId(order)] == true then return false end
    local result = resultFor(window, order)
    if result and result.ok == false then return true end
    return tostring(order.status or "") ~= "CANCELLING"
end

function Actions.RequestCancel(window, order)
    if not Actions.CanCancel(window, order) then
        return false, "WORK_ORDER_CANCELLING"
    end
    local id = orderId(order)
    local pending = pendingFor(window)
    window.pncBuildingCancelFailure = nil
    pending[id] = true
    local client = PNC and PNC.Client or nil
    local accepted, reason
    if client and client.RequestColonyAction then
        accepted, reason = client.RequestColonyAction("work_cancel", {
            requestId = id,
            workOrderId = id,
        })
    else
        accepted, reason = false, "CLIENT_UNAVAILABLE"
    end
    if accepted == false then
        pending[id] = nil
        window.pncBuildingCancelFailure = { orderId = id, reason = reason }
    end
    return accepted, reason
end

function Actions.ActionLabel(window, order)
    if pendingFor(window)[orderId(order)] == true then
        return tr("UI_PNC_Work_Cancelling", "CANCELLING...")
    end
    local result = resultFor(window, order)
    if result and result.ok == false then
        return tr("UI_PNC_Building_CancelRetry", "RETRY CANCEL")
    end
    if tostring(order and order.status or "") == "CANCELLING"
    then
        return tr("UI_PNC_Work_Cancelling", "CANCELLING...")
    end
    return tr("UI_PNC_Building_CancelOrder", "CANCEL ORDER")
end

return Actions
