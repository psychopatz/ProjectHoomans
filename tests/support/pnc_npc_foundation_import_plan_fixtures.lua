local T = require "tests/support/test"

local ImportPlan = PNC.Persistence.ImportPlan
local Fixtures = {}

local function newRecord(id)
    return PNC.Types.NewRecord({
        id = id,
        displayName = "Parity Merchant",
        identitySeed = 731,
        archetypeID = "parity_merchant",
        uniqueDefinitionVersion = 1,
        tacticalClass = "neutral",
        x = 104.5,
        y = 208.25,
        z = 0,
        anchorX = 100,
        anchorY = 200,
        anchorZ = 0,
        equipment = { worn = {}, attached = {} },
    })
end

function Fixtures.EqualValue(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    if left == right then return true end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then return true end
    seen[left][right] = true
    for key, value in pairs(left) do
        if not Fixtures.EqualValue(value, right[key], seen) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

function Fixtures.HasDecision(plan, field, action, reason)
    local i
    for i = 1, #(plan.decisions or {}) do
        local decision = plan.decisions[i]
        if decision.field == field and decision.action == action
            and (reason == nil or decision.reason == reason)
        then
            return true
        end
    end
    return false
end

function Fixtures.PrepareSourceRecord(id, emptyInventory)
    local record = newRecord(id)
    record.appearance = PNC.Identity.Appearance.Normalize({
        schemaVersion = 2,
        outfit = { mode = "none" },
        slots = {
            Torso_Upper = {
                mode = "item",
                type = "Base.Jacket",
                wornSlot = "Torso_Upper",
                itemState = { modData = { source = "p0b-plan" } },
            },
        },
    })
    T.truthy(PNC.Inventory.CreateFromTemplate(record),
        "source inventory template creation")
    if emptyInventory then
        record.inventory.items = {}
        record.inventory.worn = {}
        record.inventory.equipped = {}
        record.inventory.attached = {}
    end
    record.inventory.template.definitionRevision =
        record.uniqueDefinitionVersion
    return record
end

function Fixtures.PrepareContinuitySourceRecord(id)
    local record = Fixtures.PrepareSourceRecord(id, true)
    local targetKey = "npc:p0b_friend"
    local relationship = PNC.RelationshipTypes.NewRelationship(targetKey)
    relationship.memories = {
        PNC.RelationshipTypes.NewMemory({
            id = "memory:p0b:friend",
            type = "trade_helped",
            aboutKey = targetKey,
            createdAt = 14,
            lastEvaluatedAt = 14,
            approvalEffect = 11,
            respectEffect = 7,
            strength = 1,
            knowledgeSource = "experienced",
        }),
    }
    record.social.relationships[targetKey] = relationship
    record.social.revision = 3
    record.travel = PNC.Travel.Model.New(record, {
        journeyId = "journey:p0b:plan",
        origin = { x = record.x, y = record.y, z = record.z },
        destination = { x = 120, y = 220, z = 0 },
        metadata = { source = "p0b", opaque = { token = "retain" } },
        arrivalAction = { type = "roam" },
    }, 12)
    return record, targetKey
end

function Fixtures.CandidateCodec()
    local wire = {}
    return {
        serialize = function(candidate)
            local encoded = ImportPlan.Canonical(candidate)
            wire[encoded] = ImportPlan.Copy(candidate)
            return encoded
        end,
        deserialize = function(encoded)
            return ImportPlan.Copy(wire[encoded])
        end,
    }
end

return Fixtures
