local T = require "tests/support/test"

local SERVER =
    T.path("ProjectHoomans", "server", "PNC/")

local at = 20
local now = 1000
local sent = {}
local pacification
local war
local relationshipEvents = {}
local playerKey = "player:Patrick:char_toll"

function isClient() return false end
function isServer() return true end
function getGameTime()
    return {
        getWorldAgeHours = function() return at end,
    }
end

local inventory = { items = {} }
for index = 1, 15 do
    inventory.items[index] = {
        type = "Base.Money",
        getContainer = function() return inventory end,
    }
end
function inventory:getItemsFromType(fullType)
    local matches = {}
    for _, item in ipairs(self.items) do
        if item.type == fullType then
            matches[#matches + 1] = item
        end
    end
    return {
        size = function() return #matches end,
        get = function(_, index)
            return matches[index + 1]
        end,
    }
end
function inventory:Remove(target)
    for index, item in ipairs(self.items) do
        if item == target then
            table.remove(self.items, index)
            return
        end
    end
end
function inventory:AddItem(fullType)
    self.items[#self.items + 1] = {
        type = fullType,
        getContainer = function() return inventory end,
    }
end

local player = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getInventory = function() return inventory end,
}

PNC = {
    Core = {
        Now = function() return now end,
        ForEachPlayer = function(callback)
            callback(player)
        end,
    },
    Const = {
        MODULE = "PNC",
        CMD_FACTION_TOLL = "FactionToll",
    },
    EntityRef = {},
    PlayerCharacters = {
        GetEntityKey = function()
            return playerKey, "resolved"
        end,
    },
    Network = {
        Internal = {
            SendToPlayer = function(_, command, payload)
                sent[#sent + 1] = {
                    command = command,
                    payload = payload,
                }
                return true
            end,
        },
    },
    CommunityMath = {
        IsInsideHomeArea = function()
            return true
        end,
    },
    Registry = {
        Get = function(id)
            if id == "npc_toll_leader" then
                return {
                    id = id,
                    alive = true,
                }
            end
            return nil
        end,
    },
    Relationships = {
        ApplyEventMutation = function(
            observerNPCID,
            targetKey,
            mutation
        )
            relationshipEvents[#relationshipEvents + 1] = {
                observerNPCID = observerNPCID,
                targetKey = targetKey,
                mutation = mutation,
            }
            return true
        end,
    },
    Communities = {
        List = function()
            return {
                {
                    id = "community_toll",
                    factionID = "faction_toll",
                    name = "Bridge Camp",
                    status = "active",
                    currentPopulation = 2,
                },
                {
                    id = "community_roaming",
                    factionID = "faction_roaming",
                    name = "Not Territorial",
                    status = "active",
                    currentPopulation = 20,
                },
            }
        end,
    },
    Factions = {
        Registry = {
            byID = {
                faction_toll = {
                    id = "faction_toll",
                    name = "Bridge Crew",
                    archetypeID = "looter",
                    status = "active",
                    tags = { territorialToll = true },
                    leaderNPCID = "npc_toll_leader",
                    memberIDs = {
                        npc_toll_leader = true,
                    },
                },
                faction_roaming = {
                    id = "faction_roaming",
                    name = "Road Wolves",
                    archetypeID = "looter",
                    status = "active",
                    tags = {},
                },
            },
        },
        IsTerritorialTollFaction = function(faction)
            return faction
                and faction.tags
                and faction.tags.territorialToll == true
        end,
        GetDiplomacyFactionForPlayerKey = function()
            return { id = "faction_player" }
        end,
        GetPlayerPacification = function()
            return nil
        end,
        AreAtWar = function() return false end,
        AreAllied = function() return false end,
        PacifyForPlayer = function(factionID, key, spec)
            pacification = {
                factionID = factionID,
                key = key,
                spec = spec,
            }
            return true
        end,
        DeclareWar = function(firstID, secondID, spec)
            war = {
                firstID = firstID,
                secondID = secondID,
                spec = spec,
            }
            return true
        end,
    },
}

T.load(SERVER .. "Factions/PNC_FactionTollService.lua")

T.equal(PNC.FactionTolls.Pump(now), 1,
    "entry creates one territorial demand")
T.equal(#sent, 1, "one demand sent")
T.equal(sent[1].payload.kind, "demand",
    "demand payload kind")
T.equal(sent[1].payload.amount, 12,
    "population-scaled toll")
local demandID = sent[1].payload.demandID
T.equal(PNC.FactionTolls.HandleResponse(player, {
    demandID = demandID,
    response = "pay",
}), true, "server accepts payment")
T.equal(#inventory.items, 3, "cash removed on server")
T.equal(pacification.factionID, "faction_toll",
    "payment pacifies demanding faction")
T.equal(pacification.key, playerKey,
    "pacification is character-specific")
T.equal(pacification.spec.durationHours, 24,
    "payment grants one day")
T.equal(
    relationshipEvents[#relationshipEvents]
        .mutation.memory.type,
    "extortion_complied",
    "payment reports directed relationship memory"
)

PNC.FactionTolls.PendingByPlayerKey[playerKey] = {
    id = "leave_grace",
    playerKey = playerKey,
    factionID = "faction_toll",
    factionName = "Bridge Crew",
    communityID = "community_toll",
    communityName = "Bridge Camp",
    amount = 12,
    createdAt = at,
    expiresAt = at + 1,
}
T.equal(PNC.FactionTolls.HandleResponse(player, {
    demandID = "leave_grace",
    response = "leave",
}), true, "leave response starts grace period")
at = at + 0.03
now = now + 2000
PNC.FactionTolls.Pump(now)
T.equal(war.firstID, "faction_toll",
    "remaining inside after grace starts war")
war = nil

PNC.FactionTolls.PendingByPlayerKey[playerKey] = {
    id = "refusal",
    playerKey = playerKey,
    factionID = "faction_toll",
    factionName = "Bridge Crew",
    communityID = "community_toll",
    communityName = "Bridge Camp",
    amount = 12,
    createdAt = at,
    expiresAt = at + 1,
}
T.equal(PNC.FactionTolls.HandleResponse(player, {
    demandID = "refusal",
    response = "refuse",
}), true, "server accepts refusal")
T.equal(war.firstID, "faction_toll",
    "looter faction starts refusal war")
T.equal(war.secondID, "faction_player",
    "war targets player's diplomacy faction")
T.equal(
    relationshipEvents[#relationshipEvents]
        .mutation.memory.type,
    "defied_extortion",
    "refusal reports directed relationship memory"
)
T.finish("pnc_faction_toll_smoke")

T.finish("pnc_faction_toll_smoke")
