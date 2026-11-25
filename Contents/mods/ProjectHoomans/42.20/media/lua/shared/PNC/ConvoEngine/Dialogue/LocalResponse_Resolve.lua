-- Semantic response branch resolver provider.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Response = PNC.ConvoEngine.LocalResponse
local Internal = Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local targetText = Internal.TargetText
local socialCounts = Internal.SocialCounts
local followsRelationshipStatusAnswer =
    Internal.FollowsRelationshipStatusAnswer
local followsQuestionAnswer = Internal.FollowsQuestionAnswer
local resolveQuestion = Internal.ResolveQuestion
local FarewellRole = require "PNC/ConvoEngine/Dialogue/FarewellRole"

local function wellbeingFactsUnknown(context)
    local situation = type(context) == "table"
        and context.dialogueSituation or nil
    local npc = type(situation) == "table" and situation.npc or nil
    local healthState = type(npc) == "table" and npc.healthState or nil
    local needs = type(npc) == "table" and npc.needs or nil
    local emotion = type(npc) == "table" and npc.emotion or nil
    local healthUnknown = type(healthState) ~= "string"
        or healthState == ""
        or healthState == "unknown"
    return healthUnknown
        and (type(needs) ~= "table" or needs.highest == nil)
        and (type(emotion) ~= "table" or emotion.highest == nil)
end

local function groundedWellbeingEligible(context)
    local situation = type(context) == "table"
        and context.dialogueSituation or nil
    local npc = type(situation) == "table" and situation.npc or nil
    local healthState = type(npc) == "table" and npc.healthState or nil
    local personality = type(context) == "table"
        and context.npcPersonality or nil
    local authoredStyle = type(personality) == "table"
        and personality.socialStyle or nil
    return (healthState == "injured"
            or healthState == "wounded"
            or healthState == "critical")
        and (authoredStyle == "friendly"
            or authoredStyle == "protective"
            or authoredStyle == "withdrawn")
end

function Response.ResolveFlow(ir, state, context, flow)
    if type(flow) ~= "table" or flow.matched ~= true then
        return nil, "flow_response_not_matched"
    end
    local poolID = tostring(flow.responsePool or "")
    if poolID == "" then return nil, "flow_response_pool_unavailable" end
    if poolID == "semantic.question.identity"
        and Internal.IdentityKnown(context)
        and type(resolveQuestion) == "function"
    then
        local knownResponse = resolveQuestion(
            ir, state, context
        )
        if type(knownResponse) == "table" then
            knownResponse.selectionSource = "flow"
            knownResponse.sourceFlowID = flow.flowId
            knownResponse.flowTransition = flow.transition
            return knownResponse
        end
    end
    local response = catalogResponse(poolID, ir, state, context)
    if type(response) ~= "table" then
        return nil, "flow_response_variant_unavailable"
    end
    -- The wellbeing flow owns the exchange, but its broad pool is only the
    -- default response source. Let the shared question resolver replace it
    -- with a more specific grounded/personality pool when the same
    -- authoritative situation supports one. This keeps flow ownership and
    -- response planning separate without duplicating a dialogue engine.
    if poolID == "semantic.question.wellbeing"
        and type(Response.Resolve) == "function"
        and (wellbeingFactsUnknown(context)
            or groundedWellbeingEligible(context))
    then
        local contextual = Response.Resolve(
            ir, state, context, "QUESTION_RECEIVED"
        )
        if type(contextual) == "table"
            and contextual.sourcePoolID ~= poolID
        then
            response = contextual
        end
    end
    response.selectionSource = "flow"
    response.sourceFlowID = flow.flowId
    response.flowTransition = flow.transition
    return response
end

local function detectWorldTopicFollowUpKind(ir)
    if type(ir) ~= "table" then return nil end
    local act = ir.slots and tostring(ir.slots.dialogueAct or "") or ""
    local speechAct = string.upper(tostring(ir.speechAct or ir.intent or ""))
    if act == "ASK_WHERE" then return "where" end
    if act == "ASK_WHEN" then return "when" end
    if act == "ASK_WHO" then return "who" end
    if act == "ASK_ELABORATE" then return "more" end
    if act == "STANCE_POSITIVE" or speechAct == "AGREE" or speechAct == "PRAISE" or speechAct == "REASSURE" then
        return "stance_positive"
    end
    if act == "STANCE_NEGATIVE" or speechAct == "DISAGREE" or speechAct == "CRITICIZE" or speechAct == "ANTAGONIZE" then
        return "stance_negative"
    end
    if act == "STANCE_NEUTRAL" or speechAct == "CLARIFY" then
        return "stance_neutral"
    end
    local text = string.lower(tostring(ir.normalizedText or ir.rawText or ""))
    if text == "where" or text == "where was that" or text == "where is that" then
        return "where"
    end
    if text == "when" or text == "when did that happen" or text == "when was that" then
        return "when"
    end
    if text == "who" or text == "who was that" or text == "who told you" then
        return "who"
    end
    if string.find(text, "bullshit", 1, true) or string.find(text, "don't buy", 1, true)
        or string.find(text, "nonsense", 1, true) or string.find(text, "disagree", 1, true)
    then
        return "stance_negative"
    end
    if string.find(text, "i agree", 1, true) or string.find(text, "good point", 1, true)
        or string.find(text, "makes sense", 1, true) or string.find(text, "hope so", 1, true)
    then
        return "stance_positive"
    end
    if string.find(text, "not sure", 1, true) or string.find(text, "hard to say", 1, true) then
        return "stance_neutral"
    end
    if text == "tell me more" or text == "more" or text == "what else"
        or text == "elaborate" or string.find(text, "what should we do", 1, true)
    then
        return "more"
    end
    return nil
end

local function buildWorldTopicTokens(topic)
    local timeLabel = type(topic.timeLabel) == "string" and topic.timeLabel ~= ""
        and topic.timeLabel or "recently"
    local locLabel = type(topic.locationLabel) == "string" and topic.locationLabel ~= ""
        and topic.locationLabel or "nearby"
    local headline = type(topic.headline) == "string" and topic.headline ~= ""
        and topic.headline or ""
    local raidCount = tonumber(topic.raidCount or (topic.meta and topic.meta.count)) or 3
    local meta = type(topic.meta) == "table" and topic.meta or {}
    local channelName = type(meta.channelName) == "string" and meta.channelName ~= ""
        and meta.channelName or "the broadcast"
    local showName = type(meta.showName) == "string" and meta.showName ~= ""
        and meta.showName or (headline ~= "" and headline or channelName)
    local episode = type(meta.episode) == "string" and meta.episode ~= ""
        and meta.episode or showName
    local topicLabel = type(meta.topicLabel) == "string" and meta.topicLabel ~= ""
        and meta.topicLabel or (headline ~= "" and headline or showName)
    return {
        ["slot.gossip_time"] = timeLabel,
        ["slot.gossip_location"] = locLabel,
        ["slot.gossip_headline"] = headline,
        ["slot.gossip_raid_count"] = tostring(raidCount),
        ["slot.show.name"] = showName,
        ["slot.broadcast.channel"] = channelName,
        ["slot.broadcast.episode"] = episode,
        ["slot.broadcast.topic"] = topicLabel,
    }
end

function Response.Resolve(ir, state, context, branch)
    if type(ir) ~= "table" then return nil end
    local activeWorldTopic = type(state) == "table" and state.activeWorldTopic or nil
    if type(activeWorldTopic) == "table"
        and activeWorldTopic.exhausted ~= true
        and type(activeWorldTopic.topic) == "table"
    then
        local followKind = detectWorldTopicFollowUpKind(ir)
        local WKG = PsychopatzCore and PsychopatzCore.WorldKnowledge or nil
        if followKind and WKG and type(WKG.AdvanceTopicFollowUp) == "function" then
            local resolved = WKG.AdvanceTopicFollowUp(
                activeWorldTopic.topic,
                followKind,
                activeWorldTopic.depth
            )
            if type(resolved) == "table" then
                activeWorldTopic.depth = resolved.nextDepth
                activeWorldTopic.exhausted = resolved.exhausted == true
                local topic = activeWorldTopic.topic
                local poolID
                if topic.source == "banter" then
                    poolID = "semantic.banter.mundane.followup"
                elseif activeWorldTopic.exhausted then
                    poolID = "semantic.gossip.world.closure"
                else
                    poolID = "semantic.gossip.world.followup"
                end
                local followCtx = copyArgs(context)
                followCtx.currentTopic = topic.topic
                followCtx.action = (followKind == "more" and activeWorldTopic.depth >= 2)
                    and "plan" or followKind
                local slotTokens = buildWorldTopicTokens(topic)
                local resp = catalogResponse(poolID, ir, state, followCtx, slotTokens)
                if type(resp) == "table" then
                    resp.dialogueAct = "FACT_ANSWER"
                    resp.topic = topic.topic
                    resp.referenceTopic = topic.subjectLabel or topic.topic
                    resp.worldTopicExhausted = activeWorldTopic.exhausted
                    if (followKind == "stance_positive" or followKind == "stance_neutral" or followKind == "stance_negative")
                        and PNC.Semantics and PNC.Semantics.ConversationDirector
                        and type(PNC.Semantics.ConversationDirector.EvaluateStanceImpact) == "function"
                    then
                        local addrRec = (type(context) == "table" and (context.npcRecord or context.record))
                            or (type(context) == "table" and context.npcID and PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(context.npcID))
                            or nil
                        local playerSpeaker = (type(context) == "table" and (context.player or context.playerKey))
                            or { isPlayer = true, username = type(context) == "table" and context.playerUsername or "0" }
                        local bystanders = nil
                        if addrRec and addrRec.x and addrRec.y and PNC.SpatialIndex and type(PNC.SpatialIndex.QueryNPCs) == "function" then
                            bystanders = PNC.SpatialIndex.QueryNPCs(addrRec.x, addrRec.y, 12)
                        end
                        local impacts = PNC.Semantics.ConversationDirector.EvaluateStanceImpact(
                            playerSpeaker, addrRec, bystanders, topic.topic, followKind,
                            { topicInstanceKey = tostring(topic.id or topic.topic) }
                        )
                        resp.stanceImpact = impacts
                    end
                    return resp
                end
            end
        end
    end
    if branch == "GREET_ACKNOWLEDGED" then
        local situation = type(context) == "table" and context.dialogueSituation or nil
        local actorCtx = type(context) == "table" and context.actorConversationContext or nil
        local actorRoles = type(actorCtx) == "table" and actorCtx.roles or nil
        local npc = type(situation) == "table" and situation.npc or nil
        local hostility = type(npc) == "table" and npc.hostility
            or (type(context) == "table" and context.hostility or nil)
        local roles = type(situation) == "table" and situation.roles or nil
        local ctxRoles = type(context) == "table" and context.roles or nil
        local style = type(context) == "table" and context.speechStyle or nil
        local activeBehavior = type(situation) == "table" and tostring(situation.activeBehavior or "") or ""
        local social = type(context) == "table" and context.socialContext or nil
        local tactical = type(social) == "table" and social.tacticalHostility or nil
        local audience = type(social) == "table" and social.conversationAudience or nil
        local isHostile = (type(actorRoles) == "table" and actorRoles.hostile == true)
            or (type(ctxRoles) == "table" and ctxRoles.hostile == true)
            or (type(roles) == "table" and roles.hostile == true)
            or (type(hostility) == "table" and (tostring(hostility.mode or "") == "hostile" or hostility.attackPlayers == true))
            or (type(style) == "table" and tostring(style.variant or "") == "guarded")
            or activeBehavior == "hostile"
            or activeBehavior == "combat"
            or (type(tactical) == "table" and tostring(tactical.mode or "") == "hostile")
            or (type(audience) == "table" and tostring(audience.audience or "") == "hostile")
        if isHostile then
            return {
                dialogueAct = "GREET_ACKNOWLEDGED",
                selectionSource = "flow_pool",
                responsePool = "semantic.flow.greeting.opening",
                templateID = "flow.greeting.opening.default",
                fallback = "State your business. Keep your distance.",
                args = {},
            }
        end
        return catalogResponse("semantic.greeting", ir, state, context, {
            topic = state and state.currentTopic,
        })
    end
    if branch == "FAREWELL_ACKNOWLEDGED" then
        local role = FarewellRole.ResolveFromContext(context)
        local farewellCtx = copyArgs(context)
        farewellCtx.socialRole = role
        farewellCtx.farewellSpeaker = "npc"
        if role == "hostile" then
            farewellCtx.socialStyle = "withdrawn"
        elseif role == "lover" or role == "family" or role == "friend" or role == "colonist" then
            farewellCtx.socialStyle = "friendly"
        end
        return catalogResponse("semantic.social.farewell.depart", ir, state, farewellCtx, {
            topic = "farewell",
        })
    end
    if branch == "SEMANTIC_NAVIGATION_RECEIVED" then
        return catalogResponse(
            "semantic.conversation.acknowledged", ir, state, context
        )
    end
    if branch == "COMPLIMENT_RECEIVED" then
        return catalogResponse("semantic.compliment", ir, state, context)
    end
    if branch == "OFFER_RECEIVED" then
        return catalogResponse("semantic.offer", ir, state, context, {
            object = ir.object,
            topic = state and state.currentTopic,
        })
    end
    if branch == "GIFT_SELECTION_REQUIRED" then
        return {
            templateID = "gift.selection_required",
            fallback = "Oh? What did you bring me?",
            args = copyArgs({ object = ir.object }),
        }
    end
    if branch == "GIFT_OFFER_DISPATCHED" then
        return {
            templateID = "gift.pending",
            fallback = "",
            args = copyArgs({ object = ir.object }),
        }
    end
    if branch == "GIFT_CONSENT_DECLINED" then
        return {
            templateID = "semantic.gift.consent.declined",
            fallback = "No problem. I'll leave it with you.",
        }
    end
    if branch == "GIFT_CONSENT_AMBIGUOUS" then
        return {
            templateID = "semantic.gift.consent.ambiguous",
            fallback = "More than one of us wants it. Please offer it to one person directly.",
        }
    end
    if branch == "QUESTION_RECEIVED" and type(resolveQuestion) == "function" then
        local response = resolveQuestion(ir, state, context)
        if response then return response end
    end
    if branch == "IDENTITY_CLAIM_RECEIVED" then
        local claim = ir.slots and ir.slots.identityClaim or {}
        return {
            templateID = "semantic.identity.exchange",
            -- The authoritative identity-claim result decides whether the
            -- NPC may disclose their own name. Do not leak it before the
            -- server validates the player's claim.
            fallback = "Nice to meet you. What's your name?",
            args = copyArgs({
                playerName = claim.name,
                npcName = context and (context.npcFullName or context.npcName),
            }),
        }
    end
    if branch == "GOSSIP_RECEIVED" then
        local response = catalogResponse(
            "semantic.gossip", ir, state, context, {
                target = targetText(ir.target),
                event = ir.slots and ir.slots.information
                    and ir.slots.information.event,
            }
        )
        if response then
            local information = ir.slots and ir.slots.information or nil
            local gossip = context and context.npcGossip or nil
            local statements = type(gossip) == "table"
                and gossip.statements or nil
            local gossipLines = {}
            local index
            local line
            if type(statements) == "table" then
                for index = 1, math.min(#statements, 4) do
                    line = statements[index]
                    if type(line) == "string" and line ~= "" then
                        gossipLines[#gossipLines + 1] = line
                    end
                end
            end
            if #gossipLines > 0 then
                response.templateID = "semantic.gossip.memory"
                response.fallback = table.concat(gossipLines, " ")
                response.args = nil
                return response
            end
            if type(information) == "table"
                and information.event == "NEWS"
            then
                local target = type(ir.target) == "table"
                    and ir.target.unresolved ~= true
                    and ir.target or nil
                local name = target and targetText(target) or ""
                if name ~= "" and name ~= "them" then
                    response.fallback = "I haven't heard anything new about "
                        .. name .. " lately."
                else
                    local WKG = PsychopatzCore and PsychopatzCore.WorldKnowledge or nil
                    if WKG and type(WKG.QueryConversationTopics) == "function" then
                        local worldHour = context and tonumber(context.worldAgeHours)
                            or (getGameTime and getGameTime() and getGameTime().getWorldAgeHours
                                and tonumber(getGameTime():getWorldAgeHours()))
                            or nil
                        local topics = WKG.QueryConversationTopics(
                            context and (context.actorID or context.npcID) or nil,
                            {
                                npcID = context and context.npcID,
                                identitySeed = context and context.identitySeed,
                                x = context and context.npcX,
                                y = context and context.npcY,
                                worldHour = worldHour,
                                worldDay = worldHour and math.floor(worldHour / 24) or 0,
                            },
                            { limit = 1 }
                        )
                        local top = type(topics) == "table" and topics[1] or nil
                        if top and type(top.topic) == "string" and top.topic ~= "" then
                            if type(state) == "table" then
                                state.activeWorldTopic = {
                                    topic = top,
                                    depth = 0,
                                    exhausted = false,
                                }
                            end
                            local poolID = top.source == "banter"
                                and "semantic.banter.mundane"
                                or "semantic.gossip.world.opening"
                            local topicCtx = copyArgs(context)
                            topicCtx.currentTopic = top.topic
                            topicCtx.worldRaiderSurge = (top.meta and top.meta.chopperLinked == true)
                                or (top.chopperLinked == true)
                            local slotTokens = buildWorldTopicTokens(top)
                            local compiled = catalogResponse(poolID, ir, state, topicCtx, slotTokens)
                            if type(compiled) == "table" then
                                compiled.topic = top.topic
                                compiled.referenceTopic = top.subjectLabel or top.topic
                                return compiled
                            end
                        end
                    end
                    response.fallback = "I haven't heard any news lately."
                end
            else
                local name = targetText(ir.target)
                response.fallback = "I haven't heard anything about "
                    .. name .. " yet."
            end
            return response
        end
    end
    if branch == "HOSTILE_REMARK_RECEIVED" then
        local hostilityCount = socialCounts(state)
        return catalogResponse(
            "semantic.hostile_remark", ir, state, context, {
                speechAct = ir.speechAct,
                intensity = ir.emotionalState
                    and ir.emotionalState.intensity,
                hostilityCount = hostilityCount,
            }
        )
    end
    if branch == "SELF_REFLECTION_RECEIVED" then
        return catalogResponse(
            "semantic.self_reflection", ir, state, context, {
                reflectionType = ir.socialContext
                    and ir.socialContext.reflectionType,
                relationshipState = context and context.relationshipState,
                socialStyle = context and context.socialStyle,
            }
        )
    end
    if branch == "SELF_STATE_RECEIVED" then
        return catalogResponse(
            "semantic.self_state", ir, state, context, {
                state = ir.slots and ir.slots.state,
            }
        )
    end
    if branch == "IDENTITY_NAME_EVASION" then
        return catalogResponse(
            "semantic.identity.evasion", ir, state, context, {
                relationshipState = context and context.relationshipState,
                socialStyle = context and context.socialStyle,
            }
        )
    end
    if branch == "THREAT_RECEIVED" then
        return catalogResponse("semantic.threat", ir, state, context, {
            speechAct = ir.speechAct,
        })
    end
    if branch == "SOCIAL_ACKNOWLEDGED" then
        if ir.intent == "APOLOGIZE" then
            return catalogResponse("semantic.apology", ir, state, context)
        end
        if (ir.intent == "ACKNOWLEDGE"
                or ir.intent == "ACCEPT"
                or ir.intent == "AGREE"
                or ir.intent == "THANK")
            and followsRelationshipStatusAnswer(context)
        then
            return catalogResponse(
                "semantic.question.relationship_status.acknowledged",
                ir,
                state,
                context
            )
        end
        if (ir.intent == "ACKNOWLEDGE"
                or ir.intent == "ACCEPT"
                or ir.intent == "AGREE")
            and type(followsQuestionAnswer) == "function"
            and followsQuestionAnswer(context)
        then
            return catalogResponse(
                "semantic.conversation.acknowledged",
                ir,
                state,
                context
            )
        end
        if ir.intent == "THANK" then
            return catalogResponse("semantic.thanks", ir, state, context, {
                topic = state and state.currentTopic,
            })
        end
        if ir.intent == "ACCEPT" or ir.intent == "AGREE" then
            return catalogResponse("semantic.accept", ir, state, context, {
                action = state and state.pendingRequest
                    and state.pendingRequest.action,
                topic = state and state.currentTopic,
            })
        end
        if ir.intent == "REFUSE" or ir.intent == "DISAGREE" then
            return catalogResponse("semantic.refuse", ir, state, context, {
                action = state and state.pendingRequest
                    and state.pendingRequest.action,
                topic = state and state.currentTopic,
            })
        end
    end
    return nil
end


return Response
