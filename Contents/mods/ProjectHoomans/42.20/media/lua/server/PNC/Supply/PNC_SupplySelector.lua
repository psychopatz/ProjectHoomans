if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.SupplySelector = PNC.SupplySelector or {}

local Selector = PNC.SupplySelector
local Utility = PNC.ItemUtility
local Index = PNC.SupplyIndex
local Metrics = PNC.SupplyMetrics
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"

local function requiredAmount(request)
    if request.resourceKind == "FOOD" then
        return math.max(0.001, tonumber(request.required.hunger) or 0.001)
    end
    if request.resourceKind == "HYDRATION" then
        return math.max(0.001, tonumber(request.required.thirst) or 0.001)
    end
    return math.max(1, tonumber(request.required.count) or 1)
end

function Selector.Score(descriptor, request, remaining)
    if not Utility.Supports(descriptor, request) then return nil end
    if request.resourceKind == "FOOD" then
        local usefulHunger = math.min(remaining, descriptor.hunger)
        local usefulThirst = math.min(
            tonumber(request.required.thirst) or 0,
            descriptor.thirst
        )
        local waste = math.max(0, descriptor.hunger - remaining)
        return usefulHunger * 4 + usefulThirst * 2
            + descriptor.expiry * 8 - waste - descriptor.negativeThirst * 3
            - (descriptor.burnt and 12 or 0)
    end
    if request.resourceKind == "HYDRATION" then
        local total = descriptor.thirst * math.max(1, descriptor.remainingUses)
        return math.min(remaining, total) * 5
            - math.max(0, total - remaining) * 0.15
    end
    if request.resourceKind == "MEDICAL" then return 100 end
    return nil
end

local function exactQuery(record)
    local key = ItemRecord.stackKey(record)
    local canonical = not key and Util.canonical(record) or nil
    return {
        typeId = record[C.TYPE_ID],
        predicate = function(candidate)
            if key then return ItemRecord.stackKey(candidate) == key end
            return Util.canonical(candidate) == canonical
        end,
    }
end

function Selector.SelectFromStorage(storage, request)
    Metrics.Increment("candidateQueries")
    local candidates = Index.Query(storage, request)
    local limit = math.max(1, tonumber(PNC.NeedsDefinitions
        and PNC.NeedsDefinitions.SUPPLY_MAX_CANDIDATES) or 24)
    local scored = {}
    local remaining = requiredAmount(request)
    for index = 1, math.min(#candidates, limit) do
        local entry = candidates[index]
        local descriptor = Utility.DescribeCoreRecord(entry.record)
        Metrics.Increment("candidateItemsEvaluated")
        local score = Selector.Score(descriptor, request, remaining)
        if score then
            scored[#scored + 1] = {
                entry = entry,
                descriptor = descriptor,
                score = score,
            }
        end
    end
    table.sort(scored, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.descriptor.expiry ~= right.descriptor.expiry then
            return left.descriptor.expiry > right.descriptor.expiry
        end
        return left.descriptor.fullType < right.descriptor.fullType
    end)
    local selected = {}
    local selectedUnits = 0
    local maxSelections = math.max(1, math.floor(tonumber(
        request.selectionLimit) or tonumber(PNC.NeedsDefinitions
            and PNC.NeedsDefinitions.SUPPLY_MAX_SELECTIONS) or 3))
    for index = 1, #scored do
        if selectedUnits >= maxSelections or remaining <= 0 then break end
        local candidate = scored[index]
        local contribution = request.resourceKind == "FOOD"
            and candidate.descriptor.hunger
            or request.resourceKind == "HYDRATION"
                and candidate.descriptor.thirst
                    * math.max(1, candidate.descriptor.remainingUses)
                or 1
        local available = math.max(0,
            storage.inventory:count(exactQuery(candidate.entry.record), false))
        local quantity = math.min(available,
            math.max(1, math.ceil(
                remaining / math.max(0.001, contribution)
            )))
        quantity = math.min(quantity, maxSelections - selectedUnits)
        if quantity > 0 then
            selected[#selected + 1] = {
                record = candidate.entry.record,
                query = exactQuery(candidate.entry.record),
                quantity = quantity,
                descriptor = candidate.descriptor,
                score = candidate.score,
            }
            selectedUnits = selectedUnits + quantity
            remaining = remaining - contribution * quantity
        end
    end
    return selected, #candidates, scored
end

return Selector
