-- Projects the existing generated triage-flow offers for the observation Beat and Scene.
local Offers = {
    FLOW_ID = "combat.injury.triage_exchange",
    INITIAL_NODE = "observation_reply",
    SUPPLY_NODE = "observation_supply",
    FOLLOWUP_NODE = "observation_followup",
}
local PLAN_PREFIX = "semantic.flow.combat.injury.triage."
local nodes

function Offers.PlanID(node)
    return PLAN_PREFIX .. node
end

local function offersForNode(node)
    if not nodes then
        for _, flow in ipairs(require "PNC/ConvoEngine/Flows/Dialogue/CombatWoundCallouts") do
            if flow.id == Offers.FLOW_ID then nodes = flow.nodes; break end
        end
        nodes = nodes or {}
    end
    return nodes[node] and nodes[node].branchOffers or {}
end

function Offers.ForPlan(plan)
    if plan == Offers.PlanID(Offers.INITIAL_NODE) then return offersForNode(Offers.INITIAL_NODE) end
    if plan == Offers.PlanID(Offers.SUPPLY_NODE) then return offersForNode(Offers.SUPPLY_NODE) end
    if plan == Offers.PlanID(Offers.FOLLOWUP_NODE) then return offersForNode(Offers.FOLLOWUP_NODE) end
    return {}
end

function Offers.IDs(node)
    local output = {}
    for i, offer in ipairs(offersForNode(node)) do output[i] = offer.id end
    return output
end

function Offers.Resolve(plan, offerID)
    for _, offer in ipairs(Offers.ForPlan(plan)) do
        if offer.id == offerID then return offer end
    end
end

return Offers
