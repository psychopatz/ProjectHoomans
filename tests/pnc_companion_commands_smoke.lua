local T = require "tests/support/test"

local SHARED_ROOT =
    T.path("ProjectHoomans", "shared", "PNC/Core/Commands/")
local CLIENT_ROOT =
    T.path("ProjectHoomans", "client", "PNC/")

local records = {}
local broadcasts = {}
local marked = {}
local liveBodies = {}
local sentHome = {}
local releasedWorkers = {}
local manualProvisionRequests = 0

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
        GetLiveZombie = function(id) return liveBodies[tostring(id)] end,
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
    HomeDutyService = {
        SendHome = function(record, _, reason)
            sentHome[#sentHome + 1] = {
                id = record.id,
                reason = reason,
            }
            return true, "RETURNING_HOME"
        end,
    },
    WorkService = {
        Commands = {
            ReleaseWorker = function(id, reason)
                releasedWorkers[#releasedWorkers + 1] = {
                    id = id,
                    reason = reason,
                }
                records[tostring(id)].runtime.workOrderId = nil
                return true
            end,
        },
    },
    ProvisionScheduler = {
        RequestManual = function(record)
            manualProvisionRequests = manualProvisionRequests + 1
            record.manualProvisionRequested = true
            return true, "provision_grabbed"
        end,
    },
}

T.load(SHARED_ROOT .. "PNC_CompanionCommandRegistry.lua")
T.load(SHARED_ROOT .. "PNC_CompanionCommandDefinitions.lua")
T.load(SHARED_ROOT .. "PNC_CompanionCommandFlavor.lua")
T.truthy(PNC.CompanionCommands.Get("manual_eat"),
    "manual eat command is registered")
T.truthy(PNC.CompanionCommands.Get("manual_drink"),
    "manual drink command is registered")
T.truthy(PNC.CompanionCommands.Get("manual_sleep"),
    "manual sleep command is registered")
T.truthy(PNC.CompanionCommands.Get("manual_provision"),
    "manual provision command is registered")
T.equal(PNC.CompanionCommands.Get("manual_sleep").contextOnly, true,
    "manual sleep stays out of the radial command list")
T.load(SHARED_ROOT .. "PNC_CompanionCommandFlavorDefinitions.lua")

T.truthy(PNC.CompanionCommandFlavor.Resolve("follow", "player", "seed"),
    "built-in player flavor missing")
T.truthy(PNC.CompanionCommandFlavor.Resolve("follow", "npc", "seed"),
    "built-in NPC flavor missing")
T.equal(PNC.CompanionCommandFlavor.Register("extension_command", {
    player = {
        { key = "UI_Extension_Command", fallback = "Extension fallback." },
    },
}), true, "extension flavor registration")
T.equal(PNC.CompanionCommandFlavor.Resolve(
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
T.truthy(string.find(namedFlavor, "Walker Sage", 1, true),
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
T.truthy(flavorVariantCount >= 2, "player flavor did not vary by seed")

local player = {
    getUsername = function() return "alice" end,
    getOnlineID = function() return 7 end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}

liveBodies.owned = {
    isDead = function() return false end,
    getX = function() return 3.5 end,
    getY = function() return 1.5 end,
    getZ = function() return 0 end,
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
T.equal(PNC.CompanionCommands.IsOwnedByPlayer(records.owned, player),
    true, "single-player faction ownership uses canonical account key")

T.equal(#PNC.CompanionCommands.List(), 13, "registered command count")
T.equal(PNC.CompanionCommands.Get("scavenge_nearby").clientOnly, true,
    "scavenge command opens its client setup UI")
T.equal(#PNC.CompanionCommands.ListGroups(), 3,
    "registered command group count")

local provisionAffected, provisionReason = PNC.CompanionCommands.Execute(player, {
    id = "owned",
    commandID = "manual_provision",
})
T.equal(provisionAffected, 1, "manual provision command target count")
T.equal(provisionReason, "commanded", "manual provision command result")
T.equal(manualProvisionRequests, 1,
    "manual provision uses the provision scheduler")
T.equal(records.owned.manualProvisionRequested, true,
    "manual provision targets the selected companion")
T.equal(
    PNC.CompanionCommands.GetAttackTypeDefinition("auto").icon,
    "media/ui/emotes/yes.png",
    "auto attack icon"
)
T.equal(
    PNC.CompanionCommands.GetAttackTypeDefinition("melee").icon,
    "media/ui/emotes/comefromfront.png",
    "melee attack icon"
)
T.equal(
    PNC.CompanionCommands.GetAttackTypeDefinition("ranged").icon,
    "media/ui/emotes/fire.png",
    "ranged attack icon"
)
local affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "owned",
    commandID = "stay",
})
T.equal(affected, 1, "targeted companion command")
T.equal(reason, "commanded", "targeted companion result")
T.equal(records.owned.orderSpec.kind, "guard", "stay order")
T.equal(records.owned.orderSpec.x, 3.5, "stay live-body anchor x")
T.equal(records.owned.orderSpec.y, 1.5, "stay live-body anchor y")

affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "neutral",
    commandID = "follow",
})
T.equal(affected, 0, "neutral NPC command rejected")
T.equal(reason, "not_companion", "neutral rejection reason")

affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "other_owner",
    commandID = "follow",
})
T.equal(affected, 0, "other player's companion rejected")
T.equal(reason, "not_owner", "ownership rejection reason")

affected, reason = PNC.CompanionCommands.Execute(player, {
    commandID = "attack_ranged",
    scope = "closest",
    radius = 200,
})
T.equal(affected, 1, "closest command affects one nearby companion")
T.equal(records.owned.orderSpec.kind, "guard",
    "attack type changed movement order")
T.equal(records.owned.weaponMode, "ranged", "ranged attack mode")
T.equal(records.owned.attackType, "ranged", "ranged attack type")
T.equal(records.owned_second.attackType, nil,
    "closest attack type changed a second companion")
T.equal(records.owned.runtime.combatModeResolved, "ranged",
    "attack type equipment state refresh")
T.equal(records.far.attackType, nil, "bulk radius bypassed server maximum")
T.equal(records.abstract.attackType, nil, "abstract companion was commanded")
affected, reason = PNC.CompanionCommands.Execute(player, {
    commandID = "attack_auto",
    scope = "group",
})
T.equal(affected, 0, "group attack type was accepted")
T.equal(reason, "personalized_command",
    "group attack type rejection reason")
affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "owned",
    commandID = "scavenge_nearby",
})
T.equal(affected, 0, "server executed client-only scavenge command")
T.equal(reason, "client_action_required",
    "client-only scavenge rejection reason")
affected, reason = PNC.CompanionCommands.Execute(player, {
    commandID = "follow",
    scope = "group",
})
T.equal(affected, 2, "group movement command target count")
T.equal(records.owned.orderSpec.kind, "follow",
    "group follow did not update closest companion")
T.equal(records.owned_second.orderSpec.kind, "follow",
    "group follow did not update second companion")
records.owned.runtime.workOrderId = "work-1"
affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "owned",
    commandID = "return_home",
})
T.equal(affected, 1, "single go-home command target count")
T.equal(sentHome[#sentHome].id, "owned", "single go-home target")
T.equal(sentHome[#sentHome].reason, "companion_command",
    "single go-home source")
T.equal(releasedWorkers[#releasedWorkers].id, "owned",
    "go-home command released active work")
affected, reason = PNC.CompanionCommands.Execute(player, {
    commandID = "return_home",
    scope = "group",
})
T.equal(affected, 2, "all-nearby go-home target count")
T.equal(reason, "commanded", "all-nearby go-home result")
records.owned.runtime.attackAction = { finishAt = 9999 }
affected, reason = PNC.CompanionCommands.Execute(player, {
    id = "owned",
    commandID = "attack_none",
})
T.equal(affected, 1, "don't attack command")
T.equal(records.owned.attackType, "none", "don't attack preference")
T.equal(records.owned.orderSpec.kind, "follow",
    "don't attack preserved movement order")
T.equal(records.owned.runtime.attackAction, nil,
    "don't attack cancelled committed attack")
T.equal(PNC.CompanionCommands.IsCurrent(records.owned, "attack_none"),
    true, "current attack type")
T.truthy(#broadcasts >= 2, "companion changes were not broadcast")

local spoken = {}
player.Say = function(_, text)
    spoken[#spoken + 1] = text
end
player.playEmote = function() end
PNC.CompanionCommandPresentation = nil
T.load(T.path("ProjectHoomans", "client", "PNC/Knowledge/PNC_NPCIdentityPresentation.lua"))
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
T.load(CLIENT_ROOT .. "Commands/PNC_CompanionCommandPresentation.lua")
for i = 1, 8 do
    PNC.CompanionCommandPresentation.ShowPlayerFlavor(
        player,
        "follow",
        { target = { name = "Walker Sage" } }
    )
end
local spokenVariants = {}
for i = 1, #spoken do
    T.truthy(string.find(spoken[i], "Walker Sage", 1, true),
        "presented player flavor omitted target name")
    spokenVariants[spoken[i]] = true
end
local spokenVariantCount = 0
for _ in pairs(spokenVariants) do
    spokenVariantCount = spokenVariantCount + 1
end
T.truthy(spokenVariantCount >= 2,
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

T.load(CLIENT_ROOT
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
T.load(CLIENT_ROOT .. "UI/Context/PNC_NPCSelection.lua")
local selectedEntries = PNC.NPCSelection.CollectNearbyNPCs(
    player,
    { { getSquare = function() return selectedSquare end } },
    3
)
T.equal(#selectedEntries, 1, "multiplayer snapshot NPC selection")
T.equal(selectedEntries[1].snapshot, ownedSnapshot,
    "live body selection discarded authoritative client snapshot")

T.equal(registeredProvider.isEnabled(
    selectedEntries[1],
    player
), true, "owned companion context provider")
T.equal(registeredProvider.isEnabled(
    { id = "neutral", snapshot = records.neutral },
    player
), false, "neutral context provider hidden")

local context = newMenu()
registeredProvider.addOptions(
    context,
    selectedEntries[1],
    player
)
T.equal(context.options[1].name, "Companion Commands",
    "context command root")
T.equal(#context.options[1].submenu.options, 5,
    "movement commands and nested attack root")
T.equal(context.options[1].submenu.options[3].name, "Go Home",
    "context go-home command")
T.equal(context.options[1].submenu.options[4].name, "Scavenge Nearby",
    "context scavenge command")
T.equal(context.options[1].submenu.options[5].name, "Attack Type",
    "nested attack type root")
local attackOptions = context.options[1].submenu.options[5].submenu.options
T.equal(#attackOptions, 4, "attack type definitions")
T.equal(attackOptions[4].notAvailable, true,
    "current attack type is disabled and red")
T.equal(
    context.options[1].submenu.options[5].iconTexture,
    "media/ui/emotes/no.png",
    "context attack type icon did not reflect current setting"
)
attackOptions[3].callback()
T.equal(sent[1].commandID, "attack_ranged",
    "context command dispatch")
T.equal(sent[1].npcId, "client_owned",
    "context targeted companion")
T.equal(played[1].commandID, "attack_ranged",
    "context command visual emote")
T.equal(played[1].target.id, "client_owned",
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

T.load(CLIENT_ROOT .. "Commands/PNC_CompanionCommandEmotes.lua")

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
T.equal(foundRosterCandidate, true,
    "roster snapshot without owner detail hid closest commands")
PNC.Network.ClientState.snapshots.roster_owned = nil

local radial = {}
setmetatable(radial, { __index = ISEmoteRadialMenu })
radial:init()
T.equal(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands.name,
    "Closest Companion: Walker Sage",
    "closest radial command root"
)
T.equal(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands
        .subMenu.PNC_ClosestCommand_follow,
    "Follow Me",
    "closest radial follow slice"
)
T.equal(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands
        .subMenu.PNC_ClosestCommand_return_home,
    "Go Home",
    "closest radial go-home slice"
)
T.equal(
    ISEmoteRadialMenu.menu.PNC_GroupCompanionCommands
        .subMenu.PNC_GroupCommand_return_home,
    "Go Home",
    "all-nearby radial go-home slice"
)
T.equal(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands
        .subMenu.PNC_ClosestCommandGroup_attack_type,
    "Attack Type",
    "radial nested attack type slice"
)
T.equal(
    ISEmoteRadialMenu.menu.PNC_GroupCompanionCommands
        .subMenu.PNC_GroupCommand_attack_auto,
    nil,
    "attack type leaked into group wheel"
)
T.equal(
    ISEmoteRadialMenu.menu.PNC_ClosestCommandGroup_attack_type,
    nil,
    "private attack subgroup leaked into vanilla radial roots"
)
T.equal(
    radial.PNCCommandNestedMenus.PNC_ClosestCommandGroup_attack_type
        .subMenu.PNC_ClosestCommand_attack_none,
    "Don't Attack",
    "radial nested don't attack slice"
)
T.equal(
    ISEmoteRadialMenu.icons.PNC_GroupCompanionCommands,
    "media/ui/Emotes/PNC_EmoteMenu.png",
    "framework group radial icon"
)
T.equal(
    ISEmoteRadialMenu.icons.PNC_ClosestCompanionCommands,
    "media/ui/emotes/no.png",
    "closest root icon did not reflect target attack type"
)
T.equal(
    ISEmoteRadialMenu.icons.PNC_ClosestCommandGroup_attack_type,
    "media/ui/emotes/no.png",
    "attack subgroup icon did not reflect target attack type"
)
T.equal(
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
T.equal(foundAttackTypeSlice, true,
    "vanilla closest submenu omitted attack type slice")
radial:emote("PNC_ClosestCommandGroup_attack_type")
T.equal(#radialSlices, 5,
    "nested radial attack commands plus back")
T.equal(radialSlices[1].value, "PNC_ClosestCommand_attack_auto",
    "nested radial stable auto order")
T.equal(radialSlices[4].value, "PNC_ClosestCommand_attack_none",
    "nested radial stable don't-attack order")
T.equal(radialSlices[5].value, "PNC_ClosestCompanionCommands",
    "nested radial back target")
T.equal(displayed, 1, "nested radial displayed")
radial:emote("PNC_ClosestCommand_attack_ranged")
T.equal(radialSent[1].commandID, "attack_ranged",
    "closest radial command dispatch")
T.equal(radialSent[1].npcId, "client_owned",
    "closest radial target")
T.equal(radialSent[1].scope, "closest",
    "closest radial scope")
T.equal(radialFlavor.context.targets[1].name, "Walker Sage",
    "closest radial flavor target name")
radial:emote("PNC_GroupCommand_follow")
T.equal(radialSent[2].commandID, "follow",
    "group radial command dispatch")
T.equal(radialSent[2].npcId, nil, "group radial target should be nil")
T.equal(radialSent[2].scope, "group", "group radial scope")
T.truthy(#radialFlavor.context.targets >= 1,
    "group radial flavor omitted nearby companions")
T.equal(originalVisual, "followme", "radial visual emote")
radial:emote("PNC_GroupCommand_return_home")
T.equal(radialSent[3].commandID, "return_home",
    "group radial go-home dispatch")
T.equal(radialSent[3].npcId, nil,
    "group radial go-home target should be nil")
T.equal(radialSent[3].scope, "group",
    "group radial go-home scope")
radial:emote("wavehi")
T.equal(originalVisual, "wavehi", "ordinary emote delegation")

local savedForEach = PNC.Registry.ForEach
local savedSnapshots = PNC.Network.ClientState.snapshots
PNC.Registry.ForEach = function() end
PNC.Network.ClientState.snapshots = {}
local syncingRadial = {}
setmetatable(syncingRadial, { __index = ISEmoteRadialMenu })
syncingRadial:init()
T.equal(
    ISEmoteRadialMenu.menu.PNC_ClosestCompanionCommands
        .subMenu.PNC_ClosestCommandGroup_attack_type,
    "Attack Type",
    "sync gap hid personalized attack type"
)
syncingRadial:emote("PNC_ClosestCommand_attack_auto")
T.equal(radialSent[#radialSent].scope, "closest",
    "sync-gap closest command scope")
T.equal(radialSent[#radialSent].npcId, nil,
    "sync-gap closest command trusted a stale target")
PNC.Registry.ForEach = savedForEach
PNC.Network.ClientState.snapshots = savedSnapshots
T.finish("pnc_companion_commands_smoke")

T.finish("pnc_companion_commands_smoke")
