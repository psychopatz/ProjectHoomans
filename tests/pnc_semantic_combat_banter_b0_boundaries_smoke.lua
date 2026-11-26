local T = require "tests/support/test"

local receiveSource = T.read(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_SemanticSpeechPresentation_Receive_Context.lua"
)
local buildSources = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/ConvoEngine/Dialogue/Suggestions_Build_Sources.lua"
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
    "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua"
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
T.contains(onKillCall, "weaponItem = hit.weaponItem",
    "B5 forwards the actual resolved weapon item")
T.contains(onKillCall, "weaponFullType = hit.weaponFullType",
    "B5 forwards the actual resolved weapon type")
T.contains(onKillCall, "partId = hit.partId",
    "B5 forwards the authoritative hit body part")
T.contains(onKillCall, "woundType = hit.woundType",
    "B5 forwards the authoritative wound type")
T.contains(reactionService, "CombatWeaponContext",
    "B5 derives skill/family from one canonical weapon context")

T.contains(reactionService, "llmEligible = false",
    "routine kill reaction remains non-LLM")
T.contains(reactionService, "memoryEligible = false",
    "routine kill reaction remains non-memory")

local directives = io.open(
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/commands/companion_directives.convo",
    "r"
)
local dirText = directives and directives:read("*a") or ""
if directives then directives:close() end
local reactions = io.open(
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/combat/combat_horde_reactions.convo",
    "r"
)
local reactText = reactions and reactions:read("*a") or ""
if reactions then reactions:close() end

T.contains(dirText, "camp_rejected",
    "combat-adjacent catalog includes offerless companion rejection")
T.contains(reactText, "default",
    "catalog contains generic offerless/default families")
T.contains(reactText, "combat.style",
    "style-aware combat variants are explicit catalog predicates")

T.finish("pnc_semantic_combat_banter_b0_boundaries_smoke")
