-- Player-knowledge and world-discovery network adapters.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

Router.Register(Const.CMD_PLAYER_BOOTSTRAP_REQUEST, function(player, args)
    PNC.PlayerKnowledgeCommands.HandleBootstrap(player, args)
end)

Router.Register(Const.CMD_NPC_PRESENTATION_REQUEST, function(player, args)
    PNC.PlayerKnowledgeCommands.HandlePresentation(player, args)
end)

Router.Register(Const.CMD_KNOWLEDGE_DISCLOSURE_REQUEST, function(player, args)
    PNC.PlayerKnowledgeCommands.HandleDisclosure(player, args)
end)

local function handleWorldDiscovery(player, args)
    PNC.Network.SendWorldDiscovery(
        player,
        PNC.WorldDiscovery.HandleAction(player, args)
    )
end

Router.Register(Const.CMD_WORLD_DISCOVERY_REQUEST, handleWorldDiscovery)
Router.Register(Const.CMD_WORLD_DISCOVERY_ACTION, handleWorldDiscovery)
