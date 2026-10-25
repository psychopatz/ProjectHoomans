local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {
    Semantics = {
        IR = {
            New = function(value) return value end,
        },
    },
    Conversation = {
        Text = {
            Resolve = function(value) return value.fallback end,
        },
    },
    Translation = {
        GetKey = function(_, _, fallback) return fallback end,
    },
}
PNC = {
    Semantics = {
        SemanticDialogueRuntime = {
            IsEnabled = function() return true end,
        },
        CapabilityCatalog = {
            ListActions = function()
                return {
                    { id = "FOLLOW", dispatchable = true },
                    { id = "GO", dispatchable = true },
                    { id = "STAY", dispatchable = true },
                }
            end,
        },
    },
}
ZombRand = function() return 1 end

PNC.Identity = {}
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
PNC.Semantics.SuggestionPredicates = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueSuggestionPredicates.lua"
)
PNC.Semantics.DialogueBranchOffers = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueBranchOffers.lua"
)
PNC.Semantics.ActorConversationContext = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_ActorConversationContext.lua"
)
PNC.Semantics.DialogueChoiceRanking = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_Ranking.lua"
)

local registry = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_Registry.lua"
)
local staticProvider = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider.lua"
)
local capabilityProvider = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_CapabilityProvider.lua"
)
local socialProvider = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_SocialProvider.lua"
)

local originalRequire = require
local loadedModules = {
    ["PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_Registry"] = registry,
    ["PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_StaticProvider"] = staticProvider,
    ["PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_CapabilityProvider"] = capabilityProvider,
    ["PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_SocialProvider"] = socialProvider,
}
require = function(name)
    return loadedModules[name] or originalRequire(name)
end

local Suggestions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueSuggestions.lua"
)
require = originalRequire

local projection = Suggestions.Build({
    accepted = true,
    sequence = 7,
    ir = {},
    decision = {},
}, {
    baseEstablished = false,
    actorAuthority = {
        eligible = true,
        owned = true,
        companion = true,
    },
    npcState = {
        activeBehavior = "idle",
        healthState = "healthy",
        orderKind = "idle",
        followState = { mode = "idle" },
    },
    campSiteCandidates = {
        {
            id = "action.camp_site:bedroom",
            siteID = "site:bedroom",
            roomID = "room:bedroom",
            roomName = "Bedroom",
            x = 10,
            y = 11,
            z = 0,
        },
    },
})

local campGroup
for _, group in ipairs(projection.groups or {}) do
    if group.id == Suggestions.COMPANION_CAMP_GROUP_ID then
        campGroup = group
        break
    end
end
T.truthy(campGroup, "camp group is projected for an owned companion")
T.equal(#campGroup.capabilities, 2,
    "a discovered room produces an automatic and a specific camp row")
T.equal(campGroup.capabilities[1].display.label, "Let's camp here.",
    "the automatic camp row is presented first")
T.equal(campGroup.capabilities[1].capability.selectionMode, "auto",
    "the automatic camp row retains auto selection semantics")
T.equal(campGroup.capabilities[1].status, "eligible",
    "automatic camp capability exposes its top-level eligible status")
T.truthy(campGroup.capabilities[1].enabled,
    "automatic camp capability remains enabled for the UI adapter")
T.truthy(campGroup.capabilities[1].frame.target.clientHint,
    "automatic camp capability carries the bounded best-site hint")
T.equal(campGroup.capabilities[2].display.label, "Let's camp in the bedroom.",
    "the specific room row exposes the concrete room type")
T.equal(campGroup.capabilities[2].capability.selectionMode, "specific",
    "the specific camp row retains explicit selection semantics")
T.truthy(campGroup.capabilities[2].enabled,
    "the specific room capability remains enabled for the UI adapter")

local campfireProjection = Suggestions.Build({
    accepted = true,
    sequence = 8,
    ir = {},
    decision = {},
}, {
    baseEstablished = true,
    actorAuthority = {
        eligible = true,
        owned = true,
        companion = true,
    },
    npcState = {
        activeBehavior = "idle",
        healthState = "healthy",
        orderKind = "idle",
        followState = { mode = "idle" },
    },
    campSiteCandidates = {
        {
            id = "action.camp_site:fire",
            kind = "campfire",
            campfireID = "fire:1",
            scope = "campfire",
            x = 12,
            y = 11,
            z = 0,
        },
    },
})
local campfireGroup
for _, group in ipairs(campfireProjection.groups or {}) do
    if group.id == Suggestions.COMPANION_CAMP_GROUP_ID then
        campfireGroup = group
        break
    end
end
T.truthy(campfireGroup, "campfire candidate projects into the camp group")
T.equal(campfireGroup.capabilities[2].display.label,
    "Let's camp by the campfire.",
    "specific campfire row exposes the concrete campfire type")

local goHome
for _, capability in ipairs(projection.permittedCapabilities or {}) do
    if capability.action == "GO" then
        goHome = capability
        break
    end
end
T.truthy(goHome, "Go Home remains visible for an owned companion")
T.equal(goHome.status, "unavailable_rejected",
    "Go Home is unavailable without a base")
T.falsy(goHome.enabled,
    "Go Home is disabled without a base")
T.equal(goHome.reasonCode, "base_required",
    "Go Home carries the stable no-base reason")

local function capabilityFor(projection, action)
    for _, capability in ipairs(projection.permittedCapabilities or {}) do
        if capability.action == action then return capability end
    end
    return nil
end

local follow = capabilityFor(projection, "FOLLOW")
local stay = capabilityFor(projection, "STAY")
T.truthy(follow, "idle companion exposes the Follow action")
T.equal(follow.status, "eligible", "Follow is eligible while idle")
T.falsy(stay, "idle companion hides the non-actionable Stay toggle")
local ordersGroup
for _, group in ipairs(projection.groups or {}) do
    if group.id == Suggestions.COMPANION_ORDERS_GROUP_ID then
        ordersGroup = group
        break
    end
end
local groupActions = {}
for _, capability in ipairs(ordersGroup and ordersGroup.capabilities or {}) do
    groupActions[capability.action] = capability
end
T.truthy(groupActions.FOLLOW,
    "Follow is present in the rendered companion orders group")
T.falsy(groupActions.STAY,
    "Stay is absent from the rendered group while idle")

local followingProjection = Suggestions.Build({
    accepted = true,
    sequence = 10,
    ir = {},
    decision = {},
}, {
    baseEstablished = true,
    actorAuthority = {
        eligible = true,
        owned = true,
        companion = true,
    },
    npcState = {
        activeBehavior = "idle",
        healthState = "healthy",
        orderKind = "follow",
        followState = { mode = "following" },
    },
    campSiteCandidates = {},
})
local followingAction = capabilityFor(followingProjection, "FOLLOW")
local stayAction = capabilityFor(followingProjection, "STAY")
T.falsy(followingAction,
    "following companion hides the redundant Follow toggle")
T.truthy(stayAction, "following companion exposes the Stay action")
T.equal(stayAction.status, "eligible", "Stay is eligible while following")

local movingProjection = Suggestions.Build({
    accepted = true,
    sequence = 11,
    ir = {},
    decision = {},
}, {
    baseEstablished = true,
    actorAuthority = {
        eligible = true,
        owned = true,
        companion = true,
    },
    npcState = {
        activeBehavior = "FollowOwner:moving",
        healthState = "healthy",
        orderKind = "idle",
        followState = { mode = "following" },
    },
})
local movingFollow = capabilityFor(movingProjection, "FOLLOW")
local movingStay = capabilityFor(movingProjection, "STAY")
T.equal(movingFollow.status, "eligible",
    "a transient moving phase does not imply a durable follow order")
T.falsy(movingStay,
    "Stay stays hidden until the durable follow order is active")

local busyProjection = Suggestions.Build({
    accepted = true,
    sequence = 9,
    ir = {},
    decision = {},
}, {
    baseEstablished = true,
    actorAuthority = {
        eligible = true,
        owned = true,
        companion = true,
    },
    npcState = {
        activeBehavior = "busy",
        healthState = "healthy",
        orderKind = "idle",
        followState = { mode = "idle" },
    },
    campSiteCandidates = {},
})
local busyGoHome
for _, capability in ipairs(busyProjection.permittedCapabilities or {}) do
    if capability.action == "GO" then
        busyGoHome = capability
        break
    end
end
T.truthy(busyGoHome, "Go Home remains visible while the companion is busy")
T.equal(busyGoHome.reasonCode, "companion_busy",
    "busy Go Home explains the companion-state rejection")
T.falsy(capabilityFor(busyProjection, "FOLLOW"),
    "Follow hides while the companion is busy")
T.falsy(capabilityFor(busyProjection, "STAY"),
    "Stay hides while the companion is busy")

local incapacitatedProjection = Suggestions.Build({
    accepted = true,
    sequence = 12,
    ir = {},
    decision = {},
}, {
    baseEstablished = true,
    actorAuthority = {
        eligible = true,
        owned = true,
        companion = true,
    },
    npcState = {
        activeBehavior = "FollowOwner:abstract",
        healthState = "incapacitated",
        orderKind = "follow",
        followState = { mode = "abstract_follow" },
    },
    campSiteCandidates = {
        {
            id = "action.camp_site:incapacitated",
            siteID = "site:incapacitated",
            roomID = "room:incapacitated",
            x = 10,
            y = 10,
            z = 0,
        },
    },
})
T.falsy(capabilityFor(incapacitatedProjection, "FOLLOW"),
    "Follow hides while the companion is incapacitated")
T.falsy(capabilityFor(incapacitatedProjection, "STAY"),
    "Stay hides while the companion is incapacitated")
local incapacitatedCampGroup
for _, group in ipairs(incapacitatedProjection.groups or {}) do
    if group.id == Suggestions.COMPANION_CAMP_GROUP_ID then
        incapacitatedCampGroup = group
        break
    end
end
T.truthy(incapacitatedCampGroup,
    "camp group remains inspectable while the companion is incapacitated")
T.falsy(incapacitatedCampGroup.capabilities[1].enabled,
    "camp destination is disabled while the companion is incapacitated")
T.equal(incapacitatedCampGroup.capabilities[1].reasonCode,
    "companion_incapacitated",
    "camp destination explains the incapacitation rejection")

local emptyProjection = Suggestions.Build({
    accepted = true,
    sequence = 8,
    ir = {},
    decision = {},
}, {
    baseEstablished = false,
    actorAuthority = {
        eligible = true,
        owned = true,
        companion = true,
    },
    npcState = {
        activeBehavior = "idle",
        healthState = "healthy",
        orderKind = "idle",
        followState = { mode = "idle" },
    },
    campSiteCandidates = {},
})
local campNavigation
for _, candidate in ipairs(emptyProjection.candidates or {}) do
    if candidate.id == "companion.orders:camp" then
        campNavigation = candidate
        break
    end
end
T.truthy(campNavigation,
    "camp navigation remains visible when no location is available")
T.falsy(campNavigation.enabled,
    "camp navigation is disabled without a candidate")
T.equal(campNavigation.status, "unavailable_no_camp_site",
    "camp navigation exposes the empty-location status")
T.equal(campNavigation.reasonCode, "no_camp_site",
    "camp navigation carries the stable empty-location reason")
local emptyCampGroup
for _, group in ipairs(emptyProjection.groups or {}) do
    if group.id == Suggestions.COMPANION_CAMP_GROUP_ID then
        emptyCampGroup = group
        break
    end
end
T.truthy(emptyCampGroup,
    "camp group remains inspectable when no location is available")
T.equal(emptyCampGroup.capabilities[1].display.label,
    "Let's camp here.",
    "automatic camp choice remains visible without a valid location")
T.falsy(emptyCampGroup.capabilities[1].enabled,
    "automatic camp choice is disabled without a valid location")
T.equal(emptyCampGroup.capabilities[1].reasonCode, "no_camp_site",
    "automatic camp choice explains the missing-location rejection")

T.finish("pnc_semantic_dialogue_suggestions_availability_smoke")
