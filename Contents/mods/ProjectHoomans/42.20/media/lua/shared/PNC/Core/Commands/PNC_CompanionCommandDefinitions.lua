-- Add future companion commands here with one Commands.Register definition.
-- Both the emote radial and context-menu provider enumerate this registry.

PNC = PNC or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const

Commands.RegisterGroup({
    id = "movement",
    nested = false,
})

Commands.RegisterGroup({
    id = "attack_type",
    nested = true,
    labelKey = "UI_PNC_CommandAttackType",
    label = "Attack Type",
    icon = "media/ui/Emotes/PNC_EmoteProtect.png",
    dynamicAttackTypeIcon = true,
})

local function followOrder(_, player)
    return {
        kind = Const.ORDER_FOLLOW,
        ownerUsername = player.getUsername and player:getUsername() or nil,
        ownerOnlineID = player.getOnlineID and player:getOnlineID() or nil,
    }
end

local function currentPosition(record)
    local zombie = record and record.id and PNC.Registry
        and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if zombie and (not zombie.isDead or not zombie:isDead()) then
        return zombie:getX(), zombie:getY(), zombie:getZ()
    end
    return tonumber(record and record.x) or 0,
        tonumber(record and record.y) or 0,
        tonumber(record and record.z) or 0
end

Commands.Register({
    id = "follow",
    group = "movement",
    labelKey = "UI_PNC_CommandFollow",
    label = "Follow Me",
    emote = "followme",
    icon = "media/ui/Emotes/PNC_EmoteFollow.png",
    buildOrder = followOrder,
})

Commands.Register({
    id = "stay",
    group = "movement",
    labelKey = "UI_PNC_CommandStay",
    label = "Wait Here",
    emote = "freeze",
    icon = "media/ui/Emotes/PNC_EmoteStay.png",
    buildOrder = function(record)
        local x, y, z = currentPosition(record)
        return {
            kind = Const.ORDER_GUARD,
            x = x,
            y = y,
            z = z,
        }
    end,
})

Commands.Register({
    id = "return_home",
    group = "movement",
    labelKey = "UI_PNC_CommandReturnHome",
    label = "Go Home",
    emote = "followme",
    icon = "media/ui/Emotes/PNC_EmoteFollow.png",
    apply = function(record)
        local home = PNC.HomeDutyService
        if record.runtime and record.runtime.workOrderId
            and PNC.WorkService and PNC.WorkService.Commands
            and PNC.WorkService.Commands.ReleaseWorker
        then
            PNC.WorkService.Commands.ReleaseWorker(
                record.id,
                "return_home_command"
            )
        end
        if not home or not home.SendHome then return false end
        return home.SendHome(record, nil, "companion_command") == true
    end,
})

Commands.Register({
    id = "stop_activity",
    group = "movement",
    labelKey = "UI_PNC_CommandStopActivity",
    label = "Stop Current Activity",
    icon = "media/ui/Emotes/PNC_EmoteStay.png",
    contextOnly = true,
    isVisible = function(record)
        return record and (
            record.runtime and record.runtime.facilityActivity ~= nil
            or record.orderSpec
                and record.orderSpec.kind == "facility_activity"
            or tostring(record.activeJob or "") == "Sleep"
        )
    end,
    apply = function(record)
        return PNC.FacilityJobs and PNC.FacilityJobs.Stop
            and PNC.FacilityJobs.Stop(record, "player_stop") == true
    end,
})

Commands.Register({
    id = "attack_auto",
    group = "attack_type",
    labelKey = "UI_PNC_CommandAttackAuto",
    label = "Auto",
    emote = "signalok",
    icon = "media/ui/emotes/yes.png",
    attackType = Const.ATTACK_TYPE_AUTO or "auto",
})

Commands.Register({
    id = "attack_melee",
    group = "attack_type",
    labelKey = "UI_PNC_CommandAttackMelee",
    label = "Melee",
    emote = "comefront",
    icon = "media/ui/emotes/comefromfront.png",
    attackType = Const.ATTACK_TYPE_MELEE or "melee",
})

Commands.Register({
    id = "attack_ranged",
    group = "attack_type",
    labelKey = "UI_PNC_CommandAttackRanged",
    label = "Ranged",
    emote = "signalfire",
    icon = "media/ui/emotes/fire.png",
    attackType = Const.ATTACK_TYPE_RANGED or "ranged",
})

Commands.Register({
    id = "attack_none",
    group = "attack_type",
    labelKey = "UI_PNC_CommandAttackNone",
    label = "Don't Attack",
    emote = "no",
    icon = "media/ui/emotes/no.png",
    attackType = Const.ATTACK_TYPE_NONE or "none",
})

return Commands
