local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

local calls = {}
PNC = { Client = {
    RequestColonyAction = function(action, options)
        calls[#calls + 1] = { action = action, options = options }
        return true, "sent"
    end,
} }

local Actions = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingQueueActions.lua")
local order = { id = "work:queue-action", status = "BLOCKED" }
local window = { snapshot = { building = { queue = { order } } } }

T.truthy(Actions.RequestCancel(window, order),
    "building cancellation request was not sent")
T.equal(calls[1].action, "work_cancel",
    "building cancellation used the wrong action")
T.equal(calls[1].options.requestId, order.id,
    "building cancellation did not preserve the work identity")
T.falsy(Actions.CanCancel(window, order),
    "pending building cancellation remained clickable")
T.equal(Actions.ActionLabel(window, order), "CANCELLING...",
    "pending building cancellation did not expose its state")

window.snapshot.actionResult = {
    action = "work_cancel", requestId = order.id,
    ok = false, reason = "CLEANUP_FAILED",
}
Actions.Reconcile(window, window.snapshot, { order })
T.truthy(Actions.CanCancel(window, order),
    "failed building cancellation did not become retryable")
T.equal(Actions.ActionLabel(window, order), "RETRY CANCEL",
    "failed building cancellation did not expose retry feedback")

T.truthy(Actions.RequestCancel(window, order),
    "failed building cancellation could not be retried")
T.equal(Actions.ActionLabel(window, order), "CANCELLING...",
    "retry did not return the row to pending state")

T.finish("pnc_building_queue_actions_smoke")
