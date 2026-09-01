-- ZedColonies-style radial adapter. Command behavior remains in the shared
-- registry; this module only resolves nearby targets and renders command
-- scopes. Nested groups stay private so vanilla never exposes them as roots.

require "ISUI/ISEmoteRadialMenu"
require "PNC/Commands/PNC_CompanionTargetResolver"

PNC = PNC or {}
PNC.CompanionCommandEmotes = PNC.CompanionCommandEmotes or {}

local Emotes = PNC.CompanionCommandEmotes
local Commands = PNC.CompanionCommands
local Targets = PNC.CompanionTargetResolver
local VanillaInteractions = PNC.VanillaEmoteInteractions
local Core = PNC.Core
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

function Emotes.CollectNearbyCompanions(player)
    return Targets.CollectNearbyCompanions(player)
end

-- Convert the same closest-companion result used by the emote radial menu
-- into the richer entry shape consumed by the conversation definition.
function Emotes.BuildConversationEntry(target)
    return Targets.BuildConversationEntry(target)
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
            and not (scope == "group" and (definition.attackType ~= nil
                or definition.personalized == true))
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
    local nearby
    local closest
    local closestLabel
    local closestVisual
    originalInit(self)
    ISEmoteRadialMenu.menu = ISEmoteRadialMenu.menu or {}
    ISEmoteRadialMenu.icons = ISEmoteRadialMenu.icons or {}
    player = self.character
        or getSpecificPlayer and getSpecificPlayer(self.playerNum or 0)
        or nil
    nearby = Targets.ResolveRecipients(player, "nearby")
    self.PNCNearbyCompanions = nearby and nearby.targets or {}
    self.PNCClosestCompanion = nearby and nearby.target or nil
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
    local vanillaDefinition
    local socialRecipients
    local socialContext
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
        vanillaDefinition = VanillaInteractions
            and VanillaInteractions.Get(emoteName) or nil
        if vanillaDefinition then
            player = self.character
                or getSpecificPlayer and getSpecificPlayer(self.playerNum or 0)
                or nil
            socialRecipients = Targets.ResolveRecipients(
                player,
                "nearby",
                vanillaDefinition.radius,
                Targets.SCOPE_SOCIAL
            )
            socialContext = {
                origin = "vanilla_emote_radial",
                requestID = Core.GenerateID
                    and Core.GenerateID("emote") or tostring(Core.Now()),
                targets = socialRecipients and socialRecipients.targets or {},
            }
            if socialContext.targets and #socialContext.targets > 0
                and PNC.CompanionCommandPresentation
                and PNC.CompanionCommandPresentation.ShowPlayerFlavor
            then
                PNC.CompanionCommandPresentation.ShowPlayerFlavor(
                    player,
                    vanillaDefinition.flavorID,
                    socialContext
                )
            end
            if PNC.Client and PNC.Client.ExecutePlayerEmoteInteraction then
                PNC.Client.ExecutePlayerEmoteInteraction(
                    vanillaDefinition.id,
                    socialContext
                )
            end
        end
        return originalEmote(self, emote)
    end
    definition = Commands and Commands.Get(commandID) or nil
    if not definition then return false end
    local execute = PNC.Client and (PNC.Client.ExecuteCompanionCommand
        or PNC.Client.SendCompanionCommand)
    if execute then
        sent = execute(
            commandID,
            target and target.id or nil,
            scope,
            target
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
    if definition.clientOnly == true then return sent end
    return originalEmote(self, definition.emote)
end

ISEmoteRadialMenu.PNCCompanionCommandsInstalled = true

return Emotes
