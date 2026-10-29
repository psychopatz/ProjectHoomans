local T = require "tests/support/test"

local receiveSource = T.read(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_SemanticSpeechPresentation_Receive_Context.lua"
)
local buildSources = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueSuggestions_Build_Sources.lua"
)
local zombieResolution = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Zombie.lua"
)
local hitEvent = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_HitEvent.lua"
)
local reactionService = T.read(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticCombatReactionService.lua"
)
local catalog = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Social_Reactions.lua"
)

T.contains(receiveSource,
    "if not view or not view.spec or not view.spec.context",
    "current event-offer projection requires an active conversation view")
T.contains(buildSources, "\"npc_event_response_plan\"",
    "open conversation suggestions consume lifecycle event offers")

T.contains(hitEvent, "weaponItem",
    "authoritative hit context carries the actual weapon item")
T.contains(hitEvent, "weaponFullType",
    "authoritative hit context carries weapon full type")
T.contains(hitEvent, "woundType",
    "authoritative hit context carries wound type")
T.contains(zombieResolution, "partId = hit.partId",
    "zombie damage resolution receives hit body-part context")
T.contains(zombieResolution, "woundType = hit.woundType",
    "zombie damage resolution receives wound context")

local onKillCall = string.match(
    zombieResolution,
    "reactionService%.OnNPCKill%b()"
)
T.truthy(onKillCall, "zombie kill forwards a bounded spec to semantic reaction")
T.falsy(string.find(onKillCall, "weaponItem", 1, true),
    "B0 gap: OnNPCKill currently drops weapon item")
T.falsy(string.find(onKillCall, "weaponFullType", 1, true),
    "B0 gap: OnNPCKill currently drops weapon type")
T.falsy(string.find(onKillCall, "partId", 1, true),
    "B0 gap: OnNPCKill currently drops body-part result")
T.falsy(string.find(onKillCall, "woundType", 1, true),
    "B0 gap: OnNPCKill currently drops wound result")
T.falsy(string.find(onKillCall, "weaponSkill", 1, true),
    "B0 gap: OnNPCKill currently drops weapon skill")

T.contains(reactionService, "llmEligible = false",
    "routine kill reaction remains non-LLM")
T.contains(reactionService, "memoryEligible = false",
    "routine kill reaction remains non-memory")

T.contains(catalog, "\"camp_rejected\"",
    "combat-adjacent catalog includes offerless companion rejection")
T.contains(catalog, "\"default\"",
    "catalog contains generic offerless/default families")
T.falsy(string.find(catalog, "presentationClass", 1, true),
    "B0 gap: response catalog has no explicit BARK/TACTICAL_PROMPT classification")

T.finish("pnc_semantic_combat_banter_b0_boundaries_smoke")
