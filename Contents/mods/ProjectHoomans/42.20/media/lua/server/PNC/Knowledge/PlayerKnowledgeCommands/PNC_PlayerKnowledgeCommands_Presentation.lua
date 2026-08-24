if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Commands = PNC.PlayerKnowledgeCommands
local H = Commands.Internal
local Network = PNC.Network
local Core = PNC.Core

function H.PresentationFor(player, npcID, requestID)
    local context, reason = H.ContextFor(player, "npc_presentation")
    if not context then
        return { requestID = requestID, npcID = npcID, state = "error", reason = reason }
    end
    if Commands.Uncommitted[context.characterUUID]
        and Commands.Uncommitted[context.characterUUID][npcID]
    then
        return {
            requestID = requestID, npcID = npcID, state = "error",
            reason = "knowledge_commit_pending",
            characterUUID = context.characterUUID,
            bindingRevision = context.bindingRevision,
        }
    end
    local snapshot
    local nameFact
    snapshot, reason = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(player, npcID)
    if not snapshot then
        return {
            requestID = requestID, npcID = npcID, state = "error",
            reason = reason, bindingRevision = context.bindingRevision,
        }
    end
    snapshot, nameFact = H.SanitizeSnapshot(snapshot)
    local known = nameFact and nameFact.value ~= nil
    local identity = snapshot.identity or {}
    return {
        requestID = requestID,
        npcID = npcID,
        state = known and "known" or "unknown",
        canAskName = not known,
        displayName = known and tostring(nameFact.value) or "Unknown survivor",
        archetypeLabel = known and identity.archetypeLabel or nil,
        factionName = identity.factionName,
        portrait = snapshot.portrait,
        relationship = snapshot.relationship,
        snapshot = snapshot,
        characterUUID = context.characterUUID,
        accountKey = context.accountKey,
        bindingRevision = context.bindingRevision,
        knowledgeRevision = tonumber(snapshot.revision) or 0,
    }
end


function Commands.HandlePresentation(player, args)
    args = type(args) == "table" and args or {}
    local npcID = H.SafeID(args.npcID)
    local payload = npcID and H.PresentationFor(player, npcID, args.requestID)
        or { requestID = args.requestID, state = "error", reason = "invalid_npc_id" }
    Network.SendNPCPresentation(player, payload)
    return payload
end
