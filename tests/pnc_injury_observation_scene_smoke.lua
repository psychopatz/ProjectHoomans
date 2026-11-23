local T = require "tests/support/test"
T.addPackagePaths()

isServer = function() return true end
isClient = function() return false end

local helper = { id = "medic", alive = true, runtime = {} }
local injured = { id = "injured", alive = true }
local px = 1
local player = { getX = function() return px end, getY = function() return 0 end, getZ = function() return 0 end }
local observerBody = { getX = function() return 0 end, getY = function() return 0 end, getZ = function() return 0 end }
local clock = 1000
local closed, opened, mutations, memories = 0, 0, 0, 0
local scene, activeBeat, handler
local available = true
local lastRole

PNC = {
    Core = { IsAuthority = function() return true end, Now = function() return clock end },
    Const = { CMD_SEMANTIC_INTERACTION_LIFECYCLE = "semantic_interaction_lifecycle" },
    ServerCommandRouter = { Register = function(_, value) handler = value end },
    Registry = { GetLiveZombie = function() return observerBody end, Get = function(id) if id == injured.id then return injured end if id == helper.id then return helper end end },
    Relationships = { ApplyConversationEffect = function(observer, target, effect)
        T.equal(observer, injured.id)
        T.equal(target, "npc:" .. helper.id)
        T.equal(effect.memoryType, "injury_aid_received")
        memories = memories + 1
    end },
    PlayerCharacters = { GetEntityKey = function(value) if value == player then return "player:local" end end },
    Conversation = {
        Authority = { Internal = { ValidateLease = function(_, _, token) return token == "approved" end } },
        InteractionLifecyclePersistence = { Project = function() return { thread = { activeBeat = activeBeat } } end },
    },
    Semantics = { CombatTargetCallouts = {
        HandoffInjuryBeatToScene = function(record, _, spec)
            T.equal(record, helper)
            T.equal(spec.participants[1], injured, "injured NPC joins the Scene")
            opened = opened + 1
            scene = { id = "triage-scene" }
            return scene
        end,
        ResolveSemanticLine = function(_, _, _, _, _, _, _, opts)
            lastRole = opts.replyRole
            return opts.replyRole
        end,
        DeliverBark = function(_, _, opts)
            T.truthy(opts.audienceFilter(player))
            T.falsy(opts.audienceFilter({}), "reply is private to the responding player")
            activeBeat = { eventRef = opts.eventRef, responsePlanID = opts.responsePlanID, offerIDs = opts.offerIDs, flowID = opts.flowID }
            return 1
        end,
    } },
}

package.loaded["PNC/ConvoEngine/Interaction/SceneRuntime"] = {
    Get = function() return scene end,
    Close = function() scene = nil; closed = closed + 1 end,
}
package.loaded["PNC/Semantics/PNC_SemanticInjuryAid"] = {
    Offer = function(_, _, opts)
        T.equal(opts.action, "transfer_bandage")
        if available then return { action = "bandage_transfer", partID = "UpperLeg_R" } end
        return nil, "missing_bandage", { reason = "missing_bandage" }
    end,
    Execute = function(a, b, offer)
        T.equal(a, helper)
        T.equal(b, injured)
        T.equal(offer.action, "bandage_transfer")
        mutations = mutations + 1
        return true
    end,
}

local Offers = require "PNC/ConvoEngine/Dialogue/InjuryTriageOffers"
local Observation = require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_ObservationScene"
require "PNC/Networking/Handlers/PNC_ServerSemanticInteractionLifecycleCommandHandler"

local function start()
    Observation.Bind(helper, injured, "visible-injury:" .. tostring(clock), "UpperLeg_R", clock)
    activeBeat = {
        eventRef = helper.runtime.activeInjuryObservation.ref, flowID = Offers.FLOW_ID,
        responsePlanID = Offers.PlanID(Offers.INITIAL_NODE), offerIDs = Offers.IDs(Offers.INITIAL_NODE),
    }
end

local function choose(action, token, eventRef)
    return handler(player, {
        requestID = "a-turn-" .. tostring(clock), npcID = helper.id, token = token or "approved",
        interaction = { act = "INFORM", topic = "combat_injury", offerID = "combat.injury." .. action,
            offerEventRef = eventRef or (activeBeat and activeBeat.eventRef) },
    })
end

start()
T.equal(#activeBeat.offerIDs, 5, "initial observation uses five authored reply offers")
T.equal(choose("observation_accept_aid").accepted, false, "accept must belong to active response plan")
T.equal(choose("observation_no_dressing", "forged").accepted, false, "server lease checked before admission")
T.equal(choose("observation_no_dressing").accepted, true)
T.equal(lastRole, "aid_supply_offer")
T.equal(opened, 1)
T.equal(mutations, 0, "offer has no gameplay effect")
T.equal(#activeBeat.offerIDs, 3, "confirmation and two declines come from the second authored node")
clock = 1200
T.equal(choose("observation_accept_aid").accepted, true)
T.equal(lastRole, "aid_taken")
T.equal(mutations, 1)
T.equal(closed, 0, "completed aid opens bounded follow-up replies")
T.equal(memories, 1, "committed aid records one directed relationship consequence")
T.equal(#activeBeat.offerIDs, 3)
T.equal(choose("observation_accept_aid").accepted, false, "consumed offer cannot replay")
T.equal(choose("observation_thanks").accepted, true)
T.equal(lastRole, "aid_gratitude")
T.equal(closed, 1)
T.equal(memories, 1, "gratitude does not create a second gameplay memory")

clock, available = 1500, false
start()
T.equal(choose("observation_no_dressing").accepted, true)
T.equal(lastRole, "aid_no_supply")
T.equal(mutations, 1, "missing inventory never dispatches a transfer")
T.equal(closed, 2)
T.equal(memories, 1, "ordinary no-supply response has no durable memory")

clock, px = 1600, 13
start()
T.equal(choose("observation_known", "").accepted, false, "ambient replies validate current player distance")
px = 1
T.equal(choose("observation_known", "", "other-beat").accepted, false, "ambient reply must name its own current Beat")
T.equal(choose("observation_known", "").accepted, true, "a nearby player can answer the server-admitted ambient Beat")
