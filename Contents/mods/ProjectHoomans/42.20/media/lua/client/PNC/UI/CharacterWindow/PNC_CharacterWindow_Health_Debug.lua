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

local function addDebugDamageMenu(context, view, selectedPartId)
    local damageMenu = context:getNew(context)
    local partMenu = context:getNew(context)
    local order = PNC.NPCWounds and PNC.NPCWounds.PartOrder or {}
    local i
    context:addSubMenu(
        context:addOption(Shared.Text("UI_PNC_DebugDamage", "Debug Injury"), nil),
        damageMenu
    )
    damageMenu:addOption(Shared.Text("UI_PNC_DebugDamageRandom", "Random Body Part"), nil, function()
        PNC.Client.SendDebug("damage_part", { id = view.npcId })
    end)
    if selectedPartId and PNC.NPCWounds and PNC.NPCWounds.Parts[selectedPartId] then
        damageMenu:addOption(
            Shared.Text("UI_PNC_DebugDamageSelected", "Injure") .. " " .. localizedPartName(selectedPartId),
            nil,
            function()
                PNC.Client.SendDebug("damage_part", { id = view.npcId, partId = selectedPartId })
            end
        )
    end
    damageMenu:addSubMenu(
        damageMenu:addOption(Shared.Text("UI_PNC_DebugDamageSpecific", "Choose Body Part"), nil),
        partMenu
    )
    for i = 1, #order do
        local damagePartId = order[i]
        partMenu:addOption(localizedPartName(damagePartId), nil, function()
            PNC.Client.SendDebug("damage_part", { id = view.npcId, partId = damagePartId })
        end)
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
    local isWholeBody = partId == "WholeBody"
    local context
    local option
    if (isWholeBody and not canDebug) or (not wound
        or (wound.bandaged == true and wound.bandageDirty ~= true)
        or not player) and not canDebug
    then
        return false
    end
    context = ISContextMenu.get(0, x + view:getAbsoluteX(), y + view:getAbsoluteY())
    -- Whole Body ailments have no wound object and can never enter the normal
    -- bandage flow. Debug menus may still inspect the region explicitly.
    if not isWholeBody and wound
        and (wound.bandaged ~= true or wound.bandageDirty == true) and player then
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
    end
    return true
end


return Debug
