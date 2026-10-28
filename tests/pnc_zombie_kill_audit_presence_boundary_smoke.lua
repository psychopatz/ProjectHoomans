local T = require "tests/support/test"

local composition = T.read("ProjectHoomans", "client",
    "PNC/Composition/PNC_ClientComposition.lua")
local serverHooks = T.read("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter.lua")
local killBridge = T.read("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_KillBridge.lua")
local reactionService = T.read("ProjectHoomans", "server",
    "PNC/Semantics/PNC_SemanticCombatReactionService.lua")
local clientKill = T.read("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_ClientKill.lua")
local socialTransport = T.read("ProjectHoomans", "shared",
    "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Social.lua")

T.falsy(string.find(composition, "PNC_ClientZombieKillAudit", 1, true),
    "retired Hoomans client kill audit is absent from composition")
T.contains(serverHooks, "PNC_SocialEventHooks_CombatAdapter_KillBridge",
    "server combat adapter loads the lightweight kill bridge")
T.falsy(string.find(serverHooks, "CombatAdapter_Witnesses", 1, true),
    "legacy witness-event adapter is retired")
T.contains(killBridge, "SemanticCombatReactionService",
    "kill bridge delegates routine speech to semantic reaction service")
T.falsy(string.find(killBridge, "SocialEvents.Emit", 1, true),
    "routine kill bridge cannot mutate SocialEvents")
T.contains(reactionService, "MAX_PLAYER_KILL_SPEAKERS = 2",
    "routine kill fanout is explicitly bounded")
T.contains(reactionService, "PLAYER_REACTION_COOLDOWN_MS = 5000",
    "routine player-kill reactions are globally coalesced")
T.contains(reactionService, "memoryEligible = false",
    "routine kill presentation is not memory eligible")
T.contains(clientKill, "Detector.RegisterConsumer",
    "server still consumes PsychopatzCore kill authority")
T.contains(clientKill, "onServerKill = H.OnZombieDead",
    "server kill bridge remains the authoritative detector consumer")
T.contains(socialTransport, "transient = context.transientInteraction == true",
    "semantic speech transport forwards live-only lifecycle intent")
T.contains(socialTransport, "meaningful = context.meaningful ~= false",
    "semantic speech transport no longer hardcodes persistence")

T.finish("pnc_zombie_kill_audit_presence_boundary_smoke")
