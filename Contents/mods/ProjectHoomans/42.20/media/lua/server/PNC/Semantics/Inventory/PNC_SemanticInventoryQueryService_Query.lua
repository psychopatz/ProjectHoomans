-- Aggregates bounded item candidates into the stable query response shape.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Service = PNC.Semantics.InventoryQueryService
local Internal = Service.Internal
local Diagnostics = Internal.Diagnostics
local text = Internal.Text

local function traceQuery(record, query, status, reason, result, options)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    local semanticAudit = Diagnostics
        and type(Diagnostics.IsEnabled) == "function"
        and Diagnostics.IsEnabled() == true
    local legacyTrace = trace
        and type(trace.IsEnabled) == "function"
        and trace.IsEnabled() == true
        and type(trace.Record) == "function"
    if not semanticAudit and not legacyTrace
    then
        return result, reason
    end
    query = type(query) == "table" and query or {}
    local definition = {
        source = "ProjectHoomans.Semantics",
        event = "semantic.inventory.query",
        requestID = options and options.requestID or query.requestID,
        data = {
            npcID = record and (record.id or record.npcID),
            status = status,
            reason = reason,
            mode = query.mode,
            text = text(query.text, 96),
            concept = text(query.concept, 64),
            category = text(query.category, 64),
            totalCount = result and result.totalCount or 0,
            distinctItems = result and result.distinctItems or 0,
            inventoryRevision = result and result.inventoryRevision,
            items = result and result.items,
        },
    }
    if semanticAudit then
        Diagnostics.Record(
            "semantic.inventory.query",
            definition.data,
            { requestID = options and options.requestID or query.requestID }
        )
    else
        trace.Record(definition)
    end
    return result, reason
end


function Service.Query(record, query, options)
    options = type(options) == "table" and options or {}
    query = type(query) == "table" and query or {}
    local candidates, inventory, failureReason, classificationReason =
        Internal.FindCandidates(record, query, options)
    if failureReason then
        return traceQuery(record, query, "failed", failureReason, nil, options)
    end

    if #candidates < 1 then
        if classificationReason then
            return traceQuery(record, query, "failed", classificationReason,
                nil, options)
        end
        return traceQuery(record, query, "empty", "empty", {
            status = "empty",
            items = {},
            totalCount = 0,
            distinctItems = 0,
        }, options)
    end

    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.fullType ~= right.fullType then
            return left.fullType < right.fullType
        end
        return left.itemID < right.itemID
    end)

    local totalCount = 0
    local index
    for index = 1, #candidates do
        totalCount = totalCount + candidates[index].quantity
    end
    local resultItems = {}
    for index = 1, math.min(#candidates, Service.MAX_RESULTS) do
        resultItems[index] = candidates[index]
    end
    return traceQuery(record, query, "found", "found", {
        status = "found",
        items = resultItems,
        totalCount = totalCount,
        distinctItems = #candidates,
        inventoryRevision = inventory.revision,
    }, options)
end

return Service
