local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Scheduler = require "PNC/Semantics/PNC_SemanticInteractionScheduler"
local Stimulus = require "PNC/Semantics/PNC_SemanticInteractionStimulus"
local Lifecycle = require
    "PNC/Semantics/PNC_SemanticInteractionLifecycle"
local Envelope = Lifecycle.Envelope

T.equal(Scheduler.MAX_ACTIVE_SCENES, 16,
    "baseline global scheduler ceiling is explicit")
T.equal(Scheduler.MAX_PARTICIPANTS, 4,
    "baseline participant ceiling is explicit")
T.equal(Scheduler.MAX_TURNS_PER_SCENE, 8,
    "baseline turn ceiling is explicit")
T.equal(Scheduler.MAX_RECENT_EVENTS, 8,
    "baseline recent-event ceiling is explicit")
T.equal(Scheduler.NEARBY_DISTANCE, 60,
    "baseline nearby LOD distance is explicit")

T.equal(Scheduler.ClassifyLOD({
    playerParticipant = true,
}), "player_full", "player participant gets full LOD")
T.equal(Scheduler.ClassifyLOD({
    perceived = true,
}), "nearby_perceived", "perceived nearby scene gets full presentation")
T.equal(Scheduler.ClassifyLOD({
    distance = 20,
}), "nearby_unperceived", "nearby unperceived scene is semantic-only")
T.equal(Scheduler.ClassifyLOD({
    distance = 200,
}), "distant", "distant scene is semantic-only")
T.truthy(Scheduler.RealizationPolicy("distant").semanticOnly,
    "distant policy is semantic-only")
T.falsy(Scheduler.RealizationPolicy("distant").speech,
    "distant policy suppresses speech")

local types = {}
for _, value in ipairs(Stimulus.Types()) do types[value] = true end
for _, value in ipairs({
    "HUMAN_UTTERANCE",
    "NPC_SEMANTIC_ACT",
    "EMOTE",
    "AMBIENT_SOCIAL_OPPORTUNITY",
    "WORLD_EVENT",
    "FACTION_EVENT",
    "TASK_EVENT",
    "DANGER_CHANGED",
    "ACTOR_JOINED",
    "ACTOR_LEFT",
    "WITNESSED_DEATH",
}) do
    T.truthy(types[value], "stimulus type exists: " .. value)
end

local npcSpeech = Envelope.NPCSpeech({
    actorID = "npc-a",
    targetID = "npc-b",
    act = "WARN",
    topic = "combat",
})
T.equal(npcSpeech.actorID, "npc-a",
    "NPCSpeech preserves semantic actor identity")
T.equal(npcSpeech.targetID, "npc-b",
    "NPCSpeech preserves semantic target identity")

local sceneSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionScene.lua"
)
local schedulerSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionScheduler.lua"
)
local flowSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy_Flow.lua"
)
local coreSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy_Core.lua"
)
local providerSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionProviders.lua"
)
local storageSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionLifecycle_State_Storage.lua"
)

T.contains(sceneSource, "maxActiveScenes = 1",
    "baseline Scene.New owns an isolated one-scene scheduler")
T.contains(sceneSource, "transcriptStored = false",
    "scene snapshot explicitly rejects transcript persistence")
T.contains(sceneSource, "rawText = nil",
    "scene semantic state does not retain realized/raw transcript text")
T.falsy(string.find(sceneSource, "PsychopatzSemantic.Parse", 1, true),
    "scene never reparses generated speech through NLU")
T.falsy(string.find(sceneSource, "ModData", 1, true),
    "scene owns no persistent ModData store")
T.falsy(string.find(sceneSource, "Events.OnTick", 1, true),
    "scene has no polling tick")
T.falsy(string.find(schedulerSource, "Events.OnTick", 1, true),
    "scheduler remains caller-driven rather than tick-driven")

T.contains(flowSource, "interactionDirector.Preview(",
    "normal player dialogue previews through InteractionDirector")
T.contains(coreSource, "InteractionDirector.Commit(",
    "normal player dialogue commits through InteractionDirector")
T.contains(sceneSource, "scene.scheduler:HandleStimulus(",
    "InteractionScene reaches the same scheduler/director pipeline")

T.contains(providerSource, "function Providers.RegisterActorAdapter",
    "generic actor adapter seam is public")
T.falsy(string.find(providerSource,
    'id = "projecthoomans.', 1, true),
    "baseline provider module does not install a production actor adapter")

T.contains(storageSource, 'return playerUUID .. "|" .. npcID',
    "persistent lifecycle remains player-NPC pair keyed")
T.contains(storageSource, "openQuestions = {}",
    "player-pair lifecycle owns durable conversation continuity")
T.contains(storageSource, "openCommitments = {}",
    "player-pair lifecycle owns open commitments")

T.finish("pnc_semantic_scene_runtime_s0_contract_smoke")
