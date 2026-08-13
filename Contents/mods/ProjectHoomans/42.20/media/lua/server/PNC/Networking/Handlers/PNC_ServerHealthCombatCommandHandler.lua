-- Health/combat network adapter. Domain services retain authoritative mutation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

Router.Register(Const.CMD_REVIVE, function(player, args)
    if not args.id then return end
    local revive = PNC.Revive
    if revive and revive.Try then
        revive.Try(player, args.id)
    end
end)

Router.Register(Const.CMD_BANDAGE, function(player, args)
    if not args.id or not args.partId then return end
    local treatment = PNC.Treatment
    if treatment and treatment.TryBandage then
        local debugFree = args.debugFree == true
            and Router.CanUseDebug(player)
        treatment.TryBandage(player, args.id, args.partId, {
            consumeItem = not debugFree,
            bandageType = args.bandageType,
        })
    end
end)

Router.Register(Const.CMD_PLAYER_WEAPON_HIT, function(player, args)
    local playerDamage = PNC.PlayerDamage
    if playerDamage and playerDamage.HandleClientReport then
        playerDamage.HandleClientReport(player, args)
    end
end)
