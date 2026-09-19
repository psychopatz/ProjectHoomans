-- Read-only semantic item selection over PNC's compact inventory model.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ItemSelector = PNC.Semantics.ItemSelector or {}

local Selector = PNC.Semantics.ItemSelector
Selector.Cache = Selector.Cache or {}
Selector.Internal = Selector.Internal or {}
Selector.MAX_ITEMS = Selector.MAX_ITEMS or 256
Selector.MAX_TAGS = Selector.MAX_TAGS or 96
Selector.ConceptTags = Selector.ConceptTags or {}

-- MarketSense owns the rich item taxonomy.  This small bridge only maps the
-- semantic concepts that Hoomans exposes to stable MarketSense tags; it does
-- not copy the taxonomy into the parser or mutate inventory state.
function Selector.RegisterConceptTags(concept, tags)
    concept = string.upper(tostring(concept or ""))
    if concept == "" or type(tags) ~= "table" then
        return false, "invalid_item_concept_tags"
    end
    local values = {}
    for index = 1, math.min(#tags, 8) do
        local value = string.lower(tostring(tags[index] or ""))
        if value ~= "" then values[#values + 1] = value end
    end
    if #values < 1 then return false, "item_concept_tags_required" end
    Selector.ConceptTags[concept] = values
    return true, values
end

function Selector.TagsForConcept(concept)
    local values = Selector.ConceptTags[string.upper(tostring(concept or ""))]
    if type(values) ~= "table" then return nil end
    local output = {}
    for index = 1, #values do output[index] = values[index] end
    return output
end

Selector.RegisterConceptTags("SEAFOOD", { "foodseafood" })
Selector.RegisterConceptTags("FOOD", { "food" })
Selector.RegisterConceptTags("WATER", { "liquidwater" })
Selector.RegisterConceptTags("MEDICINE", { "firstaid" })

require "PNC/Semantics/Inventory/PNC_SemanticItemSelector_Classification"
require "PNC/Semantics/Inventory/PNC_SemanticItemSelector_TextMatching"
require "PNC/Semantics/Inventory/PNC_SemanticItemSelector_Matching"
require "PNC/Semantics/Inventory/PNC_SemanticItemSelector_Queries"

return Selector
