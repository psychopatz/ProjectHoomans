local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}

local current = 1000
PNC = {
    Semantics = {},
    Core = {
        Now = function() return current end,
    },
}

local DirectorMethods = {}
function DirectorMethods:Submit(spec)
    spec = type(spec) == "table" and spec or {}
    local opportunity = {
        motive = spec.motive or "SOCIALIZE",
        relevance = tonumber(spec.relevance) or 0.8,
        priority = tonumber(spec.priority) or 20,
        speakerID = spec.speakerID or "npc-a",
        recipientID = spec.recipientID or "npc-b",
        participants = {
            { id = spec.speakerID or "npc-a" },
            { id = spec.recipientID or "npc-b" },
        },
        topic = spec.topic or "SOCIAL",
        eventType = spec.eventType or "AMBIENT_SOCIAL_OPPORTUNITY",
        eventID = spec.eventID or "audit-event",
        areaKey = spec.areaKey or "camp",
        bypassBudget = spec.bypassBudget == true,
    }
    if spec.reject == "normalize" then
        self.lastDecision = {
            accepted = false,
            reason = "social_relevance_low",
        }
        return {
            accepted = false,
            reason = "social_relevance_low",
        }
    elseif spec.reject == "budget" then
        self.lastDecision = {
            accepted = false,
            reason = "social_actor_cooldown",
            opportunity = opportunity,
        }
        return {
            accepted = false,
            reason = "social_actor_cooldown",
            opportunity = opportunity,
        }
    end
    self.lastDecision = {
        accepted = true,
        reason = "social_scene_admitted",
        sceneID = "scene:audit",
        opportunity = opportunity,
    }
    return {
        accepted = true,
        sceneID = "scene:audit",
        socialOpportunity = opportunity,
    }
end

function DirectorMethods:Snapshot()
    return {
        metrics = {
            submitted = 4,
            admitted = 2,
            rejected = 2,
        },
    }
end

local ConversationMethods = {}
function ConversationMethods:EvaluateTurn(_, _, social)
    return {
        mode = "emit",
        reason = "recipient_reply",
        actorID = "npc-b",
        targetID = "npc-a",
        currentSpeakerID = "npc-a",
        currentRecipientID = "npc-b",
        choice = {
            selected = {
                strategy = "CHALLENGE",
            },
        },
        choicesByActor = {
            ["npc-b"] = {
                targetID = "npc-a",
                frontierCount = 2,
                selected = {
                    strategy = "CHALLENGE",
                    stance = "NEGATIVE",
                },
                selectedScore = 0.81,
                reason = "highest_contextual_affordance",
                rows = {
                    {
                        candidateID = "generated.challenge",
                        strategy = "CHALLENGE",
                        eligible = true,
                        score = 0.81,
                        reason = "eligible",
                        modifiers = {
                            {
                                reason = "motive_fit:DISPUTE",
                                delta = 0.2,
                            },
                        },
                    },
                },
            },
        },
        motive = social and social.motive,
    }
end

function ConversationMethods:Snapshot()
    return {
        metrics = {
            evaluations = 3,
            emitted = 2,
            silence = 1,
        },
    }
end

local director = setmetatable({
    lastDecision = nil,
}, { __index = DirectorMethods })

local conversation = setmetatable({}, { __index = ConversationMethods })

local Audit = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticSocialDirectorAudit.lua"
)

Audit.ResetForTests()
Audit.Bind(director, conversation)

T.falsy(Audit.IsEnabled(), "social director audit defaults disabled")
T.equal(director.Submit, DirectorMethods.Submit,
    "disabled audit leaves original director method untouched")
T.equal(conversation.EvaluateTurn, ConversationMethods.EvaluateTurn,
    "disabled audit leaves original conversation method untouched")
T.equal(Audit.BuildSnapshot().instrumentation, "detached",
    "disabled snapshot explicitly reports detached instrumentation")
T.equal(Audit.BuildSnapshot().eventCount, 0,
    "disabled audit has no capture rows")

director:Submit({ reject = "budget" })
conversation:EvaluateTurn(
    { id = "scene:off" },
    {},
    { motive = "DISPUTE", relevance = 0.9, topic = "SOCIAL" }
)
T.equal(Audit.BuildSnapshot().eventCount, 0,
    "normal decisions execute without any audit capture while disabled")

Audit.SetEnabled(true)
T.truthy(Audit.IsEnabled(), "audit can be explicitly enabled")
T.truthy(director.Submit ~= DirectorMethods.Submit,
    "enabled audit temporarily wraps director Submit")
T.truthy(conversation.EvaluateTurn ~= ConversationMethods.EvaluateTurn,
    "enabled audit temporarily wraps conversation EvaluateTurn")

director:Submit({
    reject = "budget",
    motive = "SOCIALIZE",
    speakerID = "npc-a",
    recipientID = "npc-b",
})
current = current + 10
conversation:EvaluateTurn(
    { id = "scene:audit" },
    {},
    { motive = "DISPUTE", relevance = 0.9, topic = "SOCIAL" }
)

local snapshot = Audit.BuildSnapshot()
T.truthy(snapshot.enabled, "snapshot reports capture enabled")
T.equal(snapshot.instrumentation, "runtime_wrapped",
    "enabled snapshot reports temporary runtime wrappers")
T.equal(snapshot.eventCount, 2, "enabled wrappers capture bounded decisions")
T.equal(snapshot.rows[1].source, "conversation",
    "debug rows are returned newest first")
T.equal(snapshot.rows[1].selectedStrategy, "CHALLENGE",
    "turn audit preserves chosen semantic strategy")
T.equal(snapshot.rows[1].choices[1].candidates[1].strategy, "CHALLENGE",
    "turn audit preserves bounded candidate reasoning")
T.equal(
    snapshot.rows[1].choices[1].candidates[1].modifiers[1].reason,
    "motive_fit:DISPUTE",
    "turn audit preserves score modifier reasons"
)
T.equal(snapshot.rows[2].source, "director",
    "admission decision remains inspectable")
T.equal(snapshot.rows[2].stage, "budget",
    "admission audit identifies chatter-budget suppression")
T.equal(snapshot.rows[2].reason, "social_actor_cooldown",
    "admission suppression reason remains inspectable")
T.equal(snapshot.director.metrics.submitted, 4,
    "snapshot includes on-demand director metrics")
T.equal(snapshot.conversation.metrics.evaluations, 3,
    "snapshot includes on-demand conversation metrics")

for index = 1, Audit.MAX_EVENTS + 7 do
    current = current + 1
    director:Submit({
        eventID = "stress-" .. tostring(index),
        speakerID = "npc-" .. tostring(index),
        recipientID = "npc-target-" .. tostring(index),
    })
end
snapshot = Audit.BuildSnapshot()
T.equal(snapshot.eventCount, Audit.MAX_EVENTS,
    "audit ring buffer remains bounded")
T.truthy(snapshot.dropped >= 9,
    "audit reports discarded oldest rows after ring-buffer saturation")

local wrappedSubmit = director.Submit
local rowsBeforeDisable = snapshot.eventCount
Audit.SetEnabled(false)
T.falsy(Audit.IsEnabled(), "audit can be disabled at runtime")
T.equal(director.Submit, DirectorMethods.Submit,
    "disabling audit restores original director method")
T.equal(conversation.EvaluateTurn, ConversationMethods.EvaluateTurn,
    "disabling audit restores original conversation method")

director:Submit({})
conversation:EvaluateTurn(
    { id = "scene:off-again" },
    {},
    { motive = "SOCIALIZE", relevance = 0.9 }
)
snapshot = Audit.BuildSnapshot()
T.equal(snapshot.eventCount, rowsBeforeDisable,
    "disabled gameplay calls remain completely outside capture path")

wrappedSubmit(director, {})
snapshot = Audit.BuildSnapshot()
T.equal(snapshot.eventCount, rowsBeforeDisable,
    "stale enabled wrapper cannot retain rows after capture is disabled")
T.falsy(snapshot.enabled, "disabled state is visible to debug UI")

Audit.Clear()
T.equal(Audit.BuildSnapshot().eventCount, 0,
    "capture can be cleared without persistence")

local source = T.read(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticSocialDirectorAudit.lua"
)
T.falsy(string.find(source, "Events.OnTick", 1, true),
    "audit has no polling tick")
T.falsy(string.find(source, "ModData", 1, true),
    "audit has no persistent ModData root")
T.falsy(string.find(source, "Registry.ForEachLive", 1, true),
    "audit never scans the live NPC registry")
T.falsy(string.find(source, "getZombieList", 1, true),
    "audit never scans zombies")
T.falsy(string.find(source, "transcriptText", 1, true),
    "audit stores no conversation transcript")

local directorSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialDirector.lua"
)
local conversationSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialConversation.lua"
)
T.falsy(string.find(directorSource, "auditHook", 1, true),
    "disabled director hot path contains no audit branch")
T.falsy(string.find(conversationSource, "auditHook", 1, true),
    "disabled conversation hot path contains no audit branch")

T.finish("pnc_semantic_social_debug_audit_smoke")
