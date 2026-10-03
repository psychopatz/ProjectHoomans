-- Corpse haul dispatch composition and terminal-order cleanup.
--
-- Automatic assignment and manual requests are loaded in dependency order;
-- terminal pruning remains here because it coordinates durable cleanup and
-- work-claim release.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository

require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_Dispatch_Assignment"
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_Dispatch_Manual"

local function pruneTerminalCorpseOrders()
    local remove = {}
    if not WorkRepository or not WorkRepository.Load
        or not WorkRepository.Remove
    then return 0 end
    WorkRepository.Load()
    for id, order in pairs(WorkRepository.State.byId or {}) do
        if order and order.operation == "CORPSE_HAUL"
            and Internal.terminalWorkOrder(order)
        then
            remove[#remove + 1] = tostring(id)
        end
    end
    for _, id in ipairs(remove) do
        local order = WorkRepository.State.byId[id]
        if order then
            -- Terminal orders normally pass through WorkService.releaseClaim,
            -- but pruning is also a recovery path. Clear live state while the
            -- order still identifies its worker, then release the persisted
            -- projection so the NPC cannot retain a production_work spec or
            -- native movement ownership.
            Internal.clearWorkRuntime(order, "terminal_corpse_order_pruned")
            if Work and Work.Internal and Work.Internal.releaseClaim then
                Work.Internal.releaseClaim(
                    order,
                    "terminal_corpse_order_pruned",
                    false,
                    false
                )
            end
            WorkRepository.Remove(id)
        end
    end
    return #remove
end

Internal.pruneTerminalCorpseOrders = pruneTerminalCorpseOrders

return Service
