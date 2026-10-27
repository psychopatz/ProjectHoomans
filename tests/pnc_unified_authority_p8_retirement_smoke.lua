local T = require "tests/support/test"

T.addPackagePaths()

local function source(scope, path)
    return T.read("ProjectHoomans", scope, path)
end

local presentationCore = source(
    "client",
    "PNC/Conversation/PNC_SocialFlavorPresentation_Core.lua"
)
local farewell = source(
    "client",
    "PNC/Conversation/PNC_ConversationFarewell.lua"
)
local runtimeComposition = source(
    "client",
    "PNC/Composition/PNC_ConversationRuntimeComposition.lua"
)
local diary = source(
    "client",
    "PNC/Conversation/PNC_ConversationDiary.lua"
)
local interactionQueue = source(
    "client",
    "PNC/Commands/PNC_CompanionCommandInteractionQueue.lua"
)
local presentation = source(
    "client",
    "PNC/Commands/PNC_CompanionCommandPresentation.lua"
)

T.falsy(
    presentationCore:find("PNC_SocialFlavorDefinitions", 1, true),
    "social presentation no longer loads first-party prose definitions"
)
T.falsy(
    farewell:find("PNC_SocialFlavorDefinitions", 1, true),
    "farewell no longer loads first-party prose definitions"
)
T.falsy(
    runtimeComposition:find("HoomansFlavorDefinitions", 1, true),
    "compatibility composition no longer loads legacy Flavor definitions"
)
T.falsy(
    diary:find("Flavor.Resolve", 1, true),
    "diary never reselects wording from persisted flavor IDs"
)
T.truthy(
    interactionQueue:find("selected wording", 1, true),
    "command queue documents semantic wording ownership"
)
T.falsy(
    interactionQueue:find("authoredText", 1, true),
    "command queue cannot overwrite semantic wording with legacy content"
)
T.truthy(
    presentation:find("semantic_realization_required", 1, true),
    "ambient semantic delivery fails explicitly when realization is missing"
)

PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Reactions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)
local Ownership = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticConversationCategoryOwnership.lua"
)

T.falsy(
    PNC.SocialFlavorDefinitions,
    "semantic event selection remains independent of legacy definitions"
)

local function fact(eventID, summary)
    return {
        [eventID] = {
            eventRef = eventID,
            summary = summary,
            happened = summary,
            authoritative = true,
            disclosure = "player",
        },
    }
end

local leader = Reactions.Resolve({
    eventType = "witnessed_leader_death",
    eventID = "event:p8:leader",
    npcID = "npc-p8",
    context = {
        eventType = "witnessed_leader_death",
        eventRef = "event:p8:leader",
        eventID = "event:p8:leader",
        factRefs = { "event:p8:leader" },
        semanticEventFacts = fact(
            "event:p8:leader",
            "the settlement leader died"
        ),
    },
})
T.truthy(leader and leader.responsePlan,
    "leader loss remains semantic-owned after selector retirement")
T.truthy(leader and leader.fallback,
    "leader loss still has selected wording")

for _, categoryID in ipairs({
    "projecthoomans:wellbeing",
    "projecthoomans:small_talk",
    "projecthoomans:ask_about",
}) do
    local metadata = Ownership.Get(categoryID)
    T.truthy(metadata, categoryID .. " has semantic ownership metadata")
    T.equal(metadata.authority, "semantic_response_flow",
        categoryID .. " reports semantic meaning authority")
    T.equal(metadata.registryRole, "eligibility_gates_effects_projection",
        categoryID .. " keeps registry data as a projection only")
    T.equal(metadata.registryOwner, "conversation_registry_data",
        categoryID .. " records the bounded registry data owner")
    T.falsy(metadata.legacyRegistry,
        categoryID .. " no longer reports legacy registry authority")
end

T.finish("pnc_unified_authority_p8_retirement_smoke")
