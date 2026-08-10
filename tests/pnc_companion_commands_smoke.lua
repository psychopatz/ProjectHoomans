local SHARED_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Commands/"
local CLIENT_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local records = {}
local broadcasts = {}
local marked = {}

local function companion(id, owner, x)
    return {
        id = id,
        alive = true,
        faction = "colonist",
        recruited = true,
        ownerUsername = owner,
        ownerOnlineID = owner == "alice" and 7 or 8,
        presenceState = "live",
        x = x or 0,
        y = 0,
        z = 0,
        runtime = {},
    }
end

records.owned = companion("owned", "alice", 2)
records.owned_second = companion("owned_second", "alice", 6)
records.other_owner = companion("other_owner", "bob", 2)
records.far = companion("far", "alice", 40)
records.abstract = companion("abstract", "alice", 2)
records.abstract.presenceState = "abstract"
records.neutral = companion("neutral", "alice", 2)
records.neutral.faction = "neutral"
records.neutral.recruited = false

PNC = {
    Const = {
        FACTION_COLONIST = "colonist",
        PRESENCE_LIVE = "live",
        ORDER_FOLLOW = "follow",
        ORDER_GUARD = "guard",
        COMPANION_COMMAND_RADIUS = 20,
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_MELEE = "melee",
        ATTACK_TYPE_RANGED = "ranged",
        ATTACK_TYPE_NONE = "none",
    },
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 1234 end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function() return nil end,
        ForEach = function(callback)
            local id
            local record
            for id, record in pairs(records) do callback(record, id) end
        end,
        MarkDirty = function(record, domain)
            marked[#marked + 1] = { id = record.id, domain = domain }
        end,
    },
    OrderSystem = {
        SetOrder = function(record, orderSpec)
            record.orderSpec = orderSpec
        end,
    },
    Network = {
        BroadcastRecord = function(record, reason)
            broadcasts[#broadcasts + 1] = {
                id = record.id,
                reason = reason,
            }
        end,
    },
    Equipment = {
        Describe = function(record)
            return {
                combatModeResolved = record.weaponMode,
                weaponStatus = tostring(record.weaponMode) .. "_ready",
            }
        end,
    },
}

dofile(SHARED_ROOT .. "PNC_CompanionCommandRegistry.lua")
dofile(SHARED_ROOT .. "PNC_CompanionCommandDefinitions.lua")
dofile(SHARED_ROOT .. "PNC_CompanionCommandFlavor.lua")
dofile(SHARED_ROOT .. "PNC_CompanionCommandFlavorDefinitions.lua")

assert(PNC.CompanionCommandFlavor.Resolve("follow", "player", "seed"),
    "built-in player flavor missing")
assert(PNC.CompanionCommandFlavor.Resolve("follow", "npc", "seed"),
    "built-in NPC flavor missing")
assertEqual(PNC.CompanionCommandFlavor.Register("extension_command", {
    player = {
        { key = "UI_Extension_Command", fallback = "Extension fallback." },
    },
}), true, "extension flavor registration")
assertEqual(PNC.CompanionCommandFlavor.Resolve(
    "extension_command",
    "player",
    "seed"
), "Extension fallback.", "extension flavor fallback")
local namedFlavor = PNC.CompanionCommandFlavor.Resolve(
    "follow",
    "player",
    "named_seed",
    { name = "Walker Sage", names = "Walker Sage", count = 1 }
)
assert(string.find(namedFlavor, "Walker Sage", 1, true),
    "player flavor omitted companion name")
local flavorVariants = {}
for i = 1, 20 do
    flavorVariants[PNC.CompanionCommandFlavor.Resolve(
        "follow",
        "player",
        tostring(i),
        { name = "Walker Sage", names = "Walker Sage", count = 1 }
    )] = true
end
local flavorVariantCount = 0
for _ in pairs(flavorVariants) do
    flavorVariantCount = flavorVariantCount + 1
end
assert(flavorVariantCount >= 2, "player flavor did not vary by seed")

local player = {
    getUsername = function() return "alice" end,
    getOnlineID = function() return 7 end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}

-- Single-player factions use the slot account key, not the display username.
PNC.PlayerCharacters = {
    GetCharacterUUID = function() return "char_alice" end,
    Registry = {
        byUUID = {
            char_alice = {
                accountKey = "sp_slot_0",
                accountIdentity = "alice",
            },
        },
    },
}
PNC.EntityRef = {
    ForPlayerIdentity = function(account, uuid)
        return "player:" .. tostring(account) .. ":" .. tostring(uuid)
    end,
}
PNC.Factions = {
    Registry = {
        byID = {
            faction_alice = {
                ownerPlayerKey = "player:sp_slot_0:char_alice",
                playerMemberKeys = {
                    ["player:sp_slot_0:char_alice"] = true,
                },
            },
        },
    },
}
records.owned.affiliation = { factionID = "faction_alice" }
assertEqual(PNC.CompanionCommands.IsOwnedByPlayer(records.owned, player),
    true, "single-player faction ownership uses canonical account key")

assertEqual(#PNC.CompanionCommands.List(), 6, "registered command count")
assertEqual(#PNC.CompanionCommands.ListGroups(), 2,
    "registered command group count")
assertEqual(
    PNC.CompanionCommands.GetAttackTypeDefinition("auto").icon,
    "media/ui/emotes/yes.png",
    "auto attack icon"
)
assertEqual(
    PNC.CompanionCommands.GetAttackTypeDefinition("melee").icon,
    "media/ui/emotes/comefromfront.png",
    "melee attack icon"
)
assertEqual(
    PNC.CompanionCommands.GetAttackTypeDefinition("ranged").icon,
    "media/ui/emotes/fire.png",
    "ranged attack icon"
)
local affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "owned",
    commandID = "stay",
})
assertEqual(affected, 1, "targeted companion command")
assertEqual(reason, "commanded", "targeted companion result")
assertEqual(records.owned.orderSpec.kind, "guard", "stay order")
assertEqual(records.owned.orderSpec.x, 2, "stay anchor")

affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "neutral",
    commandID = "follow",
})
assertEqual(affected, 0, "neutral NPC command rejected")
assertEqual(reason, "not_companion", "neutral rejection reason")

affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "other_owner",
    commandID = "follow",
})
assertEqual(affected, 0, "other player's companion rejected")
assertEqual(reason, "not_owner", "ownership rejection reason")

affected, reason = PNC.CompanionCommands.Execute(player, {
    commandID = "attack_ranged",
    scope = "closest",
    radius = 200,
})
assertEqual(affected, 1, "closest command affects one nearby companion")
assertEqual(records.owned.orderSpec.kind, "guard",
    "attack type changed movement order")
assertEqual(records.owned.weaponMode, "ranged", "ranged attack mode")
assertEqual(records.owned.attackType, "ranged", "ranged attack type")
assertEqual(records.owned_second.attackType, nil,
    "closest attack type changed a second companion")
assertEqual(records.owned.runtime.combatModeResolved, "ranged",
    "attack type equipment state refresh")
assertEqual(records.far.attackType, nil, "bulk radius bypassed server maximum")
assertEqual(records.abstract.attackType, nil, "abstract companion was commanded")
affected, reason = PNC.CompanionCommands.Execute(player, {
    commandID = "attack_auto",
    scope = "group",
})
assertEqual(affected, 0, "group attack type was accepted")
assertEqual(reason, "personalized_command",
    "group attack type rejection reason")
affected, reason = PNC.CompanionCommands.Execute(player, {
    commandID = "follow",
    scope = "group",
})
assertEqual(affected, 2, "group movement command target count")
assertEqual(records.owned.orderSpec.kind, "follow",
    "group follow did not update closest companion")
assertEqual(records.owned_second.orderSpec.kind, "follow",
    "group follow did not update second companion")
records.owned.runtime.attackAction = { finishAt = 9999 }
affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "owned",
    commandID = "attack_none",
})
assertEqual(affected, 1, "don't attack command")
assertEqual(records.owned.attackType, "none", "don't attack preference")
assertEqual(records.owned.orderSpec.kind, "follow",
    "don't attack preserved movement order")
assertEqual(records.owned.runtime.attackAction, nil,
    "don't attack cancelled committed attack")
assertEqual(PNC.CompanionCommands.IsCurrent(records.owned, "attack_none"),
    true, "current attack type")
assert(#broadcasts >= 2, "companion changes were not broadcast")

local spoken = {}
player.Say = function(_, text)
    spoken[#spoken + 1] = text
end
player.playEmote = function() end
PNC.CompanionCommandPresentation = nil
dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Knowledge/PNC_NPCIdentityPresentation.lua")
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
dofile(CLIENT_ROOT .. "Commands/PNC_CompanionCommandPresentation.lua")
for i = 1, 8 do
    PNC.CompanionCommandPresentation.ShowPlayerFlavor(
        player,
        "follow",
        { target = { name = "Walker Sage" } }
    )
end
local spokenVariants = {}
for i = 1, #spoken do
    assert(string.find(spoken[i], "Walker Sage", 1, true),
        "presented player flavor omitted target name")
    spokenVariants[spoken[i]] = true
end
local spokenVariantCount = 0
for _ in pairs(spokenVariants) do
    spokenVariantCount = spokenVariantCount + 1
end
assert(spokenVariantCount >= 2,
    "presented player flavor remained repetitive")

local registeredProvider
local sent = {}
local played = {}

local function newMenu()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = { name = name, target = target, callback = callback }
        self.options[#self.options + 1] = option
        return option
    end
    function menu:addSubMenu(option, submenu)
        option.submenu = submenu
    end
    return menu
end

PNC.ContextHub = {
    RegisterProvider = function(provider) registeredProvider = provider end,
    ApplyOptionPresentation = function(option, state)
        option.notAvailable = state.disabled == true
            and state.color == "bad"
        return option
    end,
}
PNC.Client = {
    SendCompanionCommand = function(commandID, npcId)
        sent[#sent + 1] = { commandID = commandID, npcId = npcId }
        return true
    end,
}
PNC.CompanionCommandPresentation = {
    PlayCommand = function(_, commandID, target)
        played[#played + 1] = {
            commandID = commandID,
            target = target,
        }
        return true
    end,
}
ISContextMenu = { getNew = function() return newMenu() end }
getText = function(key) return key end
getTexture = function(path) return path end

dofile(CLIENT_ROOT
    .. "UI/Context/Providers/PNC_ContextProvider_Commands.lua")

local ownedSnapshot = {
    id = "client_owned",
    alive = true,
    faction = "colonist",
    recruited = true,
    presenceState = "live",
    x = 1,
    y = 0,
    z = 0,
    displayName = "Walker Sage",
    attackType = "none",
    characterWindow = { ownerUsername = "alice" },
}

local selectedZombie = {
    getX = function() return 2 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getModData = function() return { PNC_UUID = "client_owned" } end,
}
local movingObjects = {
    size = function() return 1 end,
    get = function() return selectedZombie end,
}
local selectedSquare = {
    getX = function() return 2 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getMovingObjects = function() return movingObjects end,
}
PNC.Network.ClientState = {
    snapshots = { client_owned = ownedSnapshot },
}
PNC.Registry.FindRecordByZombie = function() return nil end
instanceof = function() return true end
getCell = function()
    return { getGridSquare = function() return nil end }
end
dofile(CLIENT_ROOT .. "UI/Context/PNC_NPCSelection.lua")
local selectedEntries = PNC.NPCSelection.CollectNearbyNPCs(
    player,
    { { getSquare = function() return selectedSquare end } },
    3
)
assertEqual(#selectedEntries, 1, "multiplayer snapshot NPC selection")
assertEqual(selectedEntries[1].snapshot, ownedSnapshot,
    "live body selection discarded authoritative client snapshot")

assertEqual(registeredProvider.isEnabled(
    selectedEntries[1],
    player
), true, "owned companion context provider")
assertEqual(registeredProvider.isEnabled(
    { id = "neutral", snapshot = records.neutral },
    player
), false, "neutral context provider hidden")

local context = newMenu()
registeredProvider.addOptions(
    context,
    selectedEntries[1],
    player
)
assertEqual(context.options[1].name, "Companion Commands",
    "context command root")
assertEqual(#context.options[1].submenu.options, 3,
    "movement commands and nested attack root")
assertEqual(context.options[1].submenu.options[3].name, "Attack Type",
    "nested attack type root")
local attackOptions = context.options[1].submenu.options[3].submenu.options
assertEqual(#attackOptions, 4, "attack type definitions")
assertEqual(attackOptions[4].notAvailable, true,
    "current attack type is disabled and red")
assertEqual(
    context.options[1].submenu.options[3].iconTexture,
    "media/ui/emotes/no.png",
    "context attack type icon did not reflect current setting"
)
attackOptions[3].callback()
assertEqual(sent[1].commandID, "attack_ranged",
    "context command dispatch")
assertEqual(sent[1].npcId, "client_owned",
    "context targeted companion")
assertEqual(played[1].commandID, "attack_ranged",
    "context command visual emote")
assertEqual(played[1].target.id, "client_owned",
    "context flavor target")

local radialSent = {}
local originalVisual
local displayed = 0
local radialSlices = {}
local radialFlavor
ISEmoteRadialMenu = {
    menu = {},
    icons = {},
    init = function()
        ISEmoteRadialMenu.menu = {}
        ISEmoteRadialMenu.icons = {}
    end,
    emote = function(_, emote)
        originalVisual = emote
        return emote
    end,
    fillMenu = function(self, submenu)
        local menu = getPlayerRadialMenu(self.playerNum or 0)
        local key
        local label
        menu:clear()
        for key, label in pairs(
            ISEmoteRadialMenu.menu[submenu].subMenu
        ) do
            menu:addSlice(
                label,
                ISEmoteRadialMenu.icons[key],
                self.emote,
                self,
                key
            )
        end
        menu:addSlice(
            "Back",
            ISEmoteRadialMenu.icons.back,
            self.fillMenu,
            self,
            nil
        )
        originalVisual = submenu
    end,
    display = function()
        displayed = displayed + 1
    end,
}
getSpecificPlayer = function() return player end
getPlayerRadialMenu = function()
    return {
        clear = function()
            radialSlices = {}
        end,
        addSlice = function(_, label, icon, callback, target, value)
            radialSlices[#radialSlices + 1] = {
                label = label,
                icon = icon,
                callback = callback,
                target = target,
                value = value,
            }
        end,
    }
end
package.preload["ISUI/ISEmoteRadialMenu"] = function()
    return ISEmoteRadialMenu
end
PNC.CompanionCommandEmotes = nil
PNC.Client.SendCompanionCommand = function(commandID, npcId, scope)
    radialSent[#radialSent + 1] = {
        commandID = commandID,
        npcId = npcId,
        scope = scope,
    }
    return true
end
PNC.CompanionCommandPresentation.ShowPlayerFlavor =
    function(_, commandID, contextData)
        radialFlavor = {
            commandID = commandID,
            context = contextData,
        }
        return true
    end

dofile(CLIENT_ROOT .. "Commands/PNC_CompanionCommandEmotes.lua")

PNC.Network.ClientState.snapshots.roster_owned = {
    id = "roster_owned",
    displayName = "Roster Companion",
    alive = true,
    faction = "colonist",
    recruited = true,
    presenceState = "live",
    x = 0.5,
    y = 0,
    z = 0,
    attackType = "auto",
}
local rosterCandidates =
    PNC.CompanionCommandEmotes.CollectNearbyCompanions(player)
local foundRosterCandidate = false
for i = 1, #rosterCandidates do
    if rosterCandidates[i].id == "roster_owned" then
        foundRosterCandidate = true
    end
end
assertEqual(foundRosterCandidate, true,
    "roster snapshot without owner detail hid closest commands")
PNC.Network.ClientState.snapshots.roster_owned = nil

local radial = {}
setmetatable(radial, { __index = ISEmoteRadialMenu })
radial:init()
assertEqual(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands.name,
    "Closest Companion: Walker Sage",
    "closest radial command root"
)
assertEqual(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands
        .subMenu.PNC_ClosestCommand_follow,
    "Follow Me",
    "closest radial follow slice"
)
assertEqual(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands
        .subMenu.PNC_ClosestCommandGroup_attack_type,
    "Attack Type",
    "radial nested attack type slice"
)
assertEqual(
    ISEmoteRadialMenu.menu.PNC_GroupCompanionCommands
        .subMenu.PNC_GroupCommand_attack_auto,
    nil,
    "attack type leaked into group wheel"
)
assertEqual(
    ISEmoteRadialMenu.menu.PNC_ClosestCommandGroup_attack_type,
    nil,
    "private attack subgroup leaked into vanilla radial roots"
)
assertEqual(
    radial.PNCCommandNestedMenus.PNC_ClosestCommandGroup_attack_type
        .subMenu.PNC_ClosestCommand_attack_none,
    "Don't Attack",
    "radial nested don't attack slice"
)
assertEqual(
    ISEmoteRadialMenu.icons.PNC_GroupCompanionCommands,
    "media/ui/Emotes/PNC_EmoteMenu.png",
    "framework group radial icon"
)
assertEqual(
    ISEmoteRadialMenu.icons.PNC_ClosestCompanionCommands,
    "media/ui/emotes/no.png",
    "closest root icon did not reflect target attack type"
)
assertEqual(
    ISEmoteRadialMenu.icons.PNC_ClosestCommandGroup_attack_type,
    "media/ui/emotes/no.png",
    "attack subgroup icon did not reflect target attack type"
)
assertEqual(
    ISEmoteRadialMenu.icons.PNC_GroupCommand_follow,
    "media/ui/Emotes/PNC_EmoteFollow.png",
    "framework group follow radial icon"
)
radial:fillMenu("PNC_ClosestCompanionCommands")
local foundAttackTypeSlice = false
for i = 1, #radialSlices do
    if radialSlices[i].value
        == "PNC_ClosestCommandGroup_attack_type"
    then
        foundAttackTypeSlice = true
    end
end
assertEqual(foundAttackTypeSlice, true,
    "vanilla closest submenu omitted attack type slice")
radial:emote("PNC_ClosestCommandGroup_attack_type")
assertEqual(#radialSlices, 5,
    "nested radial attack commands plus back")
assertEqual(radialSlices[1].value, "PNC_ClosestCommand_attack_auto",
    "nested radial stable auto order")
assertEqual(radialSlices[4].value, "PNC_ClosestCommand_attack_none",
    "nested radial stable don't-attack order")
assertEqual(radialSlices[5].value, "PNC_ClosestCompanionCommands",
    "nested radial back target")
assertEqual(displayed, 1, "nested radial displayed")
radial:emote("PNC_ClosestCommand_attack_ranged")
assertEqual(radialSent[1].commandID, "attack_ranged",
    "closest radial command dispatch")
assertEqual(radialSent[1].npcId, "client_owned",
    "closest radial target")
assertEqual(radialSent[1].scope, "closest",
    "closest radial scope")
assertEqual(radialFlavor.context.targets[1].name, "Walker Sage",
    "closest radial flavor target name")
radial:emote("PNC_GroupCommand_follow")
assertEqual(radialSent[2].commandID, "follow",
    "group radial command dispatch")
assertEqual(radialSent[2].npcId, nil, "group radial target should be nil")
assertEqual(radialSent[2].scope, "group", "group radial scope")
assert(#radialFlavor.context.targets >= 1,
    "group radial flavor omitted nearby companions")
assertEqual(originalVisual, "followme", "radial visual emote")
radial:emote("wavehi")
assertEqual(originalVisual, "wavehi", "ordinary emote delegation")

local savedForEach = PNC.Registry.ForEach
local savedSnapshots = PNC.Network.ClientState.snapshots
PNC.Registry.ForEach = function() end
PNC.Network.ClientState.snapshots = {}
local syncingRadial = {}
setmetatable(syncingRadial, { __index = ISEmoteRadialMenu })
syncingRadial:init()
assertEqual(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands
        .subMenu.PNC_ClosestCommandGroup_attack_type,
    "Attack Type",
    "sync gap hid personalized attack type"
)
syncingRadial:emote("PNC_ClosestCommand_attack_auto")
assertEqual(radialSent[#radialSent].scope, "closest",
    "sync-gap closest command scope")
assertEqual(radialSent[#radialSent].npcId, nil,
    "sync-gap closest command trusted a stale target")
PNC.Registry.ForEach = savedForEach
PNC.Network.ClientState.snapshots = savedSnapshots

print("pnc_companion_commands_smoke: ok")
