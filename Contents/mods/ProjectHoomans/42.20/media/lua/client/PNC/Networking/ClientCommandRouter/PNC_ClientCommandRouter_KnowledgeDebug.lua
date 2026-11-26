-- Client delivery of authorized knowledge diagnostics.

local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

Internal.RegisterServerCommand(Const.CMD_KNOWLEDGE_DEBUG, function(args)
    if args.profileRequestID then
        if PNC.CharacterWindow and PNC.CharacterWindow.ReceiveDebugProfile then
            local snapshot = args.authorized == true and args.snapshot or nil
            PNC.CharacterWindow.ReceiveDebugProfile(args.profileRequestID, snapshot)
        end
        return
    end
    ClientState.knowledgeDebugAuthorized = args.authorized == true
    ClientState.knowledgeDebug = args.snapshot
    ClientState.knowledgeDebugReason = args.reason
    ClientState.lastKnowledgeDebugReceiveAt = Core.Now()
    if PNC.KnowledgeDebugUI and PNC.KnowledgeDebugUI.ReceiveSnapshot then
        PNC.KnowledgeDebugUI.ReceiveSnapshot(args.snapshot)
    end
    if PNC.NPCDossierUI and PNC.NPCDossierUI.ReceiveDebugSnapshot then
        PNC.NPCDossierUI.ReceiveDebugSnapshot(args.snapshot)
    end
end)

return Internal
