if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Registry = PNC.Registry
local Network = PNC.Network
local relationshipSnapshot = Internal.relationshipSnapshot

PNC.Gifts = PNC.Gifts or {}
local giftEffect = PNC.Gifts.EvaluateEffect
local Foundation = PNC.Gifts.Foundation
local RuntimeEvaluator = Foundation and Foundation.RuntimeEvaluator

local function learnedGiftPreferences(evaluation)
    local preferences = {}
    local learned = false
    local rows = evaluation and evaluation.breakdown or {}
    for _, row in ipairs(rows) do
        local fullType = type(row) == "table"
            and tostring(row.fullType or "") or ""
        local disposition = type(row) == "table"
            and tostring(row.disposition or "") or ""
        if fullType ~= ""
            and string.match(fullType, "^[A-Za-z0-9_.:%-]+$")
        then
            if disposition == "favorite" or disposition == "liked" then
                preferences[fullType] = "like"
                learned = true
            elseif disposition == "disliked" or disposition == "hated" then
                preferences[fullType] = "dislike"
                learned = true
            end
        end
    end
    return learned and preferences or nil
end

local function evaluateGift(record, itemTypes)
    local legacy = giftEffect(itemTypes or {})
    if not RuntimeEvaluator or type(RuntimeEvaluator.Evaluate) ~= "function" then
        return legacy, nil
    end
    local ok
    local evaluation
    ok, evaluation = pcall(RuntimeEvaluator.Evaluate,
        record, itemTypes or {})
    if not ok or type(evaluation) ~= "table" then return legacy, nil end
    local relationship = evaluation.relationshipEffect or {}
    local gift = {
        approval = tonumber(relationship.approval) or legacy.approval or 0,
        respect = tonumber(relationship.respect) or legacy.respect or 0,
        familiarity = tonumber(relationship.familiarity)
            or legacy.familiarity or 0,
        memoryID = evaluation.bestKey or legacy.memoryID or "gift",
        kind = legacy.kind or "general",
        interactionType = "gift",
        disposition = evaluation.disposition or "neutral",
        foundation = {
            schemaVersion = evaluation.schemaVersion,
            disposition = evaluation.disposition,
            score = evaluation.score,
            totalQuantity = evaluation.totalQuantity,
            totalPrice = evaluation.totalPrice,
            confidence = evaluation.confidence,
            bestKey = evaluation.bestKey,
            bestType = evaluation.bestType,
        },
    }
    return gift, learnedGiftPreferences(evaluation)
end

local function applyGiftEffect(player, record, args, details)
    local gift, giftPreferences = evaluateGift(
        record, details and details.itemTypes or {}
    )
    details = details or {}
    -- The acknowledgement is part of the conversation contract even if
    -- the relationship service is temporarily unavailable. The transfer
    -- remains authoritative; in that degraded case the axes simply do
    -- not change and the client still receives an honest flavour reply.
    details.giftEffect = gift
    details.giftReplyKey = "gift.received."
        .. tostring(gift and gift.kind or "general")
    local playerKey = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetEntityKey
        and PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "conversation_gift",
            worldAgeHours = getGameTime and getGameTime()
                and getGameTime():getWorldAgeHours() or 0,
        }) or nil
    local applied
    local applyReason
    local result
    local relationshipBefore = PNC.Relationships
        and PNC.Relationships.Get
        and relationshipSnapshot(PNC.Relationships.Get(record.id, playerKey))
        or relationshipSnapshot(nil)
    if playerKey and PNC.Relationships
        and PNC.Relationships.ApplyConversationEffect
    then
        applied, applyReason, result = PNC.Relationships.ApplyConversationEffect(
            record.id,
            playerKey,
            gift,
            {
                blockID = "projecthoomans:needs_gift",
                choiceID = "gift",
                outcomeID = args.requestId or details and details.itemTypes
                    and details.itemTypes[1] or "gift",
                worldAgeHours = getGameTime and getGameTime()
                    and getGameTime():getWorldAgeHours() or 0,
                sourceSystem = "gift",
                interaction = {
                    kind = "gift",
                    source = "gift",
                    interactionType = gift and gift.interactionType
                        or gift and gift.memoryType or "gift",
                    choiceID = "gift",
                    itemSummary = details.itemSummary,
                    itemTypes = details.itemTypes,
                    npcTextKey = details.giftReplyKey,
                    responseKey = details.giftReplyKey,
                    applied = true,
                },
            }
        )
    end
    if applied == true and result and result.relationship then
        local relationshipAfter = relationshipSnapshot(result.relationship)
        details.eventID = result.eventID
        details.relationshipBefore = relationshipBefore
        details.relationshipAfter = relationshipAfter
        details.relationshipDelta = {
            approval = relationshipAfter.approval - relationshipBefore.approval,
            respect = relationshipAfter.respect - relationshipBefore.respect,
            familiarity = relationshipAfter.familiarity - relationshipBefore.familiarity,
        }
        if Network and Network.SendConversationRelationshipForNPC then
            local sent
            local ignoredReason
            local summary
            sent, ignoredReason, summary = Network.SendConversationRelationshipForNPC(
                player,
                record.id,
                "gift",
                {
                    source = "gift",
                    eventID = details.eventID,
                    relationshipBefore = relationshipBefore,
                    relationshipDelta = details.relationshipDelta,
                }
            )
            if sent == true and summary then
                details.relationshipAfter = summary
            end
        end
    else
        details.giftEffectError = applyReason or "relationship_unavailable"
        details.relationshipBefore = relationshipBefore
        details.relationshipAfter = relationshipBefore
        details.relationshipDelta = {
            approval = 0,
            respect = 0,
            familiarity = 0,
        }
    end
    if giftPreferences and PNC.NPCKnowledgeAPI
        and PNC.NPCKnowledgeAPI.RecordGiftPreferencesForPlayer
    then
        local recorded
        local recordReason
        recorded, recordReason =
            PNC.NPCKnowledgeAPI.RecordGiftPreferencesForPlayer(
                player,
                record.id,
                giftPreferences,
                args and args.requestId or details.eventID
            )
        if recorded and recorded.snapshot then
            details.knowledgeSnapshot = recorded.snapshot
            if recorded.committed ~= true
                and recordReason and PNC.Core and PNC.Core.LogWarn
            then
                PNC.Core.LogWarn("Gift preference knowledge not saved npc="
                    .. tostring(record.id or "unknown") .. " reason="
                    .. tostring(recordReason))
            end
        elseif recordReason and PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("Gift preference knowledge not saved npc="
                .. tostring(record.id or "unknown") .. " reason="
                .. tostring(recordReason))
        end
    end
    if Registry.Save then Registry.Save() end
    return details
end

Internal.applyGiftEffect = applyGiftEffect
