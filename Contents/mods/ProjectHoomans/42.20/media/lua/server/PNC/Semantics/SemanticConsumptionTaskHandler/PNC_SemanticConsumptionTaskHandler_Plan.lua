-- Ordered plan composition for semantic consumption tasks.
-- Providers own selection, movement, and authoritative effects.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Handler = PNC.Semantics.ConsumptionTaskHandler
local Internal = Handler.Internal
local Plans = PNC.Semantics.ActionPlanService

local function buildPlan(request, context)
    local action = Internal.Normalized(request and request.action)
    local npcID = Internal.NPCIDFor(request, context)
    local object
    local objectReason
    local capability
    local requestID
    local resourceKind
    local plan
    if not Internal.Actions[action] then
        return nil, "consumption_action_invalid"
    end
    if not npcID then return nil, "npc_required" end
    object, objectReason, capability = Internal.ObjectFor(request, action)
    if not object then return nil, objectReason end
    requestID = Internal.RequestIDFor(request, npcID)
    resourceKind = Internal.ResourceKindFor(action, object)
    plan = {
        planID = "semantic:" .. string.lower(action) .. ":"
            .. Internal.SafePart(npcID) .. ":"
            .. Internal.SafePart(requestID),
        npcID = npcID,
        requestID = requestID,
        source = request.source or "semantic_dialogue",
        confidence = request.confidence,
        rawText = request.rawText,
        provenance = request.provenance,
        -- A semantic REFILL is an explicit player/dialogue command, not an
        -- autonomous need decision. Carry that authority through the queued
        -- plan so it remains a manual override at delayed commit time.
        manualOverride = action == "REFILL",
        metadata = {
            taskAction = action,
            resourceKind = resourceKind,
            objectText = Internal.Text(object.text or object.value),
        },
        steps = {},
    }
    plan.steps[#plan.steps + 1] = {
        id = "select_item",
        action = "SELECT_ITEM",
        parameters = {
            object = object,
            quantity = 1,
            capability = capability,
            resourceKind = resourceKind,
            required = Internal.RequiredFor(request),
        },
    }
    if action == "REFILL" then
        plan.steps[#plan.steps + 1] = {
            id = "move_to_water_source",
            action = "MOVE_TO",
            parameters = {
                target = {
                    kind = "water_fill_source",
                    mode = "walk",
                    stopDistance = 1.25,
                },
            },
        }
        plan.steps[#plan.steps + 1] = {
            id = "refill_item",
            action = "REFILL_ITEM",
            parameters = {
                object = object,
                quantity = 1,
                capability = capability,
            },
        }
    else
        plan.steps[#plan.steps + 1] = {
            id = "consume_item",
            action = "CONSUME_ITEM",
            parameters = {
                object = object,
                quantity = 1,
                capability = capability,
                resourceKind = resourceKind,
                required = Internal.RequiredFor(request),
            },
        }
    end
    return plan
end

function Handler.BuildPlan(request, context)
    return buildPlan(request, context)
end

function Handler.Validate(request, context)
    local action = Internal.Normalized(request and request.action)
    local _, reason = Internal.ObjectFor(request, action)
    if not request or request.intent ~= "REQUEST"
        or not Internal.Actions[action]
    then
        return false, "consumption_request_invalid"
    end
    if reason then return false, reason end
    if not Internal.NPCIDFor(request, context) then
        return false, "npc_required"
    end
    return true
end

function Handler.Submit(request, context)
    local plan, reason = buildPlan(request, context)
    local accepted
    local submitted
    local submitDetails
    if not plan then return false, reason end
    accepted, submitted, submitDetails = Plans.Submit(plan, context)
    if accepted ~= true then return false, submitted, submitDetails end
    return {
        accepted = true,
        status = "accepted",
        action = request.action,
        planID = submitted.planID,
        npcID = submitted.npcID,
        plan = Plans.Get(submitted.npcID),
    }
end

return Handler
