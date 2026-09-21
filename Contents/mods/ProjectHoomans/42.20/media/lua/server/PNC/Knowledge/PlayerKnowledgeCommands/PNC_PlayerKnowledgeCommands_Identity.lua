-- Server-authoritative semantic identity exchange.
-- The client may report what the player said, but only this boundary can
-- compare it with the canonical player identity and mutate reputation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}

if not (PNC.Semantics and PNC.Semantics.IdentityExchange) then
    require "PNC/Semantics/PNC_SemanticIdentityExchange"
end

local Commands = PNC.PlayerKnowledgeCommands
local Identity = PNC.Semantics.IdentityExchange
local IdentityAdmission = require
    "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_IdentityAdmission"
local IdentityMutation = require
    "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_IdentityMutation"
local IdentityPolicy = require
    "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_IdentityPolicy"
local IdentityPresentation = require
    "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_IdentityPresentation"
local IdentityResult = require
    "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_IdentityResult"
local Relationships = PNC.Relationships
local Presentation = PNC.RelationshipPresentation

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    if time and time.getWorldAgeHours then
        return math.max(0, tonumber(time:getWorldAgeHours()) or 0)
    end
    return 0
end

function Commands.HandleSemanticIdentity(player, args)
    local request, reason = IdentityAdmission.Resolve(player, args)
    if not request then
        return IdentityResult.SendRejected(player, args, reason)
    end
    args = request.args
    local requestID = request.requestID
    local npcID = request.npcID
    local kind = request.kind
    local claimedName = request.claimedName
    local record = request.record
    local targetKey = request.targetKey
    local lease = request.lease
    local actualName

    local at = worldAgeHours()
    local before = Relationships.Get(npcID, targetKey)
    local truthful = nil
    local trustLabel = nil
    local effect
    if kind == Identity.EVENT_CLAIM then
        actualName = IdentityPresentation.PlayerName(
            player,
            request.context
        )
        if actualName == "" then
            return IdentityResult.SendRejected(
                player,
                args,
                "player_name_unavailable"
            )
        end
        truthful = Identity.ClaimMatchesName
            and Identity.ClaimMatchesName(claimedName, actualName)
            or Identity.NamesEqual(claimedName, actualName)
    end
    local effectReason
    effect, trustLabel, effectReason = IdentityPolicy.EffectFor(kind, truthful)
    if not effect then
        return IdentityResult.SendRejected(
            player,
            args,
            effectReason or "identity_effect_unavailable"
        )
    end

    local eventID = "semantic_identity:" .. requestID
    local applied, applyReason, details = IdentityMutation.Apply({
        npcID = npcID,
        targetKey = targetKey,
        kind = kind,
        requestID = requestID,
        claimedName = claimedName,
        truthful = truthful,
        effect = effect,
        eventID = eventID,
        worldAgeHours = at,
    })
    if applied ~= true then
        return IdentityResult.SendRejected(
            player,
            args,
            applyReason or "relationship_rejected"
        )
    end

    local after = Relationships.Get(npcID, targetKey) or {}
    local summary = Presentation and Presentation.Summarize
        and Presentation.Summarize(after, true) or after
    summary.npcID = npcID
    summary.identityTrust = trustLabel
    local delta = IdentityResult.RelationshipDelta(before, after)
    local responseText
    local responseKey
    local responseArgs
    if kind == Identity.EVENT_CLAIM then
        responseText, responseKey, responseArgs =
            IdentityPresentation.ResolveClaim(
                player,
                request,
                record,
                truthful,
                actualName
            )
    end

    local payload = IdentityResult.BuildAccepted({
        requestID = requestID,
        npcID = npcID,
        kind = kind,
        accepted = true,
        truthful = truthful,
        trustLabel = trustLabel,
        responseText = responseText,
        responseKey = responseKey,
        responseArgs = responseArgs,
        relationship = summary,
        relationshipBefore = before,
        relationshipDelta = delta,
        eventID = eventID,
        details = details,
        effect = effect,
        lease = lease,
    })
    return IdentityResult.SendAccepted(player, payload)
end

return Commands
