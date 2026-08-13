local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "assert") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local communitySaves = 0
local factionSaves = 0
local faction = {
    id = "faction_player",
    name = "Rivera Enclave",
    ownerPlayerKey = "player:Tester",
    revision = 2,
    tags = { factionNamePending = true },
}
local community = {
    id = "community_player",
    factionID = "faction_player",
    name = "New Colony",
    renamePending = true,
    status = "active",
    revision = 1,
}
local companion = {
    id = "npc_alex",
    name = "Alex Rivera",
    alive = true,
    recruited = true,
    ownerUsername = "Tester",
    affiliation = { factionID = "faction_player", communityRole = "resident" },
    health = { state = "normal" },
    needs = { hunger = 0.82, hydration = 0.10, fatigue = 0.10 },
}

isDebugEnabled = function() return true end

PNC = {
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = type(item) == "table"
                    and PNC.Core.DeepCopy(item) or item
            end
            return output
        end,
    },
    NeedsDefinitions = {
        TYPES = { "hunger", "hydration", "fatigue" },
        Get = function(needType)
            if needType == "hunger" or needType == "hydration"
                or needType == "fatigue"
            then return { id = needType } end
        end,
        GetLevel = function(_, value)
            if value >= 0.70 then return "EMERGENCY" end
            if value >= 0.45 then return "CRITICAL" end
            if value >= 0.25 then return "LOW" end
            if value >= 0.15 then return "STABLE" end
            return "GOOD"
        end,
    },
    IndividualNeeds = {
        Ensure = function(record) return record.needs end,
        GetHighestPriority = function() return "hunger", 82 end,
        GetActivity = function() return "Following" end,
        Modify = function(record, needType, amount)
            record.needs[needType] = math.max(0,
                math.min(1, record.needs[needType] + amount))
            return record.needs[needType]
        end,
        Reset = function(record)
            record.needs = { hunger = 0, hydration = 0, fatigue = 0 }
            return true
        end,
    },
    NeedsUtils = { WorldAgeHours = function() return 42 end },
    CompanionCommands = {
        IsOwnedByPlayer = function(record, player)
            return record.ownerUsername == player:getUsername()
        end,
    },
    Registry = {
        Data = { [companion.id] = companion },
        Get = function(id)
            return id == companion.id and companion or nil
        end,
        MarkDirty = function(record, reason)
            record.lastDirtyReason = reason
        end,
    },
    Journals = {
        NPC_CAPACITY = 32,
        GetNPC = function(id, limit, newestFirst)
            equal(id, companion.id, "journal request uses companion id")
            equal(limit, 32, "journal request stays bounded")
            equal(newestFirst, true, "journal request is newest first")
            return {
                { "projecthoomans.npc.needs.foodConsumed", 120,
                    "Base.Apple", 0.2 },
            }
        end,
    },
    Factions = {
        GetPlayerFaction = function() return faction end,
        SetPlayerFactionName = function(_, name)
            if name == "" then return false, "invalid_name" end
            faction.name = name
            faction.tags.factionNamePending = nil
            faction.revision = faction.revision + 1
            return true, "renamed", faction
        end,
        Save = function() factionSaves = factionSaves + 1 end,
    },
    Communities = {
        GetForFaction = function() return { community } end,
        SetName = function(id, name)
            if id ~= community.id then return false, "community_not_found" end
            community.name = name
            community.renamePending = false
            community.revision = community.revision + 1
            return true, "renamed"
        end,
        Save = function() communitySaves = communitySaves + 1 end,
    },
    SettlementRepository = {
        GetFacility = function(id)
            if id == "facility_farm" then
                return { id = id, baseId = "base_player", definitionId = "farm" }
            end
        end,
    },
    BaseService = {
        GetForColony = function() return nil end,
        Get = function(id)
            if id == "base_player" then return { id = id } end
        end,
    },
    BaseValidationService = { CanUse = function() return true end },
    FacilityService = {
        ResolveWorkTarget = function()
            return { x = 12, y = 18, z = 0, componentId = "field_a",
                role = "farm.field" }
        end,
    },
    FacilityDefinitions = {
        Get = function() return { displayNameKey = "UI_PNC_Facility_Farm" } end,
    },
    FacilityJobs = {
        StartForFacility = function(record, facilityId, options)
            record.runtime = record.runtime or {}
            record.runtime.facilityActivity = {
                facilityId = facilityId, phase = "QUEUED", debugHold = true,
            }
            record.runtime.facilityDebugWork = record.runtime.facilityActivity
            record.orderSpec = { kind = "facility_activity", capability = "farm.work" }
            return true, "facility_activity_started"
        end,
        Stop = function(record)
            record.runtime.facilityActivity = nil
            record.runtime.facilityDebugWork = nil
            return true, "facility_activity_stopped"
        end,
    },
    OrderSystem = {
        SetOrder = function(record, order)
            record.orderSpec = order or { kind = "guard", x = 0, y = 0, z = 0 }
        end,
    },
    WorkDefinitions = {
        COLONY_JOBS = { "Constructor", "Researcher", "WorkshopWorker" },
        JOB_BY_OPERATION = { CONSTRUCT = "Constructor" },
    },
    WorkRepository = { Get = function() return nil end },
}

local Management = dofile(ROOT .. "PNC_ColonyManagement.lua")
local player = { getUsername = function() return "Tester" end }
local snapshot = Management.BuildSnapshot(player)

equal(#snapshot.people, 1, "owned companion appears")
equal(snapshot.people[1].name, "Alex Rivera", "companion identity presented")
equal(#snapshot.people[1].journal, 1, "companion journal included")
equal(#snapshot.attention, 1, "critical need appears in attention")
equal(snapshot.attention[1].needType, "hunger", "critical need type")
equal(snapshot.faction.name, "Rivera Enclave", "faction is in snapshot")
equal(snapshot.faction.renamePending, true, "initial faction prompt is pending")
equal(snapshot.people[1].allowedJobs.Constructor, true,
    "every NPC may construct by default")
equal(snapshot.people[1].allowedJobs.Researcher, true,
    "missing legacy permissions render as allowed")

local factionSnapshot, factionResult = Management.HandleAction(player, {
    action = "faction_rename", name = "River Wardens",
})
equal(factionResult.ok, true, "owned faction rename succeeds")
equal(factionSnapshot.faction.name, "River Wardens",
    "faction rename returns updated snapshot")
equal(factionSnapshot.faction.renamePending, false,
    "faction prompt clears after rename")
equal(factionSaves, 1, "faction rename commits immediately")

local jobsSnapshot, jobsResult = Management.HandleAction(player, {
    action = "job_permission_set", npcID = companion.id,
    job = "Constructor", enabled = false,
})
equal(jobsResult.ok, true, "constructor permission can be disabled")
equal(jobsSnapshot.people[1].allowedJobs.Constructor, false,
    "explicit opt-out returns in the colony snapshot")
jobsSnapshot, jobsResult = Management.HandleAction(player, {
    action = "job_permission_set", npcID = companion.id,
    job = "Constructor", enabled = true,
})
equal(jobsResult.ok, true, "constructor permission can be restored")
equal(jobsSnapshot.people[1].allowedJobs.Constructor, true,
    "restored permission returns in the colony snapshot")
equal(companion.lastDirtyReason, "allowed_jobs",
    "job permission persists through registry dirtiness")

local renamed, result = Management.RenameForPlayer(player, {
    communityID = community.id,
    name = "Riverside Watch",
})
equal(result.ok, true, "owned colony rename succeeds")
equal(renamed.colony.name, "Riverside Watch", "renamed snapshot returned")
equal(renamed.colony.renamePending, false, "name prompt is cleared")
equal(communitySaves, 1, "rename commits community state immediately")

local debugSnapshot, debugResult = Management.HandleAction(player, {
    action = "debug_need", npcID = companion.id, operation = "modify",
    needType = "hydration", amount = 0.25,
})
equal(debugResult.ok, true, "debug need mutation succeeds")
equal(debugSnapshot.people[1].needs.hydration, 0.35,
    "debug tab action returns the authoritative updated need")

local workSnapshot, workResult = Management.HandleAction(player, {
    action = "debug_facility_work", npcID = companion.id,
    facilityId = "facility_farm", operation = "start",
})
equal(workResult.ok, true, "debug facility work starts")
equal(companion.orderSpec.kind, "facility_activity",
    "debug facility work installs production order")
equal(workSnapshot.people[1].facilityDebugWork.phase, "QUEUED",
    "facility work state is visible in management snapshot")

local _, stopResult = Management.HandleAction(player, {
    action = "debug_facility_work", npcID = companion.id, operation = "stop",
})
equal(stopResult.ok, true, "debug facility work stops")
equal(companion.runtime.facilityDebugWork, nil, "debug work state cleared")

print("pnc_colony_management_smoke: ok")
