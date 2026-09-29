-- A player-funded (bootstrap) build removes materials from the survivor's own
-- inventory before the work order exists. If the queue rejects the order the
-- materials must come back; otherwise a failed build silently costs items.
local T = require "tests/support/test"

T.addPackagePaths()

local consumeCalls = {}
local rollbackCalls = {}
local queueResult = { nil, "UNKNOWN_OPERATION" }
local queueSpecs = {}
local facility = { id = "facility:1" }

PNC = {
    ConstructionService = { Internal = {} },
    FacilityCostService = {
        ConsumePlayer = function(player, definition, options)
            consumeCalls[#consumeCalls + 1] = {
                player = player, definition = definition, options = options,
            }
            return true, { affordable = true, receipts = { { id = "r1" } },
                reason = "consumed" }
        end,
        Rollback = function(quote)
            rollbackCalls[#rollbackCalls + 1] = quote
            return true
        end,
    },
    WorkService = {
        Commands = {
            Queue = function(spec)
                queueSpecs[#queueSpecs + 1] = spec
                return queueResult[1], queueResult[2]
            end,
        },
    },
    FacilityService = { RefreshState = function() end },
}

local definition = { id = "stockpile", bootstrapFromPlayer = true,
    buildCosts = { { fullType = "Base.Plank", amount = 4 } }, buildWork = 10 }
local player = { getOnlineID = function() return 7 end,
    getUsername = function() return "survivor" end }
local context = { colony = { id = "colony:1" }, faction = { id = "faction:1" },
    base = { id = "base:1" } }

PNC.ConstructionService.Internal.ContextFor = function()
    return context
end
PNC.ConstructionService.Internal.RecipeRevisionFor = function() return 3 end

local Service = T.load("ProjectHoomans", "server",
    "PNC/Production/ConstructionService/ConstructionService_Queueing/"
        .. "PNC_ConstructionService_Queueing_Build.lua")

-- Rejected queue: materials are restored and the failure is reported.
local order, reason = Service.QueueBuild(player, facility, definition)
T.falsy(order ~= nil, "rejected bootstrap build returned an order")
T.equal(reason, "UNKNOWN_OPERATION", "queue failure reason was not propagated")
T.equal(#rollbackCalls, 1, "rejected bootstrap build did not refund materials")
T.truthy(rollbackCalls[1] and rollbackCalls[1].receipts ~= nil,
    "refund ran without the consumption receipts")
T.equal(facility.constructionState, nil,
    "rejected bootstrap build was marked under construction")
T.equal(#consumeCalls, 1, "unexpected consumption count")
T.truthy(consumeCalls[1].options and consumeCalls[1].options.keepReceipts == true,
    "bootstrap consumption discarded its rollback receipts")
T.truthy(queueSpecs[1].payload.refund
    and queueSpecs[1].payload.refund.toPlayer == true,
    "bootstrap order did not record a player refund route")
T.equal(queueSpecs[1].payload.refund.username, "survivor",
    "bootstrap order lost the paying survivor")
T.equal(queueSpecs[1].payload.refund.onlineID, 7,
    "bootstrap order lost the paying survivor id")
T.equal(queueSpecs[1].payload.requirements, nil,
    "bootstrap order pinned empty requirements instead of the real costs")

-- Accepted queue: no refund, facility moves to construction.
queueResult = { { id = "order:1" }, nil }
order, reason = Service.QueueBuild(player, facility, definition)
T.truthy(order ~= nil, "accepted bootstrap build returned no order")
T.equal(#rollbackCalls, 1, "accepted bootstrap build refunded materials")
T.equal(facility.constructionState, "UNDER_CONSTRUCTION",
    "accepted bootstrap build was not marked under construction")
T.equal(facility.constructionWorkOrderId, "order:1",
    "accepted bootstrap build lost its work order id")

local refunds = T.read("ProjectHoomans", "server",
    "PNC/Production/ConstructionService/ConstructionService_Lifecycle/"
        .. "PNC_ConstructionService_Lifecycle_Refunds.lua")
T.contains(refunds, "Costs.RefundPlayer(player, refund.products)",
    "cancellation must return player-funded materials to the survivor")

T.finish("pnc_bootstrap_build_refund_smoke")
