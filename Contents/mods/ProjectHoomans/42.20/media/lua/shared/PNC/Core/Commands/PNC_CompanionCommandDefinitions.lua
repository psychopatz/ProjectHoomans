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
        return {
            kind = Const.ORDER_GUARD,
            x = tonumber(record.x) or 0,
            y = tonumber(record.y) or 0,
            z = tonumber(record.z) or 0,
        }
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
