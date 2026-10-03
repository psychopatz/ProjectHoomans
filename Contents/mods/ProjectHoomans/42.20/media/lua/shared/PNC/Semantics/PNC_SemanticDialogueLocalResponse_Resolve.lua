-- Semantic response branch resolver provider.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Response = PNC.Semantics.LocalResponse
local Internal = Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local targetText = Internal.TargetText
local socialCounts = Internal.SocialCounts
local followsRelationshipStatusAnswer =
    Internal.FollowsRelationshipStatusAnswer
local resolveQuestion = Internal.ResolveQuestion

function Response.Resolve(ir, state, context, branch)
    if type(ir) ~= "table" then return nil end
    if branch == "GREET_ACKNOWLEDGED" then
        return catalogResponse("semantic.greeting", ir, state, context, {
            topic = state and state.currentTopic,
        })
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
            templateID = "semantic.gift.selection_required",
            fallback = "Oh? What did you bring me?",
            args = copyArgs({ object = ir.object }),
        }
    end
    if branch == "GIFT_OFFER_DISPATCHED" then
        return {
            templateID = "semantic.gift.pending",
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
        if ir.intent == "ACKNOWLEDGE"
            and followsRelationshipStatusAnswer(context)
        then
            return catalogResponse(
                "semantic.question.relationship_status.acknowledged",
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
