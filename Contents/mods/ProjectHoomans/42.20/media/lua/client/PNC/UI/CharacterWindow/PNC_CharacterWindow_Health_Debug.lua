local Debug = {}
local Shared = PNC.CharacterWindowShared
local bodyPartText = {}

require "ISUI/ISContextMenu"

function Debug.SetBodyPartText(value)
    bodyPartText = value or {}
end

local function currentWorldHour()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and (tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

local function localizedPartName(partId)
    local part = PNC.NPCWounds and PNC.NPCWounds.Parts and PNC.NPCWounds.Parts[partId] or nil
    return Shared.Text(bodyPartText[partId], part and part.label or tostring(partId or ""))
end

local DEBUG_WOUND_OPTIONS = {
    { id = "scratch", labelKey = "UI_PNC_Wound_scratch", fallback = "Scratch" },
    { id = "laceration", labelKey = "UI_PNC_Wound_laceration", fallback = "Laceration" },
    { id = "bite", labelKey = "UI_PNC_Wound_bite", fallback = "Bite" },
    { id = "burn", labelKey = "UI_PNC_Wound_burn", fallback = "Burn" },
    { id = "fracture", labelKey = "UI_PNC_Wound_fracture", fallback = "Fracture" },
    { id = "deep_wound", labelKey = "UI_PNC_Wound_deep_wound", fallback = "Deep Wound" },
    { id = "deep_wound_glass", labelKey = "UI_PNC_Wound_glass", fallback = "Lodged Glass Shards" },
    { id = "bullet", labelKey = "UI_PNC_Wound_bullet", fallback = "Lodged Bullet" },
}

local function addWoundTypeEntries(menu, view, partId)
    for i = 1, #DEBUG_WOUND_OPTIONS do
        local entry = DEBUG_WOUND_OPTIONS[i]
        local woundType = entry.id
        menu:addOption(Shared.Text(entry.labelKey, entry.fallback), nil, function()
            PNC.Client.SendDebug("damage_part", {
                id = view.npcId,
                partId = partId,
                woundType = woundType,
            })
        end)
    end
end

local function addDebugDamageMenu(context, view, selectedPartId)
    local damageMenu = context:getNew(context)
    local typeMenu = context:getNew(context)
    local partMenu = context:getNew(context)
    local order = PNC.NPCWounds and PNC.NPCWounds.PartOrder or {}
    local validSelected = selectedPartId and PNC.NPCWounds
        and PNC.NPCWounds.Parts[selectedPartId] and selectedPartId or nil
    local i
    context:addSubMenu(
        context:addOption(Shared.Text("UI_PNC_DebugDamage", "Debug Injury"), nil),
        damageMenu
    )
    damageMenu:addOption(Shared.Text("UI_PNC_DebugDamageRandom", "Random Body Part"), nil, function()
        PNC.Client.SendDebug("damage_part", { id = view.npcId })
    end)
    local typeTitle = validSelected
        and (Shared.Text("UI_PNC_DebugDamageSelected", "Injure") .. " " .. localizedPartName(validSelected))
        or Shared.Text("UI_PNC_DebugDamageByType", "Inflict Wound Type")
    local typeOption = damageMenu:addOption(typeTitle, nil, validSelected and function()
        PNC.Client.SendDebug("damage_part", { id = view.npcId, partId = validSelected })
    end or nil)
    damageMenu:addSubMenu(typeOption, typeMenu)
    addWoundTypeEntries(typeMenu, view, validSelected)
    damageMenu:addSubMenu(
        damageMenu:addOption(Shared.Text("UI_PNC_DebugDamageSpecific", "Choose Body Part"), nil),
        partMenu
    )
    for i = 1, #order do
        local damagePartId = order[i]
        local perPartMenu = context:getNew(context)
        local partOption = partMenu:addOption(localizedPartName(damagePartId), nil, function()
            PNC.Client.SendDebug("damage_part", { id = view.npcId, partId = damagePartId })
        end)
        partMenu:addSubMenu(partOption, perPartMenu)
        perPartMenu:addOption(Shared.Text("UI_PNC_DebugDamageRandomType", "Random Wound"), nil, function()
            PNC.Client.SendDebug("damage_part", { id = view.npcId, partId = damagePartId })
        end)
        addWoundTypeEntries(perPartMenu, view, damagePartId)
    end
end

local function addDebugWoundStateMenu(context, view, selectedPartId, wound)
    local stateMenu = context:getNew(context)
    local validPart = selectedPartId and PNC.NPCWounds
        and PNC.NPCWounds.Parts[selectedPartId] and selectedPartId or nil
    context:addSubMenu(
        context:addOption(Shared.Text("UI_PNC_DebugWoundStates", "Debug Wound & Body States"), nil),
        stateMenu
    )
    local states = {
        { action = "dirty_bandage", labelKey = "UI_PNC_DebugWoundState_DirtyBandage", fallback = "Make Bandage Dirty Now" },
        { action = "toggle_splint", labelKey = "UI_PNC_DebugWoundState_ToggleSplint", fallback = "Toggle Splint" },
        { action = "toggle_stitched", labelKey = "UI_PNC_DebugWoundState_ToggleStitched", fallback = "Toggle Stitches" },
        { action = "toggle_ordinary_infection", labelKey = "UI_PNC_DebugWoundState_ToggleInfection", fallback = "Toggle Wound Infection" },
        { action = "toggle_bleeding", labelKey = "UI_PNC_DebugWoundState_ToggleBleeding", fallback = "Toggle Bleeding" },
        { action = "clear_part_wound", labelKey = "UI_PNC_DebugWoundState_ClearPart", fallback = "Clear Part Wound" },
        { action = "incapacitate", labelKey = "UI_PNC_DebugWoundState_Incapacitate", fallback = "Trigger Incapacitated" },
        { action = "heal_all", labelKey = "UI_PNC_DebugWoundState_HealAll", fallback = "Full Heal & Revive" },
    }
    for i = 1, #states do
        local entry = states[i]
        local stateAction = entry.action
        stateMenu:addOption(Shared.Text(entry.labelKey, entry.fallback), nil, function()
            PNC.Client.SendDebug("debug_wound_state", {
                id = view.npcId,
                partId = validPart,
                stateAction = stateAction,
            })
        end)
    end
    if wound and wound.bandaged == true and validPart then
        local almostDirty = stateMenu:addOption(
            Shared.Text("UI_PNC_DebugBandageAlmostDirty", "Make Bandage Almost Dirty"),
            nil,
            function()
                PNC.Client.SendDebug("bandage_almost_dirty", {
                    id = view.npcId,
                    partId = validPart,
                })
            end
        )
        almostDirty.notAvailable = wound.bandageDirty == true
    end
end

local function addDebugInfectionMenu(context, view, selectedPartId, body)
    local infectionMenu = context:getNew(context)
    local infection = body and body.infection or nil
    local infected = infection and (infection.active == true or infection.fatal == true)
    local status = infected and string.format(
        "Status: INFECTED - %s (%.0f%%, %.1f C)",
        tostring(infection.stage or "incubating"),
        (tonumber(infection.progress) or 0) * 100,
        tonumber(infection.temperatureC) or 37
    ) or "Status: NOT INFECTED"
    local statusOption
    context:addSubMenu(
        context:addOption(Shared.Text("UI_PNC_DebugInfection", "Debug Infection"), nil),
        infectionMenu
    )
    statusOption = infectionMenu:addOption(status, nil)
    statusOption.notAvailable = true
    infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionForce", "Force Infected Bite"),
        nil,
        function()
            PNC.Client.SendDebug("infection", {
                id = view.npcId,
                partId = selectedPartId,
                stage = "incubating",
            })
        end
    )
    infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionFever", "Advance to Fever"),
        nil,
        function()
            PNC.Client.SendDebug("infection", {
                id = view.npcId,
                partId = selectedPartId,
                stage = "fever",
            })
        end
    )
    infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionTerminal", "Advance to Terminal"),
        nil,
        function()
            PNC.Client.SendDebug("infection", {
                id = view.npcId,
                partId = selectedPartId,
                stage = "terminal",
            })
        end
    )
    infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionFatal", "Trigger Infection Death"),
        nil,
        function()
            PNC.Client.SendDebug("infection", {
                id = view.npcId,
                partId = selectedPartId,
                stage = "fatal",
            })
        end
    )
    local clearOption = infectionMenu:addOption(
        Shared.Text("UI_PNC_DebugInfectionClear", "Clear Knox Infection"),
        nil,
        function()
            PNC.Client.SendDebug("clear_infection", { id = view.npcId })
        end
    )
    clearOption.notAvailable = not infected
end

local function addDebugBandageMenu(context, view, partId, wound)
    local menu
    local statusOption
    local dirtyAt
    local remaining
    if not wound or wound.bandaged ~= true or not partId then return end
    menu = context:getNew(context)
    context:addSubMenu(
        context:addOption(
            Shared.Text("UI_PNC_DebugBandageState", "Debug Bandage State"),
            nil
        ),
        menu
    )
    dirtyAt = tonumber(wound.dirtyAtWorldHour) or currentWorldHour()
    remaining = math.max(0, dirtyAt - currentWorldHour())
    statusOption = menu:addOption(
        wound.bandageDirty == true and "Status: DIRTY"
            or string.format("Status: clean, %.3f world h remaining", remaining),
        nil
    )
    statusOption.notAvailable = true
    local almostDirty = menu:addOption(
        Shared.Text(
            "UI_PNC_DebugBandageAlmostDirty",
            "Make Bandage Almost Dirty"
        ),
        nil,
        function()
            PNC.Client.SendDebug("bandage_almost_dirty", {
                id = view.npcId,
                partId = partId,
            })
        end
    )
    almostDirty.notAvailable = wound.bandageDirty == true
end

function Debug.ShowHealthMenu(view, partId, x, y)
    local body = Shared.GetSnapshot(view.snapshot, view.payload).bodyHealth
        or view.payload and view.payload.health and view.payload.health.body or {}
    local wound = body and body.wounds and body.wounds[partId] or nil
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local canDebug = PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true
    local canApply = wound and not wound.dressingHealed
        and (not wound.bandaged or wound.bandageDirty)
    local canRemove = wound and (wound.bandaged or wound.splinted)
    if not canDebug and (not player or not (canApply or canRemove)) then return false end

    local context = ISContextMenu.get(0, x + view:getAbsoluteX(), y + view:getAbsoluteY())
    if player and canRemove and PNC.Client and PNC.Client.RemoveBandage then
        local inRange = PNC.Treatment and PNC.Treatment.IsPlayerInBandageRange
            and PNC.Treatment.IsPlayerInBandageRange(player, view.npcId)
        local clientOnly = PNC.Core and PNC.Core.IsClientOnly and PNC.Core.IsClientOnly()
        if wound.bandaged then
            local remove = context:addOption(Shared.Text("ContextMenu_Remove_Bandage", "Remove Bandage"),
                nil, function() PNC.Client.RemoveBandage(view.npcId, partId) end)
            remove.notAvailable = not (inRange or clientOnly)
        end
        if wound.splinted then
            local remove = context:addOption(Shared.Text("ContextMenu_Remove_Splint", "Remove Splint"),
                nil, function() PNC.Client.RemoveBandage(view.npcId, partId, true) end)
            remove.notAvailable = not (inRange or clientOnly)
        end
    end
    if player and canApply then
        local option
        option = context:addOption(Shared.Text("ContextMenu_Bandage", "Bandage"), nil)
        if PNC.BandageMenu and PNC.BandageMenu.AddMaterialOptions then
            PNC.BandageMenu.AddMaterialOptions(
                context,
                option,
                player,
                function(bandageType)
                    PNC.Client.SendBandage(
                        view.npcId,
                        partId,
                        false,
                        bandageType
                    )
                end,
                true
            )
        else
            option.notAvailable = true
        end
        if canDebug then
            context:addOption(Shared.Text("UI_PNC_DebugBandage", "Debug Bandage (No Item)"), nil, function()
                PNC.Client.SendBandage(view.npcId, partId, true)
            end)
        end
    end
    if canDebug then
        addDebugBandageMenu(context, view, partId, wound)
        addDebugDamageMenu(context, view, partId)
        addDebugInfectionMenu(context, view, partId, body)
        addDebugWoundStateMenu(context, view, partId, wound)
    end
    return true
end


return Debug
