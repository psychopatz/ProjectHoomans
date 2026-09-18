-- Catalog filtering, capability metadata, and approval projections.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local Capabilities = Internal.Capabilities
local PlayerCatalog = Internal.PlayerCatalog or {}
local NPCCatalog = Internal.NPCCatalog or {}
local lower = Internal.lower
local entryID = Internal.entryID
local searchText = Internal.searchText
local bumpType = Internal.bumpType
local directNPCEntry = Internal.directNPCEntry
local State = Internal.State or Model.State

function Model.GetPlayerCatalogEntries()
    local query = lower(State.playerQuery)
    local source = State.playerSource
    local result = {}
    for _, entry in ipairs(PlayerCatalog.entries or {}) do
        local inSource = source == "bridge"
            and entry.source == "zombie"
            and (entry.route == "player_bridge"
                or entry.route == "player_emote_bridge")
            or source == "player" and entry.source ~= "zombie"
        if inSource
            and entry.playable == true
            and (entry.mode == "action" or entry.mode == "emote")
            and (
                (entry.mode == "action" and entry.action
                    and entry.action ~= "")
                or (entry.mode == "emote" and entry.emote
                    and entry.emote ~= "")
            )
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
            entry.puppetOperaCapability = Capabilities.DescribeEntry(
                "player",
                entry
            )
            result[#result + 1] = entry
        end
    end
    return result
end

function Model.GetNPCStates()
    local result = {}
    local seen = {}
    for state in pairs(NPCCatalog.stateCounts or {}) do
        result[#result + 1] = state
        seen[state] = true
    end
    table.sort(result)
    if not seen.bumped then table.insert(result, 1, "bumped") end
    return result
end

function Model.GetNPCCatalogEntries()
    local query = lower(State.npcQuery)
    local state = State.npcState
    local result = {}
    for _, entry in ipairs(NPCCatalog.entries or {}) do
        local bump = bumpType(entry)
        if entry.playable == true
            and (not state or state == "all" or entry.state == state)
            and (query == "" or string.find(searchText(entry), query, 1, true))
        then
            entry.puppetOperaBump = bump
            entry.puppetOperaDirect = directNPCEntry(entry)
            entry.puppetOperaCapability = Capabilities.DescribeEntry(
                "npc",
                entry,
                bump
            )
            result[#result + 1] = entry
        end
    end
    return result
end

function Model.PlayerEntryID(entry)
    return entryID("player", entry)
end

function Model.NPCEntryID(entry)
    return entryID("npc", entry)
end

function Model.EntryBumpType(entry)
    return bumpType(entry)
end

function Model.IsPlayerEntryServerApproved(entry)
    if not entry then return false end
    local approved = Capabilities.IsSceneApproved("local_player", {
        mode = entry.mode,
        action = entry.action,
        emote = entry.emote,
    })
    return approved == true
end

function Model.IsNPCEntryServerApproved(entry)
    local bump = bumpType(entry)
    if not entry or not bump or not directNPCEntry(entry) then return false end
    local approved = Capabilities.IsSceneApproved("nearby_live_npc", {
        bump = bump,
        nonCombat = true,
    })
    return approved == true
end

return Model
