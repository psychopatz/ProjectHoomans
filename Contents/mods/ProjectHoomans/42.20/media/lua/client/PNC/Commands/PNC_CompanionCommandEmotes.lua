-- ZedColonies-style radial adapter. Command behavior remains in the shared
-- registry; this module only resolves nearby targets and renders command
-- scopes. Nested groups stay private so vanilla never exposes them as roots.

require "ISUI/ISEmoteRadialMenu"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

PNC = PNC or {}
PNC.CompanionCommandEmotes = PNC.CompanionCommandEmotes or {}

local Emotes = PNC.CompanionCommandEmotes
local Commands = PNC.CompanionCommands
local Const = PNC.Const
local Registry = PNC.Registry
local ClientState = PNC.Network and PNC.Network.ClientState or nil
local Identity = PNC.NPCIdentityPresentation
local CLOSEST_MENU_KEY = "PNC_ClosestCompanionCommands"
local GROUP_MENU_KEY = "PNC_GroupCompanionCommands"
local CLOSEST_COMMAND_PREFIX = "PNC_ClosestCommand_"
local GROUP_COMMAND_PREFIX = "PNC_GroupCommand_"
local CLOSEST_GROUP_PREFIX = "PNC_ClosestCommandGroup_"

if ISEmoteRadialMenu.PNCCompanionCommandsInstalled == true then
    return Emotes
end

local originalInit = ISEmoteRadialMenu.init
local originalEmote = ISEmoteRadialMenu.emote

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function replaceTokens(text, values)
    local output = tostring(text or "")
    local key
    local value
    for key, value in pairs(values or {}) do
        output = string.gsub(output, "{" .. tostring(key) .. "}", function()
            return tostring(value or "")
        end)
    end
    return output
end

local function targetName(source)
    return Identity.GetName(source or { recruited = true })
end

local function hasOwnerIdentity(source)
    return source and (
        source.ownerUsername ~= nil
        or source.ownerOnlineID ~= nil
        or source.characterWindow
            and (
                source.characterWindow.ownerUsername ~= nil
                or source.characterWindow.ownerOnlineID ~= nil
            )
    ) or false
end

local function isClientCommandCandidate(source, player, radius)
    local x
    local y
    local z
    local dx
    local dy
    if not source or not player
        or source.alive == false
        or tostring(source.presenceState or Const.PRESENCE_LIVE)
            ~= tostring(Const.PRESENCE_LIVE)
        or not Commands or not Commands.IsCompanion
        or not Commands.IsCompanion(source)
    then
        return false
    end
    if hasOwnerIdentity(source)
        and (not Commands.IsOwnedByPlayer
            or not Commands.IsOwnedByPlayer(source, player))
    then
        return false
    end
    x = tonumber(source.x)
    y = tonumber(source.y)
    z = tonumber(source.z)
    if x == nil or y == nil or z == nil then return false end
    if math.floor(z) ~= math.floor(tonumber(player:getZ()) or 0) then
        return false
    end
    dx = x - player:getX()
    dy = y - player:getY()
    return (dx * dx) + (dy * dy) <= radius * radius
end

local function pushCandidate(output, seen, player, source, radius)
    local id = source and source.id and tostring(source.id) or nil
    local x
    local y
    local dx
    local dy
    if not id or seen[id] then return end
    if not isClientCommandCandidate(source, player, radius) then return end
    x = tonumber(source.x)
    y = tonumber(source.y)
    if x == nil or y == nil then return end
    dx = x - player:getX()
    dy = y - player:getY()
    seen[id] = true
    output[#output + 1] = {
        id = id,
        name = targetName(source),
        attackType = Commands.GetCurrentAttackType(source),
        distSq = (dx * dx) + (dy * dy),
        source = source,
    }
end

function Emotes.CollectNearbyCompanions(player)
    local output = {}
    local seen = {}
    local radius = tonumber(Const.COMPANION_COMMAND_RADIUS) or 20
    local id
    local snapshot
    if not player or player.isDead and player:isDead() then return output end
    if Registry and Registry.ForEach then
        Registry.ForEach(function(record)
            pushCandidate(output, seen, player, record, radius)
        end)
    end
    for id, snapshot in pairs(
        ClientState and ClientState.snapshots or {}
    ) do
        pushCandidate(output, seen, player, snapshot, radius)
    end
    table.sort(output, function(left, right)
        if left.distSq ~= right.distSq then
            return left.distSq < right.distSq
        end
        if left.name ~= right.name then
            return left.name < right.name
        end
        return left.id < right.id
    end)
    return output
end

function Emotes.ResolveAttackTypeIcon(target)
    local definition = Commands and Commands.GetAttackTypeDefinition
        and Commands.GetAttackTypeDefinition(target and target.attackType)
        or nil
    return definition and definition.icon
        or "media/ui/Emotes/PNC_EmoteProtect.png"
end

function Emotes.Play(player, commandID)
    if PNC.CompanionCommandPresentation
        and PNC.CompanionCommandPresentation.PlayCommand
    then
        return PNC.CompanionCommandPresentation.PlayCommand(
            player,
            commandID
        )
    end
    local definition = Commands and Commands.Get(commandID) or nil
    if not player or not definition or not definition.emote
        or player.isDead and player:isDead()
        or not player.playEmote
    then
        return false
    end
    player:playEmote(definition.emote)
    return true
end

function Emotes.BuildMenuDefinition(scope, target, nestedMenus)
    local output = {}
    local nested = {}
    local definitions = Commands and Commands.List and Commands.List() or {}
    local commandPrefix = scope == "group"
        and GROUP_COMMAND_PREFIX or CLOSEST_COMMAND_PREFIX
    local i
    local definition
    local group
    local groupID
    local groupKey
    local commandKey
    for i = 1, #definitions do
        definition = definitions[i]
        if definition.contextOnly ~= true
            and not (scope == "group" and definition.attackType ~= nil)
        then
            groupID = tostring(definition.group or "")
            group = Commands and Commands.GetGroup
                and Commands.GetGroup(groupID) or nil
            commandKey = commandPrefix .. definition.id
            if scope == "closest" and group and group.nested == true then
                groupKey = CLOSEST_GROUP_PREFIX .. groupID
                nested[groupID] = nested[groupID] or {
                    labels = {},
                    order = {},
                }
                nested[groupID].labels[commandKey] =
                    tr(definition.labelKey, definition.label)
                nested[groupID].order[#nested[groupID].order + 1] =
                    commandKey
                output[groupKey] = tr(
                    group.labelKey,
                    group.label or groupID
                )
            else
                output[commandKey] =
                    tr(definition.labelKey, definition.label)
            end
            if definition.icon and getTexture then
                ISEmoteRadialMenu.icons[commandKey] =
                    getTexture(definition.icon)
            end
        end
    end
    for groupID, _ in pairs(nested) do
        group = Commands.GetGroup(groupID)
        groupKey = CLOSEST_GROUP_PREFIX .. groupID
        nestedMenus[groupKey] = {
            name = tr(group.labelKey, group.label or groupID),
            subMenu = nested[groupID].labels,
            subMenuOrder = nested[groupID].order,
            backMenuKey = CLOSEST_MENU_KEY,
        }
        if getTexture then
            ISEmoteRadialMenu.icons[groupKey] = getTexture(
                group.dynamicAttackTypeIcon == true
                    and Emotes.ResolveAttackTypeIcon(target)
                    or group.icon
            )
        end
    end
    return output
end

function Emotes.OpenNestedGroup(radial, groupKey)
    local definition = radial and radial.PNCCommandNestedMenus
        and radial.PNCCommandNestedMenus[groupKey] or nil
    local radialMenu
    local commandKey
    local label
    local icon
    local i
    if not radial or not definition or type(definition.subMenu) ~= "table"
        or not getPlayerRadialMenu
    then
        return false
    end
    radialMenu = getPlayerRadialMenu(radial.playerNum or 0)
    if not radialMenu then return false end
    radialMenu:clear()
    for i = 1, #definition.subMenuOrder do
        commandKey = definition.subMenuOrder[i]
        label = definition.subMenu[commandKey]
        icon = ISEmoteRadialMenu.icons[commandKey]
        radialMenu:addSlice(
            label,
            icon,
            radial.emote,
            radial,
            commandKey
        )
    end
    radialMenu:addSlice(
        getText and getText("IGUI_Emote_Back") or "Back",
        ISEmoteRadialMenu.icons.back,
        radial.fillMenu,
        radial,
        definition.backMenuKey
    )
    radial:display()
    return true
end

function ISEmoteRadialMenu:init()
    local player
    local closest
    local closestLabel
    local closestVisual
    originalInit(self)
    ISEmoteRadialMenu.menu = ISEmoteRadialMenu.menu or {}
    ISEmoteRadialMenu.icons = ISEmoteRadialMenu.icons or {}
    player = self.character
        or getSpecificPlayer and getSpecificPlayer(self.playerNum or 0)
        or nil
    self.PNCNearbyCompanions = Emotes.CollectNearbyCompanions(player)
    self.PNCClosestCompanion = self.PNCNearbyCompanions[1]
    self.PNCCommandNestedMenus = {}
    closest = self.PNCClosestCompanion
    closestVisual = closest or {
        name = "Companion",
        attackType = "auto",
    }
    closestLabel = closest and replaceTokens(
                tr(
                    "UI_PNC_ClosestCompanionCommands",
                    "Closest Companion: {name}"
                ),
                { name = closest.name }
            )
        or tr(
            "UI_PNC_ClosestCompanionCommandsPending",
            "Closest Companion"
        )
    ISEmoteRadialMenu.menu[CLOSEST_MENU_KEY] = {
        name = closestLabel,
        subMenu = Emotes.BuildMenuDefinition(
            "closest",
            closestVisual,
            self.PNCCommandNestedMenus
        ),
    }
    if getTexture then
        ISEmoteRadialMenu.icons[CLOSEST_MENU_KEY] =
            getTexture(Emotes.ResolveAttackTypeIcon(closestVisual))
    end
    ISEmoteRadialMenu.menu[GROUP_MENU_KEY] = {
        name = tr(
            "UI_PNC_GroupCompanionCommands",
            "All Nearby Companions"
        ),
        subMenu = Emotes.BuildMenuDefinition(
            "group",
            nil,
            self.PNCCommandNestedMenus
        ),
    }
    if getTexture then
        ISEmoteRadialMenu.icons[GROUP_MENU_KEY] =
            getTexture("media/ui/Emotes/PNC_EmoteMenu.png")
    end
end

function ISEmoteRadialMenu:emote(emote)
    local emoteName = tostring(emote or "")
    local commandID
    local definition
    local scope
    local target
    local targets
    local sent = false
    local player
    if string.sub(emoteName, 1, string.len(CLOSEST_GROUP_PREFIX))
        == CLOSEST_GROUP_PREFIX
    then
        return Emotes.OpenNestedGroup(self, emoteName)
    end
    if string.sub(emoteName, 1, string.len(CLOSEST_COMMAND_PREFIX))
        == CLOSEST_COMMAND_PREFIX
    then
        scope = "closest"
        commandID = string.sub(
            emoteName,
            string.len(CLOSEST_COMMAND_PREFIX) + 1
        )
        target = self.PNCClosestCompanion
        targets = target and { target } or {}
    elseif string.sub(emoteName, 1, string.len(GROUP_COMMAND_PREFIX))
        == GROUP_COMMAND_PREFIX
    then
        scope = "group"
        commandID = string.sub(
            emoteName,
            string.len(GROUP_COMMAND_PREFIX) + 1
        )
        targets = self.PNCNearbyCompanions or {}
    else
        return originalEmote(self, emote)
    end
    definition = Commands and Commands.Get(commandID) or nil
    if not definition then return false end
    if PNC.Client and PNC.Client.SendCompanionCommand then
        sent = PNC.Client.SendCompanionCommand(
            commandID,
            target and target.id or nil,
            scope
        ) == true
    end
    player = getSpecificPlayer
        and getSpecificPlayer(self.playerNum or 0) or self.character
    if sent and PNC.CompanionCommandPresentation
        and PNC.CompanionCommandPresentation.ShowPlayerFlavor
    then
        PNC.CompanionCommandPresentation.ShowPlayerFlavor(
            player,
            commandID,
            {
                scope = scope,
                target = target,
                targets = targets,
            }
        )
    end
    return originalEmote(self, definition.emote)
end

ISEmoteRadialMenu.PNCCompanionCommandsInstalled = true

return Emotes
