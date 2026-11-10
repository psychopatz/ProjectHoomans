-- Knowledge disclosure and player-knowledge command adapters.

local function configureKnowledge(state)
    local context = state.context
    local Runtime = state.Runtime
    local Values = state.Values
    local number = state.number
    local playerData = state.playerData
    local npcData = state.npcData
    local identityName = state.identityName

    PNC.NPCKnowledgeAPI = PNC.NPCKnowledgeAPI or {}
    if type(PNC.NPCKnowledgeAPI.DiscloseForPlayer) ~= "function" then
    PNC.NPCKnowledgeAPI.DiscloseForPlayer = function(_, options)
        npcData.identityState = "known"
        PNC.Network.ClientState.npcPresentations =
            PNC.Network.ClientState.npcPresentations or {}
        PNC.Network.ClientState.npcPresentations[npcData.npcID] = {
            state = "known",
            displayName = identityName(npcData),
        }
        if Runtime.view and Runtime.view.spec
            and Runtime.view.spec.context
        then
            Runtime.view.spec.context.identityState = "known"
        end
        Runtime.disclosures = number(Runtime.disclosures, 0) + 1
        Runtime.knowledge = options
        return { accepted = true, revealed = { "identity.name" } }
    end
    end
    PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}
    PNC.PlayerKnowledgeCommands.Internal =
        PNC.PlayerKnowledgeCommands.Internal or {}
    PNC.PlayerKnowledgeCommands.Internal.SafeID = function(value)
        value = tostring(value or "")
        return value ~= "" and value or nil
    end
    PNC.PlayerKnowledgeCommands.Internal.ContextFor = function()
        return {
            characterUUID = playerData.characterUUID,
            entityKey = "player:" .. tostring(playerData.characterUUID),
        }
    end
    PNC.PlayerKnowledgeCommands.Internal.IntroductionText = function()
        return "I'm " .. identityName(npcData) .. "."
    end


end

return configureKnowledge
