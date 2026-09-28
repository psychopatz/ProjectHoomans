local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
T.addPackagePaths()

PNC = {}
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRegistry.lua")
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRules.lua")
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationSelector.lua")

local Registry = PNC.Conversation.Registry
local Selector = PNC.Conversation.Selector

local categoryID = "test:caravan"
local providerID = "test:caravan_roles"
local textSource = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/test/{language}/basic.json",
    domain = "test.conversation.basic",
}

T.truthy(Registry.RegisterCategory(categoryID, {
    ownerModID = "ProjectHoomans",
    labelKey = "category.test_caravan",
    order = 1,
    textSource = textSource,
}), "category registration")
T.truthy(Registry.RegisterCategoryEligibilityProvider(providerID, {
    evaluate = function(category, context)
        if category.id ~= categoryID then return true end
        return context and context.role == "merchant",
            "test_requires_merchant"
    end,
}), "category provider registration")

local eligible, reason = Selector.IsCategoryEligible(categoryID, {
    role = "merchant",
    worldAgeHours = 10,
})
T.truthy(eligible, "merchant category is eligible")
T.equal(reason, nil, "eligible category has no rejection reason")

eligible, reason = Selector.IsCategoryEligible(categoryID, {
    role = "guard",
    worldAgeHours = 10,
})
T.falsy(eligible, "guard category is rejected")
T.equal(reason, "test_requires_merchant",
    "category provider reason reaches selection")

T.truthy(Registry.UnregisterCategoryEligibilityProvider(providerID),
    "category provider unregisters")
eligible = Selector.IsCategoryEligible(categoryID, {
    role = "guard",
    worldAgeHours = 10,
})
T.truthy(eligible, "unregistered provider no longer gates category")

T.truthy(Registry.RegisterCategoryEligibilityProvider(providerID, {
    evaluate = function()
        error("bounded provider failure")
    end,
}), "failing provider registration")
eligible, reason = Selector.IsCategoryEligible(categoryID, {
    role = "merchant",
    worldAgeHours = 10,
})
T.falsy(eligible, "provider failure fails closed")
T.equal(reason, "category_eligibility_error",
    "provider failure is normalized")

T.finish("pnc_conversation_category_eligibility_smoke")
