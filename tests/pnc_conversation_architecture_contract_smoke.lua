-- Durable Conversation architecture contract.
--
-- This replaces the phase-by-phase migration absence tests.  It protects the
-- steady-state boundaries and keeps the useful semantic/runtime
-- characterization in one place; Git history remains the migration archive.

local T = require "tests/support/test"

T.addPackagePaths()

local function exists(path)
    local handle = io.open(path, "rb")
    if handle then handle:close() return true end
    return false
end

local function absent(scope, relative)
    T.falsy(
        exists(T.path("ProjectHoomans", scope, relative)),
        "retired Conversation surface remains: " .. relative
    )
end

-- First-party migration registries are archive-only.  The two compatibility
-- adapters below intentionally keep their provider-owned transport surfaces,
-- but no longer advertise them as Hoomans Flavor authorities.
local deleted = {
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Core.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_GroupA.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_GroupB.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_GroupC.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Ally.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Hostile.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Other.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Ally.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Hostile.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Wider.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Update.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath_Close.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath_Wider.lua" },
    { "client", "PNC/Compatibility/Mods/Bandits/PNC_Bandits_HoomansFlavorDefinitions.lua" },
    { "client", "PNC/Compatibility/Mods/Necroa/PNC_Necroa_HoomansFlavorDefinitions.lua" },
    { "client", "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_FlavorDefinitions.lua" },
    { "shared", "PNC/Conversation/PNC_ConversationToolReplyCatalog.lua" },
    { "shared", "PNC/Core/Commands/PNC_CompanionCommandFlavor.lua" },
    { "shared", "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions.lua" },
    { "shared", "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_Core.lua" },
    { "shared", "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_Base.lua" },
    { "shared", "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_TypedA.lua" },
    { "shared", "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_TypedB.lua" },
    { "shared", "PNC/Core/Social/PNC_FlavorTextResolver.lua" },
    { "shared", "PNC/Core/Social/PNC_FlavorTextResolver_Constants.lua" },
    { "shared", "PNC/Core/Identity/PNC_FlavorAddress.lua" },
    { "client", "PNC/Conversation/PNC_SocialFlavorPresentation.lua" },
    { "shared", "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Flavor.lua" },
    { "client", "PNC/Compatibility/Mods/Necroa/PNC_Necroa_ZombieFlavor.lua" },
}
for _, entry in ipairs(deleted) do absent(entry[1], entry[2]) end

T.truthy(exists(T.path("ProjectHoomans", "shared",
    "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_SpeechBridge.lua")),
    "Bandits transport bridge has a neutral ownership name")
T.truthy(exists(T.path("ProjectHoomans", "client",
    "PNC/Compatibility/Mods/Necroa/PNC_Necroa_ZombieCaptionAdapter.lua")),
    "Necroa provider caption adapter has a neutral ownership name")

local workerSource = T.repository
    .. "/tools/semantic_harness/lua/worker/ProductionModules_ConversationSemantic.lua"
local workerHandle = assert(io.open(workerSource, "rb"))
local workerText = workerHandle:read("*a")
workerHandle:close()
T.falsy(workerText:find("PNC_ConversationToolReplyCatalog", 1, true),
    "worker does not load the deleted wording registry")
T.falsy(workerText:find("PNC_SocialFlavorDefinitions", 1, true),
    "worker does not load deleted prose definitions")

local composition = T.read(
    "ProjectHoomans", "client", "PNC/Composition/PNC_ClientComposition.lua"
)
T.falsy(composition:find("PNC_Necroa_ZombieFlavor", 1, true),
    "client composition does not load the old Flavor-named adapter")
T.truthy(composition:find("PNC_Necroa_ZombieCaptionAdapter", 1, true),
    "client composition loads the provider caption adapter")

local sourcePath = T.repository
    .. "/tools/semantic_harness/codebuilder/sources/"
    .. "conversation/manifest.json"
local sourceHandle = assert(io.open(sourcePath, "rb"))
local contentSource = sourceHandle:read("*a")
sourceHandle:close()
for _, marker in ipairs({
    ".migrated.", "MIGRATED_", "legacySource", "migrated_events",
    "semanticAuthority", "responsePoolID", "semanticVariantID",
}) do
    T.falsy(contentSource:find(marker, 1, true),
        "canonical Conversation content retains migration marker: " .. marker)
end

-- Current metadata contains the real authority boundary, never the phase
-- vocabulary that described how the repository got here.
PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua")
local Reactions = T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua")
local Ownership = T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticConversationCategoryOwnership.lua")

for _, categoryID in ipairs({
    "projecthoomans:wellbeing",
    "projecthoomans:small_talk",
    "projecthoomans:ask_about",
}) do
    local metadata = Ownership.Get(categoryID)
    T.truthy(metadata, categoryID .. " has semantic ownership metadata")
    T.equal(metadata.authority, "semantic_response_flow",
        categoryID .. " selects meaning through semantics")
    T.equal(metadata.registryRole, "eligibility_gates_effects_projection",
        categoryID .. " retains registry data authority only")
    T.equal(metadata.registryOwner, "conversation_registry_data",
        categoryID .. " names the registry data owner")
    T.equal(metadata.legacyRegistry, nil,
        categoryID .. " has no legacy registry field")
    T.equal(metadata.migrationPhase, nil,
        categoryID .. " has no migration phase field")
end

local function eventFacts(eventID)
    return {
        [eventID] = {
            eventRef = eventID,
            summary = "an authoritative event occurred",
            happened = "an authoritative event occurred",
            authoritative = true,
            disclosure = "player",
        },
    }
end

for index, eventType in ipairs({
    "conversation_safety", "witnessed_player_kill",
    "follower_abandoned_zombie", "zombie_horde_detected",
    "incapacitated_call", "incapacitated_update", "incapacitated_repeat",
    "witnessed_leader_death", "bandit_attack", "necroa_mask_removed",
    "projectalife_meta", "companion_dog_feed",
}) do
    local eventID = "event:conversation-contract:" .. tostring(index)
    local result = Reactions.Resolve({
        eventType = eventType,
        eventID = eventID,
        npcID = "npc-conversation-contract",
        act = "REACT",
        context = {
            eventType = eventType,
            eventRef = eventID,
            socialRole = "neutral",
            factRefs = { eventID },
            semanticEventFacts = eventFacts(eventID),
            projectALifeKind = "gunfire",
            companionDogSex = "male",
        },
    })
    T.truthy(result and result.responsePlan,
        eventType .. " retains one semantic response plan")
    T.truthy(result and result.realizationID,
        eventType .. " retains a selected realization")
    T.truthy(result and result.fallback and result.fallback ~= "",
        eventType .. " retains selected content wording")
end

local SocialContext = require "PNC/Core/Social/PNC_SemanticSocialContext"
local AddressResolver = require "PNC/Semantics/PNC_SemanticAddressResolver"
T.equal(PNC.FlavorText, nil, "FlavorText compatibility namespace is absent")
T.equal(PNC.FlavorAddress, nil, "FlavorAddress compatibility namespace is absent")
T.equal(PNC.Semantics.SocialContext, SocialContext,
    "social facts use the semantic context provider")
T.equal(PNC.Semantics.AddressResolver, AddressResolver,
    "identity terms use the semantic address resolver")
local address = AddressResolver.Resolve({
    relationshipKind = "companion", persona = "casual", gender = "male",
})
T.equal(address.id, "bro", "semantic addressing preserves the friendly term")

T.finish("pnc_conversation_architecture_contract_smoke")
