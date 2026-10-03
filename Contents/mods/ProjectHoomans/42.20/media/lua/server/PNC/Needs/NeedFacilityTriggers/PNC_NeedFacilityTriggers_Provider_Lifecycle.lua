if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
local Internal = Triggers.Internal
local Definitions = PNC.NeedFacilityTriggerDefinitions
local AwayRoutes = PNC.NeedFacilityAwayRoutes
local HomeRoute = PNC.NeedFacilityHomeRoute

local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local TaskEvents = PNC.Tasking and PNC.Tasking.Events
local recordFor = Internal.RecordFor
local DRINK_RETRY_COOLDOWN_MS = 5000
local PERSONAL_FOOD_RETRY_COOLDOWN_MS = 5000

local function stop(lease, reason)
    local record = recordFor(lease.npcId)
    if record and record.runtime and record.runtime.facilityActivity
        and PNC.FacilityJobs and PNC.FacilityJobs.Stop
    then
        local stopped, stopReason = PNC.FacilityJobs.Stop(record, reason)
        return stopped == true, stopReason
    end
    return true
end

function Triggers.Cancel(lease, reason)
    return stop(lease, reason or "task_cancelled")
end

-- Reservationless drink activities are deliberately short-lived, but a
-- failed scene/path handoff must not be re-selected on the very next task
-- pump. Keep this backoff beside the need provider so tasking stays generic.
function Triggers.OnExecutorFailure(lease)
    local record = recordFor(lease and lease.npcId)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local resourceKind = tostring(activity and activity.resourceKind or "")
    local capability = tostring(activity and activity.capability or "")
    local now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    if resourceKind == "world_water" then
        runtime.worldWaterRetryAt = now + DRINK_RETRY_COOLDOWN_MS
    elseif resourceKind == "water_refill" then
        runtime.waterRefillRetryAt = now + DRINK_RETRY_COOLDOWN_MS
    elseif resourceKind == "personal_drink" then
        runtime.personalDrinkRetryAt = now + DRINK_RETRY_COOLDOWN_MS
    elseif resourceKind == "personal_food"
        or capability == "food.dine"
        or capability == "survival.eat.inventory"
    then
        runtime.personalFoodRetryAt = now + PERSONAL_FOOD_RETRY_COOLDOWN_MS
    end
end

function Triggers.Complete(lease)
    return stop(lease, "need_complete")
end

PNC.Tasking.Commands.RegisterProvider("NeedFacility", Triggers)

if PNC.IndividualNeeds and PNC.IndividualNeeds.RegisterListener then
    PNC.IndividualNeeds.RegisterListener("severity_changed",
        function(record, needType)
            for _, definition in ipairs(Definitions.List()) do
                if definition.needType == needType then
                    if TaskEvents and TaskEvents.Emit then
                        TaskEvents.Emit("NPC_NEEDS_CHANGED", {
                            npcId = record.id,
                            source = "IndividualNeeds",
                            entityId = needType,
                        })
                    end
                    return
                end
            end
        end)
end

-- Provision pickup changes the personal-supply candidates without changing
-- need severity. Wake tasking on that inventory event so a newly delivered
-- item is consumed immediately instead of waiting for NeedsScheduler.
local function onInventoryChanged(record)
    if record and TaskEvents and TaskEvents.Emit
    then
        TaskEvents.Emit("NPC_INVENTORY_CHANGED", {
            npcId = record.id, source = "InventoryEvent",
            entityId = record.id,
        })
    end
end

Events.subscribe(EventTypes.NPC_INVENTORY_CHANGED, onInventoryChanged, Triggers)

