local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Config = { Relationships = {} },
    Core = {
        IsAuthority = function() return true end,
        LogInfo = function() end,
    },
    Const = {},
    FactionConstants = {
        NAME_MAX_LENGTH = 96,
        MOBILE_PATH_RANDOM = "random",
        MOBILE_CONTROL_AMBIENT = "ambient",
        MOBILE_ACTIVITY_STREET_ROAMING = "street_roaming",
        MOBILE_AMBIENT_DAY = "day",
        MOBILE_AMBIENT_ROAD = "road",
    },
    EntityRef = {
        IsPlayer = function(value)
            return string.sub(tostring(value or ""), 1, 7) == "player:"
        end,
    },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Relationships/PNC_ColonistDeparturePolicy.lua"
)

local source = {
    id = "faction_player",
    ownerPlayerKey = "player:one:character",
    memberIDs = { npc_manual = true },
}
local destination
local record = {
    id = "npc_manual",
    name = "Dudley",
    alive = true,
    recruited = true,
    ownerUsername = "one",
    ownerOnlineID = 1,
    tacticalClass = "colonist",
    x = 100,
    y = 100,
    z = 0,
    affiliation = { factionID = source.id },
}
local nextID = 0
local imported = 0
local broadcasted = 0
local dirty = 0

PNC.Registry = {
    Data = { [record.id] = record },
    MarkDirty = function() dirty = dirty + 1 end,
    GetLiveZombie = function() return nil end,
}
PNC.Communities = {
    BuildSiteID = function() return "community_site_departure" end,
}
PNC.Factions = {
    Get = function(id)
        if id == source.id then return source end
        if destination and id == destination.id then return destination end
        return nil
    end,
    IsMobileGroup = function(value)
        return value and value.mobile and value.mobile.active == true
    end,
    Create = function(spec)
        nextID = nextID + 1
        destination = {
            id = "faction_departed_" .. tostring(nextID),
            status = "active",
            archetypeID = spec.archetypeID,
            tags = spec.tags,
            memberIDs = {},
            leaderNPCID = nil,
        }
        return true, "created", destination
    end,
    TransferNPC = function(npcID, destinationID, options)
        T.equal(npcID, record.id, "conversion transfers the requested NPC")
        T.equal(options.leaveReason, "colonist_expelled",
            "manual conversion records the dedicated faction leave reason")
        source.memberIDs[npcID] = nil
        destination.memberIDs[npcID] = true
        record.affiliation = { factionID = destinationID }
        return true, "transferred"
    end,
    SetLeader = function(factionID, npcID)
        T.equal(factionID, destination.id,
            "converted NPC becomes the mobile faction leader")
        destination.leaderNPCID = npcID
        return true, "leader_set"
    end,
    SetMobileGroup = function(factionID, state)
        destination.mobile = state
        return true, "mobile_group_updated", state
    end,
    UpdateMobileGroup = function(factionID, patch)
        for key, value in pairs(patch) do destination.mobile[key] = value end
        return true, "mobile_group_updated", destination.mobile
    end,
}
PNC.Relationships = {
    Get = function()
        return { approval = 0, respect = 0 }
    end,
    ApplyConversationEffect = function()
        return true, "applied", {
            relationship = { approval = -50, respect = -50 },
        }
    end,
}
PNC.RelationshipGraph = {
    ResolveNPCPersonality = function() return {} end,
}
PNC.AbstractGroups = {
    ImportMobileFaction = function()
        imported = imported + 1
        return { id = "agroup_departed" }, "created"
    end,
}
PNC.Network = {
    BroadcastRecord = function() broadcasted = broadcasted + 1 end,
}

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Colonists/PNC_ColonistDepartureService.lua"
)
local Service = PNC.ColonistDeparture
local ok, reason, result = Service.Depart(record, "manual", {
    ownerKey = source.ownerPlayerKey,
    worldAgeHours = 12,
})
T.truthy(ok, reason)
T.equal(reason, "colonist_departed", "manual conversion completes")
T.falsy(record.recruited, "departed NPC is no longer recruited")
T.equal(record.ownerUsername, nil, "departure clears username ownership")
T.equal(record.ownerOnlineID, nil, "departure clears online ownership")
T.equal(record.tacticalClass, "neutral",
    "departure returns the NPC to neutral tactical behavior")
T.equal(source.memberIDs[record.id], nil,
    "departed NPC is removed from the player faction")
T.equal(destination.memberIDs[record.id], true,
    "departed NPC belongs to exactly the new mobile faction")
T.equal(destination.leaderNPCID, record.id,
    "departed NPC leads the mobile refugee faction")
T.truthy(destination.mobile and destination.mobile.active,
    "departure creates mobile state")
T.equal(imported, 1, "departure imports the mobile faction into abstract groups")
T.equal(broadcasted, 1, "departure broadcasts the ownership transition")
T.truthy(result.penalty and result.penalty.delta,
    "manual departure returns the reputation penalty audit")
T.truthy(record.colonistDeparture
    and record.colonistDeparture.state == "completed",
    "departure persists a compact completion marker")
T.truthy(dirty > 0, "conversion marks both faction and NPC state dirty")

print("pnc_colonist_departure_conversion_smoke: ok")
