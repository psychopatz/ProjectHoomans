-- Companion-only context adapter for the shared command registry.

PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local ContextHub = PNC.ContextHub
local Commands = PNC.CompanionCommands
local Provider = { id = "companion_commands" }

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function commandTarget(entry)
    return entry and (entry.record or entry.snapshot) or nil
end

function Provider.isEnabled(entry, player)
    if not Commands or not Commands.CanPlayerCommand then return false end
    return Commands.CanPlayerCommand(
        commandTarget(entry),
        player,
        PNC.Const.COMPANION_COMMAND_RADIUS
    ) == true
end

function Provider.addOptions(menu, entry, player)
    local commandMenu = ISContextMenu:getNew(menu)
    local definitions = Commands.List()
    local nestedMenus = {}
    local root = menu:addOption(
        tr("UI_PNC_CompanionCommands", "Companion Commands")
    )
    local i
    local definition
    local option
    local group
    local groupID
    local groupRoot
    local targetMenu
    local groupIcon
    menu:addSubMenu(root, commandMenu)
    if root and getTexture then
        root.iconTexture = getTexture(
            "media/ui/Emotes/PNC_EmoteMenu.png"
        )
    end
    for i = 1, #definitions do
        definition = definitions[i]
        if definition.manualTabOnly == true then
            definition = nil
        elseif definition.contextOnly == true
            and type(definition.isVisible) == "function"
            and definition.isVisible(commandTarget(entry)) ~= true
        then
            definition = nil
        elseif type(definition.canApply) == "function"
            and Commands.CanApply
            and Commands.CanApply(
                commandTarget(entry), player, definition.id
            ) ~= true
        then
            definition = nil
        end
        if definition then
        local commandID = definition.id
        groupID = tostring(definition.group or "")
        group = Commands.GetGroup and Commands.GetGroup(groupID) or nil
        if group and group.nested == true and not nestedMenus[groupID] then
            nestedMenus[groupID] = ISContextMenu:getNew(commandMenu)
            groupRoot = commandMenu:addOption(
                tr(group.labelKey, group.label or groupID)
            )
            commandMenu:addSubMenu(groupRoot, nestedMenus[groupID])
            if groupRoot and group.icon and getTexture then
                groupIcon = group.icon
                if group.dynamicAttackTypeIcon == true
                    and Commands.GetAttackTypeDefinition
                then
                    local activeDefinition =
                        Commands.GetAttackTypeDefinition(
                            Commands.GetCurrentAttackType(
                                commandTarget(entry)
                            )
                        )
                    groupIcon = activeDefinition
                        and activeDefinition.icon or groupIcon
                end
                groupRoot.iconTexture = getTexture(groupIcon)
            end
        end
        targetMenu = group and group.nested == true
            and nestedMenus[groupID] or commandMenu
        option = targetMenu:addOption(
            tr(definition.labelKey, definition.label),
            nil,
            function()
                local execute = PNC.Client
                    and (PNC.Client.ExecuteCompanionCommand
                        or PNC.Client.SendCompanionCommand)
                local sent = execute and execute(
                    commandID, entry.id, nil, entry)
                if sent and PNC.CompanionCommandPresentation
                    and PNC.CompanionCommandPresentation.PlayCommand
                then
                    PNC.CompanionCommandPresentation.PlayCommand(
                        player,
                        commandID,
                        entry
                    )
                end
            end
        )
        if option and definition.icon and getTexture then
            option.iconTexture = getTexture(definition.icon)
        end
        if definition.attackType ~= nil
            and Commands.IsCurrent(commandTarget(entry), commandID)
        then
            ContextHub.ApplyOptionPresentation(option, {
                disabled = true,
                color = "bad",
            })
        end
        end
    end
end

ContextHub.RegisterProvider(Provider)

return Provider
