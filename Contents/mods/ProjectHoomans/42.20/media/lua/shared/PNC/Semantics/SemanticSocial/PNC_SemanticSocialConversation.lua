-- Autonomous NPC semantic-choice controller for one existing InteractionScene.
-- The controller reuses generated semantic affordances as NPC input and sends
-- the selected typed act back into the same Scene. InteractionDirector remains
-- the authority that decides the addressee's response.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Affordances = require
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_GeneratedAffordanceProvider"
local ChoicePolicy = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialChoicePolicy"
local TurnPolicy = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialTurnPolicy"

local Conversation = PNC.Semantics.SocialConversation or {}
PNC.Semantics.SocialConversation = Conversation

Conversation.VERSION = 1
Conversation.MAX_HISTORY = 8
Conversation.MAX_STEPS = 6
Conversation.INTERJECTION_SCORE = 0.72
Conversation.INTERJECTION_MOTIVES = {
    WARN = true,
    REACT = true,
    SOCIALIZE = true,
    DISPUTE = true,
    COORDINATE = true,
}

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 5 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 32 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function cleanID(value)
    value = tostring(value or "")
    if value == "" or #value > 128
        or string.find(value, "[^%w_%.:%-]")
    then
        return nil
    end
    return value
end

local function actorName(participant, projection)
    local actor = type(participant) == "table"
        and type(participant.actor) == "table"
        and participant.actor or {}
    local identity = type(actor.identity) == "table" and actor.identity or {}
    return tostring(
        actor.displayName or actor.name
        or identity.displayName or identity.fullName or identity.name
        or projection and projection.actor and projection.actor.name
        or ""
    )
end

local function projectionFor(scene, actorID, otherID)
    local participant = scene.participants and scene.participants[actorID]
    local other = scene.participants and scene.participants[otherID]
    if not participant then return nil, "social_actor_unknown" end
    if type(participant.projection) == "table" then
        return copy(participant.projection)
    end
    if participant.actor == nil then
        return nil, "social_actor_projection_unavailable"
    end
    return Providers.ProjectExternalContext(
        participant.actor,
        other and other.actor or nil,
        participant.adapterContext
    )
end

local function responsePlan(result)
    local presentation = type(result) == "table"
        and type(result.presentation) == "table"
        and result.presentation or {}
    local speech = type(presentation.speech) == "table"
        and presentation.speech or {}
    return type(speech.plan) == "table" and speech.plan or nil
end

local function currentTurnIdentity(result, social)
    result = type(result) == "table" and result or {}
    social = type(social) == "table" and social or {}
    local history = type(result.semanticHistoryEvent) == "table"
        and result.semanticHistoryEvent or {}
    local speakerID = cleanID(history.targetActorID or history.targetID)
    local recipientID = cleanID(history.sourceActorID or history.sourceID)
    if not recipientID then
        local continuation = type(result.continuation) == "table"
            and result.continuation or {}
        recipientID = cleanID(continuation.targetID)
    end
    recipientID = recipientID or cleanID(social.recipientID)
    return speakerID, recipientID
end

local function semanticIR(result)
    local plan = type(result) == "table"
        and type(result.interactionPlan) == "table"
        and result.interactionPlan or {}
    local act = plan.dialogueAct or plan.behaviorAct
    return {
        intent = act,
        speechAct = act,
        subject = plan.subject,
        extensions = {
            topic = plan.topic,
        },
    }
end

local function frameToRequest(frame, actorID, targetID, currentResult, social)
    frame = type(frame) == "table" and frame or {}
    local plan = type(currentResult) == "table"
        and type(currentResult.interactionPlan) == "table"
        and currentResult.interactionPlan or {}
    local dynamic = type(frame.extensions) == "table"
        and type(frame.extensions.dynamicAffordance) == "table"
        and frame.extensions.dynamicAffordance or {}
    return {
        sourceID = actorID,
        responderID = targetID,
        intent = frame.intent,
        speechAct = frame.speechAct or frame.intent,
        subject = frame.subject,
        topic = frame.topic or plan.topic or social.topic,
        factRefs = copy(plan.groundedFactRefs) or {},
        eventRefs = copy(plan.groundedEventRefs) or {},
        modifiers = {
            socialMotive = social.motive,
            semanticStrategy = dynamic.strategy,
            selectedBy = "social_choice_policy",
        },
        providerID = "semantic.social_conversation",
    }
end

function Conversation.New(options)
    options = type(options) == "table" and options or {}
    local instance = {
        historyByScene = {},
        contextByScene = {},
        audienceByScene = {},
        effectSink = type(options.effectSink) == "function"
            and options.effectSink or nil,
        lastDecision = nil,
        metrics = {
            evaluations = 0,
            emitted = 0,
            silence = 0,
            playerWaits = 0,
            interjections = 0,
            consequenceAttempts = 0,
            consequencesApplied = 0,
        },
    }
    local Methods = {}

    function Methods:RegisterScene(scene, social, audience)
        local sceneID = scene and cleanID(scene.id) or nil
        if not sceneID then return false, "social_scene_id_invalid" end
        self.contextByScene[sceneID] = copy(social) or {}
        self.audienceByScene[sceneID] = copy(audience) or {}
        return true
    end

    function Methods:SceneContext(sceneID)
        sceneID = cleanID(sceneID)
        if not sceneID then return nil end
        return self.contextByScene[sceneID]
    end

    function Methods:SceneAudience(sceneID)
        sceneID = cleanID(sceneID)
        if not sceneID then return {} end
        return self.audienceByScene[sceneID] or {}
    end

    function Methods:ForgetScene(sceneID)
        sceneID = cleanID(sceneID)
        if not sceneID then return false end
        self.historyByScene[sceneID] = nil
        self.contextByScene[sceneID] = nil
        self.audienceByScene[sceneID] = nil
        return true
    end

    function Methods:History(sceneID)
        sceneID = cleanID(sceneID)
        if not sceneID then return {} end
        self.historyByScene[sceneID] =
            self.historyByScene[sceneID] or {}
        return self.historyByScene[sceneID]
    end

    function Methods:Remember(sceneID, actorID, candidate)
        if type(candidate) ~= "table" then return end
        local history = self:History(sceneID)
        history[#history + 1] = {
            speaker = actorID,
            strategy = candidate.strategy,
            stance = candidate.stance,
        }
        while #history > Conversation.MAX_HISTORY do
            table.remove(history, 1)
        end
    end

    function Methods:BuildChoice(scene, result, actorID, targetID, social)
        local participant = scene.participants
            and scene.participants[actorID] or nil
        if not participant or participant.isPlayer == true then
            return {
                selected = nil,
                reason = participant and "player_input_required"
                    or "actor_missing",
                targetID = targetID,
            }
        end
        local projected, reason = projectionFor(
            scene, actorID, targetID
        )
        if not projected then
            return {
                selected = nil,
                reason = reason,
                targetID = targetID,
            }
        end
        local actor = type(projected.actor) == "table"
            and projected.actor or {}
        local responder = {
            actorID = actorID,
            turnSpeaker = actorID,
            name = actorName(participant, projected),
            traits = actor.traits,
            visibility = "semantic",
        }
        local affordanceContext = {
            dialogueIR = semanticIR(result),
            interactionPlan = copy(result.interactionPlan),
            sceneResponsePlan = copy(responsePlan(result)),
            interactionProjection = projected,
            semanticContextState = scene.semanticState,
            affordanceRecentTurns = copy(self:History(scene.id)),
            affordanceRecipientRef = targetID,
        }
        local frontier = Affordances.collectForResponder(
            affordanceContext, responder
        )
        local choice = ChoicePolicy.Select(frontier, {
            motive = social.motive,
            relevance = social.relevance,
            responderProjection = projected,
            silenceThreshold = social.silenceThreshold,
            allowedStrategies = social.allowedStrategies,
            forbiddenStrategies = social.forbiddenStrategies,
        })
        choice.targetID = targetID
        choice.frontierCount = #frontier
        choice.actorID = actorID
        return choice
    end

    function Methods:EvaluateTurn(scene, result, social)
        self.metrics.evaluations = self.metrics.evaluations + 1
        social = type(social) == "table" and social or {}
        local speakerID, recipientID =
            currentTurnIdentity(result, social)
        if not speakerID then
            return {
                mode = "terminate",
                reason = "social_current_speaker_missing",
                choicesByActor = {},
            }
        end
        if not recipientID then
            return {
                mode = "terminate",
                reason = "social_current_recipient_missing",
                choicesByActor = {},
            }
        end

        -- The current resolved line has now been presented to its explicit
        -- addressee. Record its grounded refs only in Scene-local disclosure
        -- state so the addressee may respond to what it just heard without
        -- fabricating durable world knowledge.
        if type(scene.RememberPresentedRefs) == "function" then
            scene:RememberPresentedRefs(recipientID, result)
        end

        local choices = {}
        local interjections = {}
        for _, actorID in ipairs(scene.participantOrder or {}) do
            if actorID ~= speakerID then
                local participant = scene.participants[actorID]
                if participant and participant.isPlayer ~= true then
                    choices[actorID] = self:BuildChoice(
                        scene, result, actorID, speakerID, social
                    )
                    if actorID ~= recipientID
                        and Conversation.INTERJECTION_MOTIVES[
                            tostring(social.motive or "")
                        ] == true
                        and choices[actorID].selected ~= nil
                        and (tonumber(choices[actorID].selectedScore) or 0)
                            >= Conversation.INTERJECTION_SCORE
                    then
                        local actor = choices[actorID]
                        interjections[actorID] = {
                            allowed = true,
                            priority = math.max(
                                0,
                                (tonumber(actor.selectedScore) or 0) - 0.6
                            ),
                            motive = social.motive,
                        }
                    end
                end
            end
        end

        local event = type(result.semanticHistoryEvent) == "table"
            and result.semanticHistoryEvent or {}
        local priorSourceID = cleanID(event.sourceActorID or event.sourceID)
        local priorSource = priorSourceID and scene.participants
            and scene.participants[priorSourceID] or nil
        local playerHasJustSpoken = priorSource
            and priorSource.isPlayer == true

        local decision = TurnPolicy.Select({
            participants = (function()
                local rows = {}
                for _, id in ipairs(scene.participantOrder or {}) do
                    local p = scene.participants[id]
                    rows[#rows + 1] = {
                        id = id,
                        actor = p and p.actor,
                        kind = p and p.kind,
                        isPlayer = p and p.isPlayer,
                    }
                end
                return rows
            end)(),
            currentSpeakerID = speakerID,
            currentRecipientID = recipientID,
            choicesByActor = choices,
            interjections = interjections,
            allowInterjectionOverPlayerWait =
                social.allowNpcAfterPlayer == true
                and playerHasJustSpoken == true
                and scene.participants
                and scene.participants[recipientID]
                and scene.participants[recipientID].isPlayer == true,
        })
        decision.currentSpeakerID = speakerID
        decision.currentRecipientID = recipientID
        decision.choicesByActor = choices
        return decision
    end

    function Methods:Advance(scene, result, social)
        local turn = self:EvaluateTurn(scene, result, social)
        self.lastDecision = copy(turn)
        if turn.mode == "wait_player" then
            self.metrics.playerWaits = self.metrics.playerWaits + 1
            return {
                mode = "wait_player",
                decision = turn,
            }
        end
        if turn.mode ~= "emit" then
            self.metrics.silence = self.metrics.silence + 1
            return {
                mode = "terminate",
                reason = turn.reason,
                decision = turn,
            }
        end

        local choice = turn.choice
        local candidate = type(choice) == "table"
            and choice.selected or nil
        local frame = candidate and candidate.frame or nil
        if type(frame) ~= "table" then
            self.metrics.silence = self.metrics.silence + 1
            return {
                mode = "terminate",
                reason = "selected_affordance_frame_missing",
                decision = turn,
            }
        end

        local request = frameToRequest(
            frame,
            turn.actorID,
            turn.targetID,
            result,
            social
        )
        local nextResult, reason = scene:EmitSemanticAct(request)
        if not nextResult then
            return {
                mode = "failed",
                reason = reason,
                decision = turn,
                selected = candidate,
                request = request,
            }
        end

        local consequence
        if self.effectSink then
            self.metrics.consequenceAttempts =
                self.metrics.consequenceAttempts + 1
            local applied = self.effectSink({
                sceneID = scene.id,
                sequence = scene.semanticState
                    and scene.semanticState.sequence or 0,
                request = copy(request),
                strategy = candidate.strategy,
                motive = social.motive,
            })
            if type(applied) == "table" then
                consequence = {
                    accepted = applied.accepted == true,
                    applied = applied.applied == true,
                    reason = applied.reason,
                    eventType = applied.eventType,
                    eventID = applied.eventID,
                }
                if applied.applied == true then
                    self.metrics.consequencesApplied =
                        self.metrics.consequencesApplied + 1
                end
            end
        end

        self:Remember(scene.id, turn.actorID, candidate)
        self.metrics.emitted = self.metrics.emitted + 1
        if turn.reason == "explicit_interjection" then
            self.metrics.interjections = self.metrics.interjections + 1
        end
        local terminal = nextResult.skipped == true
            or nextResult.interactionPlan == nil
        return {
            mode = "emit",
            terminal = terminal,
            terminalReason = terminal
                and (nextResult.reason or "social_no_response") or nil,
            decision = turn,
            selected = candidate,
            selectedPresentation = {
                actorID = turn.actorID,
                recipientID = turn.targetID,
                strategy = candidate.strategy,
                stance = candidate.stance,
                text = candidate.display
                    and (candidate.display.utterance
                        or candidate.display.label),
                utterancePlan = copy(candidate.utterancePlan),
            },
            request = request,
            consequence = consequence,
            result = nextResult,
        }
    end

    function Methods:Run(scene, result, social, options)
        options = type(options) == "table" and options or {}
        local maximum = math.min(
            Conversation.MAX_STEPS,
            math.max(1, math.floor(tonumber(options.maxSteps) or 3))
        )
        local steps = {}
        local current = result
        for _ = 1, maximum do
            local step = self:Advance(scene, current, social)
            steps[#steps + 1] = step
            if step.mode ~= "emit" then
                return {
                    schemaVersion = Conversation.VERSION,
                    mode = step.mode,
                    reason = step.reason,
                    steps = steps,
                    finalResult = current,
                }
            end
            current = step.result
            if step.terminal == true then
                if scene.status == "active" and type(scene.Close) == "function" then
                    scene:Close(step.terminalReason or "social_no_response")
                end
                return {
                    schemaVersion = Conversation.VERSION,
                    mode = "closed",
                    reason = step.terminalReason or "social_no_response",
                    steps = steps,
                    finalResult = current,
                }
            end
            if scene.status ~= "active" then
                return {
                    schemaVersion = Conversation.VERSION,
                    mode = "closed",
                    reason = "scene_closed",
                    steps = steps,
                    finalResult = current,
                }
            end
        end
        return {
            schemaVersion = Conversation.VERSION,
            mode = "step_limit",
            reason = "social_step_limit",
            steps = steps,
            finalResult = current,
        }
    end

    function Methods:Snapshot()
        local sceneCount = 0
        for _ in pairs(self.historyByScene) do sceneCount = sceneCount + 1 end
        local contextCount = 0
        for _ in pairs(self.contextByScene) do contextCount = contextCount + 1 end
        local decision = type(self.lastDecision) == "table"
            and self.lastDecision or nil
        local rows = {}
        for index = 1, math.min(
            #(decision and type(decision.rows) == "table"
                and decision.rows or {}),
            TurnPolicy.MAX_PARTICIPANTS
        ) do
            local row = decision.rows[index]
            rows[#rows + 1] = {
                actorID = cleanID(row.actorID),
                role = tostring(row.role or ""),
                eligible = row.eligible == true,
                reason = tostring(row.reason or ""),
                score = tonumber(row.score),
                waitForPlayer = row.waitForPlayer == true,
                targetID = cleanID(row.targetID),
            }
        end
        local choices = {}
        for actorID, choice in pairs(
            decision and type(decision.choicesByActor) == "table"
                and decision.choicesByActor or {}
        ) do
            if #choices >= TurnPolicy.MAX_PARTICIPANTS then break end
            local selected = type(choice) == "table"
                and type(choice.selected) == "table"
                and choice.selected or nil
            local frontier = {}
            for index = 1, math.min(
                #(type(choice) == "table"
                    and type(choice.rows) == "table"
                    and choice.rows or {}),
                ChoicePolicy.MAX_CANDIDATES
            ) do
                local candidate = choice.rows[index]
                frontier[#frontier + 1] = {
                    candidateID = tostring(candidate.candidateID or ""),
                    strategy = tostring(candidate.strategy or ""),
                    eligible = candidate.eligible == true,
                    reason = tostring(candidate.reason or ""),
                    score = tonumber(candidate.score),
                }
            end
            choices[#choices + 1] = {
                actorID = cleanID(actorID),
                reason = type(choice) == "table"
                    and tostring(choice.reason or "") or "",
                selectedID = selected and tostring(selected.id or "") or nil,
                selectedStrategy = selected
                    and tostring(selected.strategy or "") or nil,
                selectedScore = type(choice) == "table"
                    and tonumber(choice.selectedScore) or nil,
                frontierCount = type(choice) == "table"
                    and tonumber(choice.frontierCount) or nil,
                frontier = frontier,
            }
        end
        table.sort(choices, function(left, right)
            return tostring(left.actorID or "")
                < tostring(right.actorID or "")
        end)
        return {
            schemaVersion = Conversation.VERSION,
            metrics = copy(self.metrics),
            historySceneCount = sceneCount,
            contextSceneCount = contextCount,
            lastDecision = decision and {
                mode = tostring(decision.mode or ""),
                reason = tostring(decision.reason or ""),
                actorID = cleanID(decision.actorID),
                targetID = cleanID(decision.targetID),
                currentSpeakerID = cleanID(decision.currentSpeakerID),
                currentRecipientID = cleanID(decision.currentRecipientID),
                motive = tostring(decision.motive or ""),
                rows = rows,
                choices = choices,
            } or nil,
        }
    end

    return setmetatable(instance, { __index = Methods })
end

return Conversation
