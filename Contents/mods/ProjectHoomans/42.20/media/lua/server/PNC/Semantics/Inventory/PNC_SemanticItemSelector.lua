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
Selector.ConceptTagAlternatives = Selector.ConceptTagAlternatives or {}
Selector.ConceptCapabilities = Selector.ConceptCapabilities or {}

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

function Selector.RegisterConceptTagAlternatives(concept, alternatives)
    concept = string.upper(tostring(concept or ""))
    if concept == "" or type(alternatives) ~= "table" then
        return false, "invalid_item_concept_tag_alternatives"
    end
    local groups = {}
    for groupIndex = 1, math.min(#alternatives, 8) do
        local source = alternatives[groupIndex]
        if type(source) ~= "table" then
            return false, "item_concept_tag_group_required"
        end
        local group = {}
        for index = 1, math.min(#source, 8) do
            local value = string.lower(tostring(source[index] or ""))
            if value ~= "" then group[#group + 1] = value end
        end
        if #group < 1 then
            return false, "item_concept_tag_group_not_empty"
        end
        groups[#groups + 1] = group
    end
    if #groups < 1 then
        return false, "item_concept_tag_alternatives_required"
    end
    Selector.ConceptTagAlternatives[concept] = groups
    return true, groups
end

function Selector.TagAlternativesForConcept(concept)
    local groups = Selector.ConceptTagAlternatives[
        string.upper(tostring(concept or ""))]
    if type(groups) ~= "table" then return nil end
    local output = {}
    for groupIndex = 1, #groups do
        local source = groups[groupIndex]
        local group = {}
        for index = 1, #source do group[index] = source[index] end
        output[groupIndex] = group
    end
    return output
end

function Selector.RegisterConceptCapabilities(concept, capabilities)
    concept = string.upper(tostring(concept or ""))
    if concept == "" or type(capabilities) ~= "table" then
        return false, "invalid_item_concept_capabilities"
    end
    local values = {}
    for index = 1, math.min(#capabilities, 8) do
        local value = string.lower(tostring(capabilities[index] or ""))
        if value ~= "" then values[#values + 1] = value end
    end
    if #values < 1 then
        return false, "item_concept_capabilities_required"
    end
    Selector.ConceptCapabilities[concept] = values
    return true, values
end

function Selector.CapabilitiesForConcept(concept)
    local values = Selector.ConceptCapabilities[
        string.upper(tostring(concept or ""))]
    if type(values) ~= "table" then return nil end
    local output = {}
    for index = 1, #values do output[index] = values[index] end
    return output
end

Selector.RegisterConceptTags("SEAFOOD", { "foodseafood" })
Selector.RegisterConceptCapabilities("FOOD", { "edible" })
Selector.RegisterConceptCapabilities("BEVERAGE", { "drinkable" })
Selector.RegisterConceptTags("WEAPON", { "weapon" })
Selector.RegisterConceptTags("FIREARM", { "firearm" })
Selector.RegisterConceptTags("RIFLE", { "firearmrifle" })
Selector.RegisterConceptTags("HANDGUN", { "firearmhandgun" })
Selector.RegisterConceptTags("SHOTGUN", { "firearmshotgun" })
Selector.RegisterConceptTags("AMMUNITION", { "ammo" })
Selector.RegisterConceptTags("TOOL", { "tool" })
Selector.RegisterConceptTags("CONTAINER", { "container" })
Selector.RegisterConceptTags("CLOTHING", { "clothing" })
Selector.RegisterConceptTags("RESOURCE", { "resource" })
Selector.RegisterConceptTags("MEDICINE", { "medical" })
Selector.RegisterConceptTags("BANDAGE", { "bandage" })
Selector.RegisterConceptTags("LITERATURE", { "literature" })
Selector.RegisterConceptTags("ELECTRONICS", { "electronics" })
Selector.RegisterConceptTags("BUILDING", { "building" })
Selector.RegisterConceptTags("FRUIT", { "foodfruits" })
Selector.RegisterConceptTags("VEGETABLE", { "foodvegetables" })
Selector.RegisterConceptTags("MEAT", { "foodmeat" })
Selector.RegisterConceptTags("LIQUID", { "liquid" })
Selector.RegisterConceptTags("MISCELLANEOUS", { "misc" })
Selector.RegisterConceptTags("MEMENTO", { "memento" })
Selector.RegisterConceptTags("GARDENING", { "gardening" })
Selector.RegisterConceptTags("COOKING_SUPPLY", { "cooking" })
Selector.RegisterConceptTags("SMOKING_SUPPLY", { "smoking" })
Selector.RegisterConceptTags("MELEE_WEAPON", { "weaponmelee" })
Selector.RegisterConceptTags("EXPLOSIVE", { "explosive" })
Selector.RegisterConceptTags("WEAPON_PART", { "weaponpart" })
Selector.RegisterConceptTags("PROTECTIVE_GEAR", { "protectivegear" })
Selector.RegisterConceptTags("ACCESSORY", { "accessory" })
Selector.RegisterConceptTags("GARDENING_TOOL", { "toolgardening" })
Selector.RegisterConceptTags("CARPENTRY_TOOL", { "toolcarpentry" })
Selector.RegisterConceptTags("MECHANICS_TOOL", { "toolmechanics" })
Selector.RegisterConceptTags("FISHING_TOOL", { "toolfishing" })
Selector.RegisterConceptTags("BUILDING_FURNITURE", { "buildingfurniture" })
Selector.RegisterConceptTags("RADIO", { "electronicsradio" })
Selector.RegisterConceptTags("BATTERY", { "electronicsbattery" })
Selector.RegisterConceptTags("GENERATOR", { "electronicsgenerator" })
Selector.RegisterConceptTags("FLASHLIGHT", { "electronicsflashlight" })
Selector.RegisterConceptTags("SKILL_BOOK", { "skillbook" })
Selector.RegisterConceptTags("FERTILIZER", { "gardeningfertilizer" })
Selector.RegisterConceptTags("COMPOST", { "gardeningcompost" })
Selector.RegisterConceptTags("WOOD", { "materialwood" })
Selector.RegisterConceptTags("PAPER", { "materialpaper" })
Selector.RegisterConceptTags("BAKING_SUPPLY", { "foodbaking" })
Selector.RegisterConceptTags("CANDY", { "foodcandy" })
Selector.RegisterConceptTags("CHEESE", { "foodcheese" })
Selector.RegisterConceptTags("EGG", { "foodegg" })
Selector.RegisterConceptTags("HERB", { "foodherb" })
Selector.RegisterConceptTags("MUSHROOM", { "foodmushroom" })
Selector.RegisterConceptTags("NUT", { "foodnut" })
Selector.RegisterConceptTags("PET_FOOD", { "foodpetfood" })
Selector.RegisterConceptTags("SNACK", { "foodsnack" })
Selector.RegisterConceptTags("SPICE", { "foodspice" })
Selector.RegisterConceptTagAlternatives("PRESERVED_FOOD", {
    { "foodpreserved" },
    { "foodnonperishablecanned" },
})
Selector.RegisterConceptTagAlternatives("METAL", {
    { "materialmetalworking" },
    { "resourcemetal" },
})
Selector.RegisterConceptTagAlternatives("WATER", {
    { "liquidwater" },
    { "beveragewater" },
})
Selector.RegisterConceptTagAlternatives("COFFEE", {
    { "foodcoffee" },
    { "beveragecoffee" },
    { "liquidcoffee" },
})
Selector.RegisterConceptTagAlternatives("TEA", {
    { "foodtea" },
    { "beveragetea" },
    { "liquidtea" },
})
Selector.RegisterConceptTagAlternatives("MILK", {
    { "beveragemilk" },
    { "beveragedairy" },
    { "liquidmilk" },
    { "foodnonperishabledairy" },
    { "foodperishabledairy" },
})
Selector.RegisterConceptTagAlternatives("SODA", {
    { "beveragesoda" },
    { "beveragesoftdrink" },
    { "liquidsoda" },
})
Selector.RegisterConceptTagAlternatives("BEER", {
    { "beveragebeer" },
    { "liquidbeer" },
})
Selector.RegisterConceptTagAlternatives("WINE", {
    { "beveragewine" },
    { "liquidwine" },
})
Selector.RegisterConceptTagAlternatives("JUICE", {
    { "beveragejuice" },
    { "liquidjuice" },
})
Selector.RegisterConceptTagAlternatives("FUEL", {
    { "resourcefuel" },
    { "liquidfuel" },
})
Selector.RegisterConceptTagAlternatives("SEED", {
    { "foodseed" },
    { "gardeningseed" },
    { "gardeningseedpacket" },
})

require "PNC/Semantics/Inventory/PNC_SemanticItemSelector_Classification"
require "PNC/Semantics/Inventory/PNC_SemanticItemSelector_TextMatching"
require "PNC/Semantics/Inventory/PNC_SemanticItemSelector_Matching"
require "PNC/Semantics/Inventory/PNC_SemanticItemSelector_Queries"

return Selector
