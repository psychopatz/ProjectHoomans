local T = require "tests/support/test"
T.addPackagePaths()

local now = 100
local record = {
    id = "npc:alice",
    alive = true,
    x = 0,
    y = 0,
    z = 0,
    inventory = {
        revision = 4,
        items = {
            ["item:apple:1"] = {
                id = "item:apple:1",
                type = "Base.Apple",
                stack = 2,
            },
        },
    },
}
local player = {
    x = 10,
    y = 0,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
}
local transferCalls = 0
local transferred

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
    IsAuthority = function() return true end,
}
PNC = {
    Core = {
        IsAuthority = function() return true end,
        Now = function() return now end,
    },
    Registry = {
        Get = function(id)
            return tostring(id or "") == record.id and record or nil
        end,
        GetLiveZombie = function() return nil end,
        ForEach = function(callback) callback(record) end,
        MarkDirty = function() end,
    },
    Inventory = {
        EnsureRecordInventory = function(owner)
            return owner.inventory
        end,
    },
    ServerInventory = {
        SemanticTransferNPCToPlayer = function(owner, npc, args)
            transferCalls = transferCalls + 1
            transferred = {
                player = owner,
                record = npc,
                args = args,
            }
            npc.inventory.items[args.itemIDs[1]] = nil
            npc.inventory.revision = npc.inventory.revision + 1
            return true, "transferred_to_player"
        end,
    },
    Conversation = {
        Authority = {
            Internal = {
                ValidateLease = function(owner, npc, token)
                    return owner == player and npc == record
                        and token == "lease:1", "conversation_authorized"
                end,
            },
        },
    },
    PathService = {
        AdvanceAbstract = function(owner, x, y, z, stopDistance)
            local dx = x - owner.x
            local dy = y - owner.y
            local distance = math.sqrt((dx * dx) + (dy * dy))
            if distance <= (stopDistance or 0.7) then
                owner.x, owner.y, owner.z = x, y, z
                return true
            end
            local step = math.min(5, distance)
            owner.x = owner.x + (dx / distance) * step
            owner.y = owner.y + (dy / distance) * step
            owner.z = z
            return false
        end,
    },
    Semantics = {},
}

MarketSense = {
    GetTags = function(fullType)
        T.equal(fullType, "Base.Apple", "MarketSense receives the full type")
        return {
            primary = "Apple",
            category = "Food",
            tags = { "fruit", "edible" },
            expandedTags = { "fresh_food" },
            themes = { "survival" },
        }
    end,
    GetItemCapabilities = function(fullType)
        T.equal(fullType, "Base.Apple",
            "capability lookup receives the full type")
        return {
            capabilities = { edible = true },
        }
    end,
}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTaskRequest.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticActionPlan.lua"
)
local Plans = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticActionPlanService.lua"
)
Plans.PUMP_INTERVAL_MS = 0
Plans.RECONCILE_INTERVAL_MS = 0
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticWorldTargetResolver.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/Inventory/PNC_SemanticItemSelector.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanPathProvider.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider.lua"
)
local Requests = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticTaskRequestService.lua"
)
local GiveItemHandler = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticGiveItemTaskHandler.lua"
)

local ir = Semantic.Parser.Parse("Can you give me an apple?")
T.equal(ir.intent, "REQUEST", "give item parses as a request")
T.equal(ir.action, "GIVE", "give item action is compositional")
T.equal(ir.object.text, "apple", "literal item name is preserved")
T.equal(ir.object.unresolved, true,
    "MarketSense-owned item vocabulary stays unresolved in core NLU")
T.truthy(ir.confidence >= 0.85,
    "safe item lookup remains high confidence")

local contextualGiveIR = Semantic.Parser.Parse("Give it to me")
T.equal(contextualGiveIR.action, "GIVE",
    "give-it-to-me parses into the existing GIVE task")
T.equal(contextualGiveIR.object.reference, "IT",
    "pronoun item requests remain context-resolved")
T.equal(contextualGiveIR.object.unresolved, true,
    "the new transfer wording cannot choose an item without context")

local decision = Policy.Decide(ir, nil, { llmEnabled = false }, {})
T.equal(decision.route, "deterministic",
    "item request remains local without an LLM")
T.equal(decision.actionIntent.action, "GIVE",
    "local policy exposes the item task")

local request = PNC.Semantics.TaskRequest.FromIR(ir, {
    requestID = "dialogue:give:1",
    rawText = ir.rawText,
    recipient = { id = record.id },
})
local result = Requests.Submit(request, {
    player = player,
    npcID = record.id,
    conversationToken = "lease:1",
})
T.equal(result.accepted, true, "give request creates an action plan")
local plan = Plans.GetMutable(record.id)
T.equal(plan.steps[1].action, "SELECT_ITEM",
    "selection is the first queued step")
T.equal(plan.steps[2].action, "MOVE_TO",
    "movement is queued after selection")
T.equal(plan.steps[3].action, "GIVE_ITEM",
    "authoritative handoff is queued last")

now = 101
Plans.Pump(now)
T.equal(plan.steps[1].state, "ASSIGNED",
    "MarketSense-backed selection resolves locally")
T.equal(plan.steps[1].assignment.itemID, "item:apple:1",
    "selection returns the authoritative compact item ID")
now = 102
Plans.Pump(now)
T.equal(plan.steps[2].state, "PENDING",
    "selection completes before movement begins")
now = 103
Plans.Pump(now)
now = 104
Plans.Pump(now)
now = 105
Plans.Pump(now)
T.equal(plan.steps[2].state, "TRAVEL",
    "NPC movement uses the existing path provider")
now = 106
Plans.Pump(now)
now = 107
Plans.Pump(now)
now = 108
Plans.Pump(now)
T.equal(plan.steps[2].state, "ARRIVED",
    "NPC reaches the live player target")
now = 109
Plans.Pump(now)
now = 110
Plans.Pump(now)
now = 111
Plans.Pump(now)
T.equal(plan.steps[3].state, "ASSIGNED",
    "final item selection is revalidated at execution")
now = 112
Plans.Pump(now)
T.equal(plan.state, "COMPLETED",
    "item handoff completes after movement")
T.equal(transferCalls, 1,
    "only the authoritative inventory adapter mutates the handoff")
T.equal(transferred.args.itemIDs[1], "item:apple:1",
    "final transfer uses the selected item ID")
T.equal(transferred.args.inventoryRevision, 4,
    "final transfer carries the checked inventory revision")
T.equal(transferred.args.conversationToken, "lease:1",
    "final transfer carries the conversation authority token")

record.inventory.items["item:apple:2"] = {
    id = "item:apple:2",
    type = "Base.Apple",
    stack = 1,
}
record.inventory.revision = record.inventory.revision + 1

local fetchIR = Semantic.Parser.Parse("Fetch me an apple")
T.equal(fetchIR.intent, "REQUEST", "fetch item parses as a request")
T.equal(fetchIR.action, "FETCH", "fetch is a compositional item action")
T.equal(fetchIR.object.text, "apple", "fetch preserves the requested item")
local fetchDecision = Policy.Decide(
    fetchIR, nil, { llmEnabled = false }, {})
T.equal(fetchDecision.route, "deterministic",
    "fetch remains local when the LLM is disabled")
T.equal(fetchDecision.actionIntent.action, "FETCH",
    "local policy exposes the fetch task")

local fetchRequest = PNC.Semantics.TaskRequest.FromIR(fetchIR, {
    requestID = "dialogue:fetch:1",
    rawText = fetchIR.rawText,
    recipient = { id = record.id },
})
local fetchResult = Requests.Submit(fetchRequest, {
    player = player,
    npcID = record.id,
    conversationToken = "lease:1",
})
T.equal(fetchResult.accepted, true,
    "fetch request reuses the existing item handoff task")
local fetchPlan = Plans.GetMutable(record.id)
T.equal(string.sub(fetchPlan.planID, 1, 15), "semantic:fetch:",
    "fetch plans retain their task identity")
T.equal(fetchPlan.metadata.taskAction, "FETCH",
    "fetch task action survives into result presentation")
T.equal(fetchPlan.steps[1].action, "SELECT_ITEM",
    "fetch selects from the NPC's carried items")
T.equal(fetchPlan.steps[2].action, "MOVE_TO",
    "fetch moves to the speaking player")
T.equal(fetchPlan.steps[3].action, "GIVE_ITEM",
    "fetch uses the existing authoritative handoff step")

for _ = 1, 20 do
    if fetchPlan.state == "COMPLETED" then break end
    now = now + 1
    Plans.Pump(now)
end
T.equal(fetchPlan.state, "COMPLETED",
    "fetch completes through the existing action plan")
T.equal(transferCalls, 2,
    "fetch reaches the authoritative inventory transfer once")
T.equal(transferred.args.itemIDs[1], "item:apple:2",
    "fetch transfers the selected carried item")
T.equal(transferred.args.inventoryRevision, 6,
    "fetch revalidates the current inventory revision")
T.equal(transferred.args.conversationToken, "lease:1",
    "fetch preserves conversation authority at handoff")

local sourceIR = Semantic.Parser.Parse("Fetch an apple from the locker")
T.equal(sourceIR.action, "FETCH",
    "fetch with a source still reaches semantic task validation")
local sourceRequest = PNC.Semantics.TaskRequest.FromIR(sourceIR, {
    requestID = "dialogue:fetch:source",
    rawText = sourceIR.rawText,
    recipient = { id = record.id },
})
local sourceResult = Requests.Submit(sourceRequest, {
    player = player,
    npcID = record.id,
    conversationToken = "lease:1",
})
T.equal(sourceResult.accepted, false,
    "fetch from an unsupported container is rejected")
T.equal(sourceResult.reason, "fetch_source_unsupported",
    "unsupported fetch source has a stable reason")
T.equal(Plans.GetMutable(record.id).planID, fetchPlan.planID,
    "rejected source does not replace the existing plan")
sourceRequest.sourceEntity = nil
sourceRequest.requestID = "dialogue:fetch:source-text-only"
local rawSourceResult = Requests.Submit(sourceRequest, {
    player = player,
    npcID = record.id,
    conversationToken = "lease:1",
})
T.equal(rawSourceResult.reason, "fetch_source_unsupported",
    "explicit source text is rejected if a pattern loses its source capture")

local destinationIR = Semantic.Parser.Parse("Fetch an apple to Sarah")
T.equal(destinationIR.action, "FETCH",
    "fetch to a named recipient reaches semantic task validation")
local destinationRequest = PNC.Semantics.TaskRequest.FromIR(destinationIR, {
    requestID = "dialogue:fetch:destination",
    rawText = destinationIR.rawText,
    recipient = { id = record.id },
})
local destinationResult = Requests.Submit(destinationRequest, {
    player = player,
    npcID = record.id,
    conversationToken = "lease:1",
})
T.equal(destinationResult.accepted, false,
    "fetch to another named recipient is rejected")
T.equal(destinationResult.reason, "fetch_destination_unsupported",
    "unsupported fetch destination has a stable reason")
T.equal(Plans.GetMutable(record.id).planID, fetchPlan.planID,
    "rejected destination does not replace the existing plan")
destinationRequest.target = nil
destinationRequest.requestID = "dialogue:fetch:destination-text-only"
local rawDestinationResult = Requests.Submit(destinationRequest, {
    player = player,
    npcID = record.id,
    conversationToken = "lease:1",
})
T.equal(rawDestinationResult.reason, "fetch_destination_unsupported",
    "explicit destination text is rejected if a pattern loses its target capture")

local speakerDestinationIR = Semantic.Parser.Parse("Fetch an apple to me")
local speakerDestinationRequest = PNC.Semantics.TaskRequest.FromIR(
    speakerDestinationIR, {
        requestID = "dialogue:fetch:speaker-destination",
        rawText = speakerDestinationIR.rawText,
        recipient = { id = record.id },
    })
local validSpeakerDestination = GiveItemHandler.Validate(
    speakerDestinationRequest, { npcID = record.id })
T.equal(validSpeakerDestination, true,
    "explicit current-player destination remains supported")

T.finish("pnc_semantic_give_item_smoke")
