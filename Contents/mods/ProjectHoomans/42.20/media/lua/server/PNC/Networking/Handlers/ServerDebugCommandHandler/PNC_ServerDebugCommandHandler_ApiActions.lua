if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Handler = PNC.ServerDebugCommandHandler
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local H = Handler.Internal

local directDebugActions = {
    force_live = true,
    force_abstract = true,
    heal = true,
    revive = true,
    damage = true,
    damage_part = true,
    infection = true,
    clear_infection = true,
    bandage_almost_dirty = true,
    animation_scene_play = true,
    animation_scene_pool_step = true,
    animation_scene_pool_start = true,
    animation_scene_stop = true,
    set_map_presentation = true,
    set_weapon_mode = true,
    set_equipment_slot = true,
    clear_equipment = true,
    toggle_debug = true,
}

function H.HandleAPIAction(player, args)
    local api = PNC.API
    if directDebugActions[args.action] then
        api.DebugCommand(args.id, args.action, args)
        return true
    end
    if args.action == "set_map_known" then
        args.playerKey = player and player.getUsername
            and player:getUsername() or nil
        api.DebugCommand(args.id, "set_map_known", args)
        return true
    end
    if args.action == "copy_held_weapon" then
        if player and player.getPrimaryHandItem then
            local primary = player:getPrimaryHandItem()
            if primary and primary.getFullType then
                args.weaponFullType = primary:getFullType()
            end
        end
        args.sourcePlayer = player
        api.DebugCommand(args.id, "copy_held_weapon", args)
        return true
    end
    if args.action == "copy_player_loadout" then
        args.sourcePlayer = player
        api.DebugCommand(args.id, "copy_player_loadout", args)
        return true
    end
    if args.action == "set_order" then
        api.SetOrder(args.id, args.orderSpec)
        return true
    end
    if args.action == "set_hostility" then
        api.SetHostility(args.id, args.modeSpec)
        return true
    end
    return false
end

return Handler
