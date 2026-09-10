local T = require "tests/support/test"
T.addPackagePaths()

local player = {}
local sent
local baseBuilds = 0
local fullBuilds = 0
local actionArgs

PNC = {
    Const = {
        CMD_COLONY_MANAGEMENT_REQUEST = "ColonyManagementRequest",
        CMD_COLONY_MANAGEMENT_ACTION = "ColonyManagementAction",
    },
    Network = {
        SendColonyManagement = function(receivedPlayer, snapshot, scope)
            sent = { player = receivedPlayer, snapshot = snapshot, scope = scope }
        end,
    },
    ColonyManagement = {
        BuildSnapshot = function()
            fullBuilds = fullBuilds + 1
            return { marker = "full" }
        end,
        BuildBaseSnapshot = function()
            baseBuilds = baseBuilds + 1
            return { marker = "base" }
        end,
        HandleAction = function(receivedPlayer, args)
            actionArgs = args
            return { marker = "base", settlement = {} }, {
                ok = true, action = args.action, requestId = args.requestId,
            }
        end,
    },
}

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerColonyManagementCommandHandler"

Router.Handle("ColonyManagementRequest", player, { snapshotScope = "base" })
T.equal(baseBuilds, 1, "base request did not use the compact builder")
T.equal(fullBuilds, 0, "base request also built the full snapshot")
T.equal(sent.scope, "base", "base response did not preserve its scope")
T.equal(sent.snapshot.marker, "base", "base response used the wrong projection")

Router.Handle("ColonyManagementRequest", player, {})
T.equal(fullBuilds, 1, "ordinary request stopped using the full builder")
T.equal(sent.scope, nil, "ordinary response leaked a base scope")

Router.Handle("ColonyManagementAction", player, {
    action = "base_create", snapshotScope = "base", requestId = "base-1",
})
T.equal(actionArgs.snapshotScope, "base",
    "base action lost its compact response scope")
T.equal(sent.scope, "base", "base action response lost its scope")
T.equal(sent.snapshot.actionResult.action, "base_create",
    "base action result was not attached to the compact response")

T.finish("pnc_colony_base_scope_smoke")
