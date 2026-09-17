-- Client-only semantic gift candidate selection.
-- The server remains authoritative for transfer and relationship effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Selection = PNC.Semantics.GiftSelection or {}
PNC.Semantics.GiftSelection = Selection
Selection.VERSION = 1
Selection.MAX_ITEMS = Selection.MAX_ITEMS or 256
Selection.MAX_DEPTH = Selection.MAX_DEPTH or 4
Selection.MAX_TRANSFER_ITEMS = 32
Selection.Internal = Selection.Internal or {}

require "PNC/Semantics/PNC_SemanticGiftSelection_Match"
require "PNC/Semantics/PNC_SemanticGiftSelection_Scan"

local Internal = Selection.Internal

function Selection.Find(player, offer, options)
    options = type(options) == "table" and options or {}
    if not player then return nil, "player_unavailable" end
    local query, quantity = Internal.RequestFor(offer)
    if query == "" then return nil, "gift_query_empty" end
    local candidates = Internal.ScanPlayer(player)
    local matched = {}
    for index = 1, #candidates do
        local candidate = candidates[index]
        if Internal.ScoreCandidate(candidate, query) > 0 then
            matched[#matched + 1] = candidate
        end
    end
    local groups = Internal.Grouped(matched)
    local best = groups[1]
    local second = groups[2]
    local minimum = tonumber(options.minimumScore) or 58
    if not best or best.score < minimum then
        return nil, "gift_item_not_found", {
            query = query, candidateCount = #candidates,
        }
    end
    if second and best.fullType ~= second.fullType
        and best.score - second.score < (tonumber(options.margin) or 12)
    then
        return nil, "gift_item_ambiguous", {
            query = query, candidateCount = #candidates,
            bestType = best.fullType, secondType = second.fullType,
            bestScore = best.score, secondScore = second.score,
        }
    end
    local itemIDs = {}
    local limit = math.min(quantity, Selection.MAX_TRANSFER_ITEMS,
        #best.itemIDs)
    for index = 1, limit do itemIDs[#itemIDs + 1] = best.itemIDs[index] end
    if #itemIDs == 0 then return nil, "gift_item_not_found" end
    return {
        status = "matched", query = query,
        requestedQuantity = quantity, quantity = #itemIDs,
        itemIDs = itemIDs, fullType = best.fullType,
        displayName = best.displayName,
        facts = best.facts,
        score = best.score, matchField = best.matchField,
        diagnostics = { candidateCount = #candidates,
            groupCount = #groups, secondScore = second and second.score or nil },
    }
end

return Selection
