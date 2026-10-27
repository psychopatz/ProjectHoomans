local T = require "tests/support/test"

T.addPackagePaths()

local legacyFiles = {
    { "client", "PNC/Compatibility/Mods/Bandits/PNC_Bandits_HoomansFlavorDefinitions.lua" },
    { "client", "PNC/Compatibility/Mods/Necroa/PNC_Necroa_HoomansFlavorDefinitions.lua" },
    { "client", "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_FlavorDefinitions.lua" },
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
    { "shared", "PNC/Conversation/PNC_ConversationToolReplyCatalog.lua" },
}

for _, entry in ipairs(legacyFiles) do
    local path = T.path("ProjectHoomans", entry[1], entry[2])
    local handle = io.open(path, "rb")
    T.falsy(handle, "deleted legacy surface still exists: " .. entry[2])
    if handle then handle:close() end
end

local workerSource = T.repository
    .. "/tools/semantic_harness/lua/worker/ProductionModules_ConversationSemantic.lua"
local workerHandle = assert(io.open(workerSource, "rb"))
local workerText = workerHandle:read("*a")
workerHandle:close()
T.falsy(workerText:find("PNC_ConversationToolReplyCatalog", 1, true),
    "the production worker does not load the deleted ToolReply catalog")

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

local cases = {
    { "conversation_safety", "semantic.conversation.safety" },
    { "witnessed_player_kill", "semantic.combat.reaction" },
    { "follower_abandoned_zombie", "semantic.companion.reaction" },
    { "zombie_horde_detected", "semantic.combat.reaction" },
    { "incapacitated_call", "semantic.medical.distress.call" },
    { "incapacitated_update", "semantic.medical.distress.update" },
    { "incapacitated_repeat", "semantic.medical.distress.repeat" },
    { "witnessed_leader_death", "semantic.leader_loss.reaction" },
    { "bandit_attack", "semantic.compat.bandits.hooman_hurt" },
    { "necroa_mask_removed", "semantic.compat.necroa.mask_warning" },
    { "projectalife_meta", "semantic.compat.projectalife.meta" },
    { "companion_dog_feed", "semantic.compat.companion_dogs.feed" },
}

for index, case in ipairs(cases) do
    local eventID = "event:p10a:" .. tostring(index)
    local result = Reactions.Resolve({
        eventType = case[1],
        eventID = eventID,
        npcID = "npc-p10a",
        act = "REACT",
        context = {
            eventType = case[1],
            eventRef = eventID,
            socialRole = "neutral",
            factRefs = { eventID },
            semanticEventFacts = fact(eventID, "an authoritative event"),
            projectALifeKind = "gunfire",
            companionDogSex = "male",
        },
    })
    T.truthy(result and result.responsePlan,
        case[1] .. " retains its semantic ResponsePlan after purge")
    T.truthy(result.realizationFamily
        and string.find(result.realizationFamily, case[2], 1, true),
        case[1] .. " retains its canonical semantic family (got "
            .. tostring(result.realizationFamily) .. ", expected " .. case[2]
            .. ")")
    T.truthy(result.fallback and result.fallback ~= "",
        case[1] .. " retains selected Dialogue Content wording")
    T.falsy(string.find(result.fallback, "social.", 1, true),
        case[1] .. " does not expose a legacy prose key")
end

T.finish("pnc_unified_authority_p10a_legacy_absence_smoke")
