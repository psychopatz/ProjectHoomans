local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")

local function capture(path, setup)
    local calls = {}
    local originalRequire = require
    require = function(name)
        calls[#calls + 1] = name
        return true
    end
    if setup then setup(calls) end
    T.load(path)
    require = originalRequire
    return calls
end

local function indexOf(values, expected)
    for index = 1, #values do
        if values[index] == expected then return index end
    end
    return nil
end

local anchorCases = {
    {
        path = ROOT .. "shared/PNC/00_PNC_Init.lua",
        composition = "PNC/Composition/PNC_SharedComposition",
    },
    {
        path = ROOT .. "server/PNC/00_PNC_Server_Init.lua",
        composition = "PNC/Composition/PNC_ServerComposition",
    },
    {
        path = ROOT .. "client/PNC/00_PNC_Client_Init.lua",
        composition = "PNC/Composition/PNC_ClientComposition",
    },
    {
        path = ROOT .. "shared/PNC/00_PNC_Conversation_Init.lua",
        composition =
            "PNC/Conversation/Composition/PNC_ConversationSharedComposition",
    },
    {
        path = ROOT .. "client/PNC/00_PNC_Conversation_Init.lua",
        composition =
            "PNC/Conversation/Composition/PNC_ConversationClientComposition",
    },
}

for _, case in ipairs(anchorCases) do
    local calls = capture(case.path)
    T.equal(#calls, 1, case.path .. " must remain thin")
    T.equal(calls[1], case.composition,
        case.path .. " composition delegation")
end

PNC = {}
local sharedCalls = capture(
    ROOT .. "shared/PNC/Composition/PNC_SharedComposition.lua"
)
T.equal(sharedCalls[1], "PNC/Core/Base/PNC_Core",
    "shared composition first dependency")
T.equal(sharedCalls[#sharedCalls], "PNC/Integrations/PNC_PsychopatzProfiler",
    "shared composition final dependency")
local travelIndex = indexOf(sharedCalls, "PNC/Core/Travel/PNC_Travel")
T.equal(sharedCalls[travelIndex - 1], "PNC/Core/Pathing/PNC_PathService",
    "shared Travel initialization predecessor")
T.equal(sharedCalls[travelIndex + 1],
    "PNC/Core/MapCommands/PNC_MapCommandService",
    "shared Travel initialization successor")

PNC = {}
local serverCalls = capture(
    ROOT .. "server/PNC/Composition/PNC_ServerComposition.lua",
    function(calls)
        PNC.ProfilerIntegration = {
            InstallServer = function()
                calls[#calls + 1] = "<install-server-profiler>"
            end,
        }
    end
)
T.equal(serverCalls[1], "PNC/00_PNC_Init",
    "server composition begins with shared anchor")
local factionCoreIndex = indexOf(
    serverCalls,
    "PNC/Factions/PNC_FactionCore"
)
T.equal(serverCalls[factionCoreIndex - 1], "PNC/PNC_ConductDebug",
    "server Faction core initialization predecessor")
T.equal(serverCalls[factionCoreIndex + 1], "PNC/PNC_CommunityService",
    "server Faction core initialization successor")
local settlementIndex = indexOf(serverCalls, "PNC/Settlement/PNC_Settlement")
T.equal(serverCalls[settlementIndex - 1], "PNC/PNC_CommunityService",
    "server Settlement initialization predecessor")
local facilityJobsIndex = indexOf(serverCalls,
    "PNC/Settlement/FacilityJobs/PNC_FacilityJobs_Service")
T.equal(serverCalls[facilityJobsIndex + 1],
    "PNC/World/PNC_NearbyResourceLocator",
    "nearby resource services load before Tasking")
T.equal(serverCalls[facilityJobsIndex + 3], "PNC/Tasking/PNC_Tasking",
    "Tasking loads after nearby resource services")
T.equal(serverCalls[settlementIndex + 1], "PNC/Journals/PNC_JournalRoutes",
    "server Settlement initialization successor")
local directorIndex = indexOf(serverCalls, "PNC/Director/PNC_Director")
T.equal(serverCalls[directorIndex - 1], "PNC/Needs/PNC_NeedSupplyBridge",
    "server Director initialization predecessor")
T.equal(serverCalls[directorIndex + 1], "PNC/PNC_NeedsScheduler",
    "server Director initialization successor")
T.equal(serverCalls[#serverCalls - 1], "<install-server-profiler>",
    "server profiler installation timing")
T.equal(serverCalls[#serverCalls], "PNC/PNC_Server",
    "server runtime starts after dependencies")
local conversationServerIndex = indexOf(
    serverCalls,
    "PNC/Conversation/PNC_ConversationServer"
)
T.equal(serverCalls[conversationServerIndex - 1],
    "PNC/PNC_SocialEventHooks",
    "server Conversation initialization predecessor")
T.equal(serverCalls[conversationServerIndex + 1],
    "PNC/PNC_ServerInventory",
    "server Conversation initialization successor")

local eventMarkers = {}
PNC = {}
PsychopatzCore = { EventMarkers = eventMarkers }
local clientCalls = capture(
    ROOT .. "client/PNC/Composition/PNC_ClientComposition.lua"
)
T.equal(clientCalls[1], "PNC/00_PNC_Init",
    "client composition begins with shared anchor")
T.equal(clientCalls[#clientCalls], "PNC/Integrations/PNC_PsychopatzCoreDebug",
    "client composition final dependency")
T.equal(PNC.EventMarkers, eventMarkers,
    "client EventMarkers assignment timing")

PNC = { Conversation = {} }
local conversationSharedCalls = capture(
    ROOT
        .. "shared/PNC/Conversation/Composition/"
        .. "PNC_ConversationSharedComposition.lua"
)
local expectedConversationShared = {
    "PNC/Conversation/Blocks/PNC_ConversationRegistry",
    "PNC/Conversation/Blocks/PNC_ConversationRules",
    "PNC/Conversation/Blocks/PNC_ConversationSelector",
    "PNC/Conversation/PNC_ConversationScene",
    "PNC/Conversation/Definitions/00_PNC_ConversationDefinitions",
}
for index = 1, #expectedConversationShared do
    T.equal(
        conversationSharedCalls[index],
        expectedConversationShared[index],
        "shared Conversation dependency " .. tostring(index)
    )
end
T.equal(#conversationSharedCalls, #expectedConversationShared,
    "shared Conversation dependency count")

local pumpRegistrations = 0
PNC = {
    Conversation = {
        Composer = {
            PumpLocalRequests = function() end,
            LocalPumpRegistered = false,
        },
    },
}
Events = {
    OnTick = {
        Add = function(callback)
            T.equal(callback, PNC.Conversation.Composer.PumpLocalRequests,
                "client Conversation pump callback")
            pumpRegistrations = pumpRegistrations + 1
        end,
    },
}
local conversationClientCalls = capture(
    ROOT
        .. "client/PNC/Conversation/Composition/"
        .. "PNC_ConversationClientComposition.lua"
)
T.equal(conversationClientCalls[1], "PNC/Conversation/PNC_Conversation",
    "client Conversation first dependency")
T.equal(conversationClientCalls[2],
    "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation",
    "client Conversation final dependency")
T.equal(#conversationClientCalls, 2,
    "client Conversation dependency count")
T.equal(pumpRegistrations, 1,
    "client Conversation pump registration timing")
T.equal(PNC.Conversation.Composer.LocalPumpRegistered, true,
    "client Conversation pump registration guard")
capture(
    ROOT
        .. "client/PNC/Conversation/Composition/"
        .. "PNC_ConversationClientComposition.lua"
)
T.equal(pumpRegistrations, 1,
    "client Conversation pump registers once")

PNC = { Conversation = {} }
local conversationServerCalls = capture(
    ROOT .. "server/PNC/Conversation/PNC_ConversationServer.lua"
)
T.equal(conversationServerCalls[1],
    "PNC/Conversation/PNC_ConversationHistory",
    "server Conversation history dependency")
T.equal(conversationServerCalls[2],
    "PNC/Conversation/PNC_ConversationAuthority",
    "server Conversation authority dependency")
T.equal(#conversationServerCalls, 2,
    "server Conversation dependency count")

PNC = { Factions = {} }
local factionCoreCalls = capture(
    ROOT .. "server/PNC/Factions/PNC_FactionCore.lua"
)
local expectedFactionCore = {
    "PNC/PNC_FactionTelemetry",
    "PNC/PNC_FactionService",
    "PNC/PNC_FactionLeadership",
    "PNC/PNC_FactionMembershipService",
}
for index = 1, #expectedFactionCore do
    T.equal(factionCoreCalls[index], expectedFactionCore[index],
        "server Faction core dependency " .. tostring(index))
end
T.equal(#factionCoreCalls, #expectedFactionCore,
    "server Faction core dependency count")

PNC = {}
local settlementCalls = capture(
    ROOT .. "server/PNC/Settlement/PNC_Settlement.lua"
)
local expectedSettlement = {
    "PNC/Settlement/PNC_SettlementRepository",
    "PNC/Settlement/PNC_BaseValidationService",
    "PNC/Settlement/PNC_BaseService",
    "PNC/Settlement/PNC_FacilityWorldValidation",
    "PNC/Settlement/PNC_FacilityValidationService",
    "PNC/Settlement/PNC_FacilityCostService",
    "PNC/Settlement/PNC_FacilityService",
    "PNC/Settlement/PNC_InteractionTargetResolver",
    "PNC/Settlement/PNC_FacilityReservations",
    "PNC/Settlement/PNC_StockpileAccessService",
    "PNC/Settlement/PNC_SettlementDebug",
    "PNC/Settlement/PNC_WaterUtilityService",
}
for index = 1, #expectedSettlement do
    T.equal(settlementCalls[index], expectedSettlement[index],
        "server Settlement dependency " .. tostring(index))
end
T.equal(#settlementCalls, #expectedSettlement,
    "server Settlement dependency count")

PNC = {}
local directorCalls = capture(
    ROOT .. "server/PNC/Director/PNC_Director.lua"
)
local expectedDirector = {
    "PNC/Director/PNC_AbstractWorldStore",
    "PNC/Director/PNC_AbstractLocationManager",
    "PNC/Director/PNC_AbstractGroupManager",
    "PNC/WorldDiscovery/PNC_WorldDiscovery",
    "PNC/Director/PNC_AbstractCombatProfile",
    "PNC/Director/PNC_AbstractResourceNeeds",
    "PNC/Director/PNC_AbstractBehaviorProfile",
    "PNC/Director/PNC_AbstractScavengeResolver",
    "PNC/Director/PNC_AbstractActionResolver",
    "PNC/Director/PNC_AbstractEncounterEvaluator",
    "PNC/Director/PNC_AbstractCasualtyResolver",
    "PNC/Director/PNC_AbstractMobileAccidents",
    "PNC/Director/PNC_AbstractRetreatResolver",
    "PNC/Director/PNC_AbstractCombatResolver",
    "PNC/Director/PNC_AbstractEncounterResolver",
    "PNC/Director/PNC_AbstractEncounterDetector",
    "PNC/Director/PNC_AbstractTraversal",
    "PNC/Director/Population/PNC_PopulationSandbox",
    "PNC/Director/Population/PNC_PopulationLog",
    "PNC/Director/Population/PNC_PopulationIdentity",
    "PNC/Director/Population/PNC_PopulationSectorManager",
    "PNC/Director/Population/PNC_PopulationBudget",
    "PNC/Director/Population/PNC_GenerationQueue",
    "PNC/Director/Population/PNC_GroupGenerationPlan",
    "PNC/Director/Population/PNC_SettlementGenerationPlan",
    "PNC/Director/Population/PNC_SettlementCandidateManager",
    "PNC/Director/Population/PNC_StarterPopulation",
    "PNC/Director/Population/PNC_GroupGenerator",
    "PNC/Director/Population/PNC_SettlementGenerator",
    "PNC/Director/Population/PNC_CommunityGroupFormation",
    "PNC/Director/Population/PNC_PopulationReconciler",
    "PNC/Director/Population/PNC_PopulationDirector",
    "PNC/Director/PNC_WorldDirector",
    "PNC/Director/PNC_AbstractDirectorDebug",
}
for index = 1, #expectedDirector do
    T.equal(directorCalls[index], expectedDirector[index],
        "server Director dependency " .. tostring(index))
end
T.equal(#directorCalls, #expectedDirector,
    "server Director dependency count")

PNC = { Travel = {} }
local travelCalls = capture(
    ROOT .. "shared/PNC/Core/Travel/PNC_Travel.lua"
)
local expectedTravel = {
    "PNC/Core/Travel/PNC_Travel_Route",
    "PNC/Core/Travel/PNC_Travel_Providers",
    "PNC/Core/Travel/PNC_Travel_Arrivals",
    "PNC/Core/Travel/PNC_Travel_Model",
    "PNC/Core/Travel/PNC_Travel_Projection",
    "PNC/Core/Travel/PNC_Travel_Service",
}
for index = 1, #expectedTravel do
    T.equal(travelCalls[index], expectedTravel[index],
        "shared Travel dependency " .. tostring(index))
end
T.equal(#travelCalls, #expectedTravel,
    "shared Travel dependency count")
T.finish("pnc_composition_bootstrap_smoke")

T.finish("pnc_composition_bootstrap_smoke")
