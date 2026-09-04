-- Add future companion commands here with one Commands.Register definition.
-- Both the emote radial and context-menu provider enumerate this registry.

PNC = PNC or {}

local Commands = PNC.CompanionCommands
local Const = PNC.Const

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

local function playerCampEligibility(record)
    local query = PNC.TraversalQuery
    local x
    local y
    local z
    local square
    local indoor
    if not query or type(query.GetSquare) ~= "function"
        or type(query.GetInteriorState) ~= "function"
    then
        return false, "camp_requires_building"
    end
    x, y, z = currentPosition(record)
    square = query.GetSquare(x, y, z)
    indoor = query.GetInteriorState(square)
    if indoor ~= true then
        return false, "camp_requires_building"
    end
    return true, "camp_inside_building"
end

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

Commands.RegisterGroup({
    id = "manual_activity",
    nested = true,
    labelKey = "UI_PNC_CommandManualActivity",
    label = "Activities",
})

local function followOrder(_, player)
    return {
        kind = Const.ORDER_FOLLOW,
        ownerUsername = player.getUsername and player:getUsername() or nil,
        ownerOnlineID = player.getOnlineID and player:getOnlineID() or nil,
    }
end

local function manualActivity(record, capability)
    if not PNC.FacilityJobs or not PNC.FacilityJobs.ToggleManual then
        return false
    end
    return PNC.FacilityJobs.ToggleManual(record, capability) == true
end

local function manualProvision(record)
    local scheduler = PNC.ProvisionScheduler
    if not scheduler or not scheduler.RequestManual then return false end
    local ok = scheduler.RequestManual(record)
    return ok == true
end

local function manualCorpseHaul(record)
    local service = PNC.CorpseHaulService
    if not service or not service.RequestManual then return false end
    return service.RequestManual(record)
end

local function stopActivity(record, reason)
    local lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
        and PNC.TaskLeaseService.ForNPC(record.id) or nil
    if lease and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.CancelLease
    then
        local stopped = PNC.Tasking.Commands.CancelLease(
            lease.leaseId, reason or "player_stop")
        if stopped == true
            or not record.runtime
            or not record.runtime.facilityActivity
        then
            return stopped == true
        end
    end
    return PNC.FacilityJobs and PNC.FacilityJobs.Stop
        and PNC.FacilityJobs.Stop(record, reason or "player_stop") == true
        or false
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
    id = "camp",
    group = "movement",
    labelKey = "UI_PNC_CommandCamp",
    label = "Camp Here",
    llmDescription = "Order this companion to stop following and make a temporary camp at their current location. Player-issued camps require the companion to be inside a building. NPC faction AI may override that restriction for its own camps. Use for requests such as 'let's just stay here for now', 'make camp', or 'rest here'. Unlike Wait Here, camp allows the companion to satisfy needs such as sleep, food, and water without requiring a home.",
    emote = "freeze",
    icon = "media/ui/Emotes/PNC_EmoteStay.png",
    canApply = playerCampEligibility,
    buildOrder = function(record)
        local x, y, z = currentPosition(record)
        return {
            kind = Const.ORDER_CAMP or "camp",
            x = x,
            y = y,
            z = z,
            radius = tonumber(Const.CAMP_RADIUS) or 3,
            campId = "camp:" .. tostring(record.id),
            resourceRadius = tonumber(Const.CAMP_RESOURCE_RADIUS) or 12,
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
    apply = function(record, player)
        if PNC.ScavengeService and PNC.ScavengeService.BringBack then
            local handled = PNC.ScavengeService.BringBack(record, player)
            if handled == true then return true end
        end
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
    id = "scavenge_nearby",
    group = "movement",
    labelKey = "UI_PNC_CommandScavengeNearby",
    label = "Scavenge Nearby",
    emote = "lookaround",
    icon = "media/ui/Emotes/PNC_EmoteMenu.png",
    personalized = true,
    clientOnly = true,
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
        return stopActivity(record, "player_stop")
    end,
})

Commands.Register({
    id = "manual_eat",
    group = "manual_activity",
    contextOnly = true,
    manualTabOnly = true,
    labelKey = "UI_PNC_CommandEat",
    label = "Eat",
    icon = "media/ui/Emotes/PNC_EmoteMenu.png",
    apply = function(record)
        return manualActivity(record, "survival.eat.inventory")
    end,
})

Commands.Register({
    id = "manual_drink",
    group = "manual_activity",
    contextOnly = true,
    manualTabOnly = true,
    labelKey = "UI_PNC_CommandDrink",
    label = "Drink",
    icon = "media/ui/Emotes/PNC_EmoteMenu.png",
    apply = function(record)
        return manualActivity(record, "water.drink")
    end,
})

Commands.Register({
    id = "manual_sleep",
    group = "manual_activity",
    contextOnly = true,
    manualTabOnly = true,
    labelKey = "UI_PNC_CommandSleep",
    label = "Toggle Sleep",
    icon = "media/ui/Emotes/PNC_EmoteStay.png",
    apply = function(record)
        return manualActivity(record, "sleep")
    end,
})

Commands.Register({
    id = "manual_provision",
    group = "manual_activity",
    contextOnly = true,
    manualTabOnly = true,
    labelKey = "UI_PNC_CommandProvision",
    label = "Grab Provision",
    icon = "media/ui/Emotes/PNC_EmoteMenu.png",
    apply = manualProvision,
})

Commands.Register({
    id = "manual_corpse_haul",
    group = "manual_activity",
    contextOnly = true,
    manualTabOnly = true,
    labelKey = "UI_PNC_CommandCorpseHaul",
    label = "Grab Corpses",
    icon = "media/ui/Emotes/PNC_EmoteMenu.png",
    apply = manualCorpseHaul,
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
