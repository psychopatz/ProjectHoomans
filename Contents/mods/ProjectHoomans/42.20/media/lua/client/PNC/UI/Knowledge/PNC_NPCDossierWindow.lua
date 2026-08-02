-- Compatibility bridge for callers that used the former standalone dossier.
-- The dossier now belongs to the NPC Character Window's Dossier tab.

PNC = PNC or {}
PNC.NPCDossierUI = PNC.NPCDossierUI or {}

local Dossier = PNC.NPCDossierUI

function Dossier.Open(npcID)
    if PNC.CharacterWindow and PNC.CharacterWindow.OpenDossier then
        return PNC.CharacterWindow.OpenDossier(npcID)
    end
    return nil
end

function Dossier.ReceiveSnapshot(snapshot)
    if PNC.CharacterWindow and PNC.CharacterWindow.ReceiveKnowledgeSnapshot then
        PNC.CharacterWindow.ReceiveKnowledgeSnapshot(snapshot)
    end
end

function Dossier.ReceiveDebugSnapshot(snapshot)
    if snapshot and snapshot.npcID and PNC.Client and PNC.Client.RequestNPCKnowledge then
        PNC.Client.RequestNPCKnowledge(snapshot.npcID)
    end
end

return Dossier
