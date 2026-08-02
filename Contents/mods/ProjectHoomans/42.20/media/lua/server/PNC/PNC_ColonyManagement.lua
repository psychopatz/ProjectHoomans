-- Read-only player colony presentation; canonical Need state remains on NPC records.
if isClient and isClient() and (not isServer or not isServer()) then return end
PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
local Management, Definitions = PNC.ColonyManagement, PNC.NeedsDefinitions

local function owned(record, player)
    return PNC.CompanionCommands and PNC.CompanionCommands.IsOwnedByPlayer
        and PNC.CompanionCommands.IsOwnedByPlayer(record, player)
end
local function summary(record)
    local needs = PNC.IndividualNeeds.Ensure(record)
    local priorityType, priority = PNC.IndividualNeeds.GetHighestPriority(record)
    return { id=record.id, name=tostring(record.name or record.id),
        role=record.affiliation and record.affiliation.communityRole or record.affiliation and record.affiliation.role or "companion",
        activity=PNC.IndividualNeeds.GetActivity(record), job=record.activeJob,
        health=record.health and record.health.state or "unknown", needs=needs,
        priorityType=priorityType, priority=priority,
        location={x=record.x,y=record.y,z=record.z} }
end
function Management.BuildSnapshot(player)
    local people, attention, counts = {}, {}, { hunger={}, hydration={}, fatigue={} }
    local playerFaction, colony
    if PNC.Factions and PNC.Factions.GetPlayerFaction then playerFaction = PNC.Factions.GetPlayerFaction(player) end
    if playerFaction and PNC.Communities and PNC.Communities.GetForFaction then
        for _, value in ipairs(PNC.Communities.GetForFaction(playerFaction.id) or {}) do if value.status == "active" then colony=value; break end end
    end
    for _, record in pairs(PNC.Registry.Data or {}) do
        if record.alive ~= false and owned(record, player) then
            local value = summary(record); people[#people+1]=value
            for _, needType in ipairs(Definitions.TYPES) do
                local level=Definitions.GetLevel(value.needs[needType]); counts[needType][level]=(counts[needType][level] or 0)+1
                if level == "EMERGENCY" or level == "CRITICAL" or level == "LOW" then attention[#attention+1]={ severity=level, npcID=value.id, name=value.name, needType=needType, value=value.needs[needType] } end
            end
        end
    end
    table.sort(people,function(a,b) return a.name<b.name end)
    table.sort(attention,function(a,b) return a.value<b.value end)
    return { colony=colony, people=people, attention=attention, levels=counts,
        generatedAt=PNC.NeedsUtils.WorldAgeHours() }
end

function Management.RenameForPlayer(player, args)
    args = type(args) == "table" and args or {}
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    local communityID = tostring(args.communityID or "")
    local allowed = false
    if faction and PNC.Communities and PNC.Communities.GetForFaction then
        for _, community in ipairs(PNC.Communities.GetForFaction(faction.id) or {}) do
            if community.id == communityID and community.status == "active" then
                allowed = true
                break
            end
        end
    end
    if not allowed then
        return Management.BuildSnapshot(player), {
            ok = false, reason = "community_not_owned",
        }
    end
    local ok, reason = PNC.Communities.SetName(
        communityID,
        args.name
    )
    if ok == true and PNC.Communities.Save then
        PNC.Communities.Save()
        if GlobalModData and GlobalModData.save then
            GlobalModData.save()
        end
    end
    return Management.BuildSnapshot(player), {
        ok = ok == true,
        reason = reason,
        communityID = communityID,
    }
end
return Management
