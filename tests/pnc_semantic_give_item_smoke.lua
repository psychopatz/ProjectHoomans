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
T.load(
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

T.finish("pnc_semantic_give_item_smoke")
