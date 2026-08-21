local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

Internal.RegisterServerCommand(Const.CMD_COLONY_MANAGEMENT, function(args)
    ClientState.colonyManagement = args.snapshot
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
    if args.snapshot and args.snapshot.actionResult
        and (args.snapshot.actionResult.action == "storage_player_deposit"
            or args.snapshot.actionResult.action == "storage_player_withdraw"
            or args.snapshot.actionResult.action == "storage_npc_deposit"
            or args.snapshot.actionResult.action == "storage_npc_deposit_all")
        and PNC.InventoryWindow
        and PNC.InventoryWindow.OnColonyStorageResult
    then
        PNC.InventoryWindow.OnColonyStorageResult(args.snapshot.actionResult)
    end
    if PNC.ColonyNamePrompt and PNC.ColonyNamePrompt.OpenIfNeeded then
        PNC.ColonyNamePrompt.OpenIfNeeded(args.snapshot)
    end
end)

Internal.RegisterServerCommand(Const.CMD_SETTLEMENT_DELTA, function(args)
    local snapshot = ClientState.colonyManagement or {}
    snapshot.settlement = args.settlement
    if args.storage then snapshot.storage = args.storage end
    snapshot.actionResult = args.actionResult
    ClientState.colonyManagement = snapshot
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
end)

Internal.RegisterServerCommand(Const.CMD_COLONY_KNOWLEDGE_DELTA, function(args)
    local delta = args and args.delta or nil
    local snapshot = ClientState.colonyManagement
    local research = snapshot and snapshot.research
    if not delta or not research or not snapshot.colony
        or tostring(snapshot.colony.id or "") ~= tostring(delta.colonyId or "")
    then return end
    local current = tonumber(research.knowledgeRevision) or 0
    if tonumber(delta.revision) ~= current + 1 then
        if PNC.Client and PNC.Client.RequestColonyManagement then
            PNC.Client.RequestColonyManagement()
        end
        return
    end
    research.knowledgeRevision = delta.revision
    if delta.recipeId then
        research.learnedRecipeIds = research.learnedRecipeIds or {}
        research.learnedRecipeIds[#research.learnedRecipeIds + 1] = delta.recipeId
        table.sort(research.learnedRecipeIds)
        snapshot.workshop = snapshot.workshop or {}
        snapshot.workshop.knownRecipes = snapshot.workshop.knownRecipes or {}
        if delta.recipe then
            snapshot.workshop.knownRecipes[#snapshot.workshop.knownRecipes + 1]
                = delta.recipe
        end
    elseif delta.technologyId then
        research.learnedTechnologyIds = research.learnedTechnologyIds or {}
        research.learnedTechnologyIds[#research.learnedTechnologyIds + 1]
            = delta.technologyId
        for _, entry in ipairs(research.entries or {}) do
            if entry.id == delta.technologyId then entry.known = true end
        end
    end
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
end)

return PNC.Client
