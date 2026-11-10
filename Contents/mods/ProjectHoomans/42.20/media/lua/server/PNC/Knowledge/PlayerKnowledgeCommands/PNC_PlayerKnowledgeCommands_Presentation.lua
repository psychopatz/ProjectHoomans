if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Commands = PNC.PlayerKnowledgeCommands
local H = Commands.Internal
local Network = PNC.Network
local Core = PNC.Core

local function identityDisplayName(identity)
    identity = type(identity) == "table" and identity or {}
    local fullName = tostring(identity.displayName or "")
    local nickname = tostring(identity.nickname or "")
    if fullName ~= "" and nickname ~= "" then
        return fullName .. " (" .. nickname .. ")"
    end
    return fullName ~= "" and fullName or nickname ~= "" and nickname or nil
end

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
    if PNC.NPCKnowledgeAPI and PNC.NPCKnowledgeAPI.GetForPlayer then
        snapshot, reason = PNC.NPCKnowledgeAPI.GetForPlayer(player, npcID)
    else
        snapshot, reason = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(player, npcID)
    end
    if not snapshot then
        return {
            requestID = requestID, npcID = npcID, state = "error",
            reason = reason, bindingRevision = context.bindingRevision,
        }
    end
    snapshot, nameFact = H.SanitizeSnapshot(snapshot)
    local identity = snapshot.identity or {}
    local displayName = identityDisplayName(identity)
    local fullNameKnown = identity.displayName ~= nil
        and tostring(identity.displayName) ~= ""
    local nicknameKnown = identity.nickname ~= nil
        and tostring(identity.nickname) ~= ""
    local known = displayName ~= nil
    return {
        requestID = requestID,
        npcID = npcID,
        state = known and "known" or "unknown",
        identityLevel = fullNameKnown and "full_name"
            or nicknameKnown and "nickname" or "unknown",
        canAskName = not fullNameKnown,
        displayName = displayName or "Unknown survivor",
        archetypeLabel = identity.archetypeLabel,
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
