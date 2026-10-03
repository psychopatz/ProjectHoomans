if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Public camp directory lifecycle and bounded retention.
local Service = PNC.CampZoneService
local Internal = Service.Internal
local number = Internal.number
local text = Internal.text
local copySite = Internal.copySite
local zoneID = Internal.zoneID
local discoverZones = Internal.discoverZones
local enrichZones = Internal.enrichZones
local needProfile = Internal.needProfile
local sortRecords = Internal.sortRecords
local bestZone = Internal.bestZone

local function nextRuntimeSequence()
    local sequence = tonumber(Service.Runtime.sequence) or 0
    if sequence >= 2147483646 then
        sequence = 1
    else
        sequence = sequence + 1
    end
    Service.Runtime.sequence = sequence
    return sequence
end

local function pruneRuntime(currentID)
    local camps = Service.Runtime.camps
    local maximum = math.max(1, math.floor(number(
        Service.MAX_RETAINED_CAMPS, 32)))
    local count = 0
    local oldestID
    local oldestUse
    local oldestKey
    local key
    local directory
    local use
    for key, directory in pairs(camps) do
        if type(directory) == "table" then
            count = count + 1
        else
            camps[key] = nil
        end
    end
    while count > maximum do
        oldestID = nil
        oldestUse = nil
        oldestKey = nil
        for key, directory in pairs(camps) do
            if tostring(key) ~= tostring(currentID)
                and type(directory) == "table"
            then
                use = tonumber(directory.lastUsed) or 0
                if not oldestID or use < oldestUse
                    or use == oldestUse
                        and tostring(key) < tostring(oldestKey)
                then
                    oldestID = key
                    oldestUse = use
                    oldestKey = key
                end
            end
        end
        if not oldestID then break end
        camps[oldestID] = nil
        count = count - 1
    end
end

local function retainRuntime(campID, directory)
    directory.lastUsed = nextRuntimeSequence()
    Service.Runtime.camps[campID] = directory
    pruneRuntime(campID)
end

function Service.BuildGroup(rootSite, records, options)
    local directory
    local roomsByID
    local cell
    local rootRoom
    local root
    local occupancy = {}
    local assignments
    local profiles = {}
    local previous
    local campID
    local revision
    local orderedRecords = {}
    options = type(options) == "table" and options or {}
    if type(rootSite) ~= "table" or type(records) ~= "table"
        or #records == 0
    then
        return nil, "camp_zone_input_invalid"
    end
    root = copySite(rootSite)
    root.siteID = zoneID(root)
    campID = tostring(options.campId or "camp")
    previous = Service.Runtime.camps[campID]
    revision = (tonumber(previous and previous.revision) or 0) + 1
    directory, roomsByID, cell, rootRoom = discoverZones(
        root, options)
    directory.version = Service.VERSION
    directory.campId = campID
    directory.revision = revision
    directory.createdAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    directory.source = "server_loaded_rooms"
    directory.rootSite = copySite(root)
    enrichZones(directory, roomsByID, cell, rootRoom, records[1])
    assignments = directory.assignments
    for index = 1, #records do
        orderedRecords[index] = records[index]
        profiles[tostring(records[index].id or "")] =
            needProfile(records[index])
    end
    sortRecords(orderedRecords, profiles)
    for index = 1, #orderedRecords do
        local record = orderedRecords[index]
        local profile = profiles[tostring(record.id or "")]
        local zone
        local score
        local hasMatch
        local id = tostring(record.id or "")
        zone, score, hasMatch = bestZone(
            profile, directory, occupancy, root)
        if zone and id ~= "" then
            local zoneKey = tostring(zone.siteID or "")
            occupancy[zoneKey] = (tonumber(occupancy[zoneKey]) or 0) + 1
            zone.occupancy = occupancy[zoneKey]
            assignments[id] = {
                npcID = id,
                zoneID = zoneKey,
                zoneLabel = text(zone.label, "room", 64),
                zone = copySite(zone),
                needKind = profile.kind,
                needValue = profile.value,
                urgency = profile.urgency,
                critical = profile.critical,
                reason = hasMatch and profile.reason
                    or "fallback_no_" .. tostring(profile.kind) .. "_zone",
                score = score,
                assignmentRevision = revision,
            }
        elseif id ~= "" then
            directory.rejected[id] = "no_loaded_zone"
        end
    end
    directory.zoneCount = #directory.zones
    directory.targetCount = #records
    -- Remove the temporary dedupe table before exposing the directory to any
    -- debug projection or future caller.
    retainRuntime(campID, directory)
    return directory
end

function Service.Get(campID)
    local directory = Service.Runtime.camps[tostring(campID or "")]
    if directory then directory.lastUsed = nextRuntimeSequence() end
    return directory
end

function Service.GetAssignment(campID, npcID)
    local directory = Service.Get(campID)
    return directory and directory.assignments
        and directory.assignments[tostring(npcID or "")] or nil
end

function Service.Release(campID)
    Service.Runtime.camps[tostring(campID or "")] = nil
    return true
end


return Service
