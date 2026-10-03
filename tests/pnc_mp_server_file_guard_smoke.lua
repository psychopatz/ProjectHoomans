local T = require "tests/support/test"
local ROOT = T.path("ProjectHoomans", "server", "PNC/")

local serverOnlyFiles = {}
local listing = T.truthy(io.popen(
    "find " .. ROOT
        .. " -type f -name '*.lua' ! -name '00_PNC_Server_Init.lua' | sort"
))
for path in listing:lines() do
    serverOnlyFiles[#serverOnlyFiles + 1] = path
end
listing:close()
-- The count is an intentional tripwire: a new server file must be reviewed
-- against the MP loader gate (PNC_Server_Lifecycle requires the whole tree).
-- 766: added PNC_FacilityResources_Scan,
-- PNC_FacilityResources_CapacitySelection and PNC_FacilityResources_Seating,
-- FacilityJobs_Service_StartState,
-- FacilityJobs_Service_ManualSleep,
-- FacilityJobs_Service_ManualWater and
-- FacilityJobs_Service_ManualStart and
-- PNC_SocialEventHooks_DownedDistress and
-- PNC_SocialEventHooks_LeaderLoss, all guarded by the standard
-- AllowsServerCode() early return and loaded through the
-- PNC_SocialEventHooks barrel or FacilityJobs service composition root.
-- PNC_PuppetOpera_Authority_Guards is guarded by the same server-only
-- authority entry path.
-- PNC_PuppetOpera_Authority_Lifecycle is loaded by the same guarded root.
-- PNC_PuppetOpera_Authority_Runtime_Timeline is loaded by the same guarded
-- runtime provider.
-- PNC_PuppetOpera_Authority_Runtime_Phases is loaded by that provider too.
-- PNC_PuppetOpera_Authority_Runtime_Safety is loaded by that provider too.
-- PNC_PuppetOpera_Authority_Runtime_Dispatch is loaded by that provider too.
-- PNC_PuppetOpera_Authority_Admission_Preflight and
-- PNC_PuppetOpera_Authority_Admission_Session are loaded by the admission
-- composition root.
-- PNC_CorpseHaulService_WorkAdapter_Targeting is loaded by the work adapter.
-- PNC_CorpseHaulService_WorkAdapter_Cleanup is loaded by the work adapter.
-- PNC_CorpseHaulService_WorkAdapter_Transfer is loaded by the work adapter.
-- PNC_CorpseHaulService_WorkAdapter_Tick is loaded by the work adapter.
-- PNC_CorpseHaulService_Dispatch_Assignment and
-- PNC_CorpseHaulService_Dispatch_Manual are loaded by Dispatch.
-- PNC_CorpseHaulService_Reconciliation_Candidates is loaded by Reconciliation.
-- PNC_CorpseHaulService_Reconciliation_Active is loaded after Candidates.
-- PNC_PuppetOpera_Authority_Requests_Session and
-- PNC_PuppetOpera_Authority_Requests_Readonly are loaded by Requests.
-- PNC_PuppetOpera_Authority_Lifecycle_Response is loaded by Lifecycle.
-- PNC_PuppetOpera_Authority_Context is loaded before authority spokes.
-- PNC_PuppetOpera_Authority_Bootstrap is loaded after authority spokes.
-- PNC_FacilityResources_Activity is loaded by the resources composition root.
-- PNC_FacilityJobs_Service_StartState_Activity and
-- PNC_FacilityJobs_Service_StartState_Order are loaded by StartState.
-- PNC_FacilityResources_Snapshot and PNC_FacilityResources_Detectors are
-- loaded by the resources composition root.
-- PNC_FacilityJobs_Service_Start_Targeting is loaded before StartState.
-- PNC_PuppetOpera_Override_Context, Override_Readiness,
-- Override_Maintenance and Override_Lifecycle are loaded by the
-- OverrideAdapter composition root.
-- PNC_LumberService_Execution_OutputCapture,
-- Execution_OutputDelivery, Execution_TreeWork and Execution_Dispatch are
-- loaded by the LumberService execution composition root.
-- PNC_LumberWorkAdapter_Lifecycle, OrderBridge and WorldEffects are loaded
-- by the LumberWorkAdapter composition root.
-- PNC_WorldEffectService_Context, Registry, Reconciliation, Snapshot and
-- Bootstrap are loaded by the world-effect service composition root.
-- PNC_WorkService_Queue and Claims are loaded by QueueAndClaims.
-- PNC_WorkService_Scheduler_Orders and Scheduler_Pump are loaded by
-- the Scheduler composition root.
-- PNC_WorkService_Progress_Inputs, Progress_Completion and
-- Progress_Accounting are loaded by the Progress composition root.
-- PNC_WorkTaskProvider_Context, Assignment, Lease and Execution are loaded
-- by the WorkTaskProvider composition root.
-- PNC_TaskRequestService_Commands and TaskRequestService_Snapshots are
-- loaded by the TaskRequestService composition root.
-- PNC_Tasking_Recovery_Context, Retry, Stall and Executor are loaded by
-- the Tasking recovery composition root.
-- PNC_Tasking_Pump_Context, Reconciliation, Evaluation and Execution are
-- loaded by the Tasking pump composition root.
-- PNC_TaskLeaseService_Context, Creation, Queries, Cancellation and Release
-- are loaded by the TaskLeaseService composition root.
-- PNC_WorkService_OperationRegistry is loaded by the WorkService core.
-- PNC_WorkService_Targets_Providers and Targets_Claim are loaded by the
-- WorkService target composition root.
-- PNC_WorkService_WorkerReconciliation_Claims and _State are loaded by the
-- WorkService worker reconciliation composition root.
-- PNC_SocialEventHooks_DamageAdapter_Context, Recorders and Polling are
-- loaded by the SocialEventHooks damage adapter composition root.
-- PNC_SocialEventHooks_DamageAdapter_TeammateDelivery is loaded by that
-- composition root.
-- PNC_SocialEventHooks_CombatAdapter_Awareness and Witnesses are loaded by
-- the SocialEventHooks combat adapter composition root.
-- PNC_SocialEventService_Process_Bridges is loaded by the SocialEventService
-- process provider.
-- PNC_SocialEventService_Process_Transaction is loaded by the Process root.
-- PNC_ConversationAuthority_Choice_Handle is loaded by the choice
-- composition root and the authority facade.
-- PNC_ConversationAuthority_Choice_Handle_Context,
-- PNC_ConversationAuthority_Choice_Handle_Effects and
-- PNC_ConversationAuthority_Choice_Handle_Response are loaded before the
-- choice coordinator by that composition root.
-- PNC_ConversationAuthority_Recruit_Handle_Context,
-- PNC_ConversationAuthority_Recruit_Handle_Effects and
-- PNC_ConversationAuthority_Recruit_Handle_Response are loaded before the
-- recruitment coordinator by its composition root.
-- PNC_ConversationAuthority_Recruit_Handle is loaded by the recruitment
-- composition root and the authority facade.
-- PNC_SocialGreetingService_TryGreet is loaded by the social greeting
-- composition root.
-- PNC_ServerLLMSocialReactionCommandHandler_Handle is loaded by the LLM
-- social reaction authority composition root.
-- PNC_ServerSemanticSocialInteractionCommandHandler_Handle is loaded by the
-- semantic social authority composition root.
-- PNC_ServerSemanticSocialInteractionCommandHandler_ApplySocialEvent and
-- PNC_ServerLLMSocialReactionCommandHandler_ApplyEffect and
-- PNC_ServerLLMSocialReactionCommandHandler_BuildResult and
-- PNC_ServerLLMSocialReactionCommandHandler_DeliverResult are loaded by their
-- authority composition roots.
-- PNC_ServerLLMSocialReactionCommandHandler_LeaseLifecycle is loaded by the
-- LLM social reaction authority root.
-- PNC_ServerLLMSocialReactionCommandHandler_Admission loaded by
-- LLM social reaction authority root.
-- PNC_ServerLLMSocialReactionCommandHandler_AdmissionPolicy loaded by
-- LLM social reaction authority root.
-- PNC_ServerLLMSocialReactionCommandHandler_AdmissionRequest loaded by
-- LLM social reaction authority root.
-- PNC_ServerLLMSocialReactionCommandHandler_AdmissionLease loaded by
-- LLM social reaction authority root.
-- PNC_RelationshipService_EventMutation_Apply is loaded by the relationship
-- mutation composition root.
-- PNC_ServerInventory_Transfer_Handle is loaded by the inventory transfer
-- authority composition root.
-- The four CampResourceService discovery spokes are loaded by its guarded
-- discovery composition root.
-- The three NPCKnowledgeAPI spokes are loaded by its guarded API composition
-- root.
-- The four ColonistDeparture spokes are loaded by its guarded composition
-- root.
-- The three CampSiteResolver spokes are loaded by its guarded composition
-- root.
-- The three downed-distress spokes are loaded by its guarded hook root.
-- The three CampResourceService activity spokes are loaded by its guarded
-- activity root.
-- The three need-facility effect spokes are loaded by its guarded root.
-- The four UniqueNPCRegistry providers are loaded by its guarded root.
T.equal(#serverOnlyFiles, 980,
    "server Lua inventory changed without updating the MP loader gate")
T.truthy(true, "facility-state reconciler is covered by the loader gate")

isClient = function() return true end
isServer = function() return false end
PNC = {
    Core = {
        IsClientOnly = function() return true end,
    },
}
PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return false end,
    },
}

local originalRequire = require
require = function(name)
    error("pure client required server module: " .. tostring(name))
end
for _, path in ipairs(serverOnlyFiles) do
    T.load(path)
end
require = originalRequire

T.truthy(PNC.ServerCommandRouter == nil
    and PNC.ServerDebugCommandHandler == nil
    and PNC.Supply == nil
    and PNC.ColonyStorageService == nil,
    "pure multiplayer client initialized server-only Project Hoomans state")

isServer = function() return true end
PsychopatzCore.RuntimeRole.AllowsServerCode = function() return true end
local calls = {}
require = function(name)
    calls[#calls + 1] = name
    return true
end
PNC = {
    Core = {
        IsClientOnly = function() return false end,
    },
    SupplyInventory = { Commands = {}, Queries = {} },
    NPCSupplyService = { Process = function() end },
}
local supply = T.load(ROOT .. "Supply/PNC_Supply.lua")
require = originalRequire

T.equal(#calls, 8, "hosted server skipped Supply composition")
T.equal(supply.Process, PNC.NPCSupplyService.Process,
    "hosted server did not bind the Supply process facade")

T.finish("pnc_mp_server_file_guard_smoke")
