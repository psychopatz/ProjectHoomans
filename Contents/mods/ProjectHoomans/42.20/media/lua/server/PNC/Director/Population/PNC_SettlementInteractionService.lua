-- Handles grounded hostile settlement raids (Looters, hostile/desperate Refugees)
-- and O(1) AI-settlement <-> Trader barter upon arrival, delegating math to
-- PsychopatzCore.SurvivorWorld.SettlementOps and Diplomacy.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementInteractionService = PNC.SettlementInteractionService or {}

local Service = PNC.SettlementInteractionService
local Diplomacy = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiplomacy"
local SettlementOps = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldSettlementOps"
local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local WorldEvents = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function resolveCommunity(target)
    if type(target) ~= "table" then return nil end
    local cid = target.communityId or target.communityID
    if not cid and type(target.sourceSite) == "table" then
        cid = target.sourceSite.occupantCommunityID
    end
    if cid and PNC.Communities and type(PNC.Communities.Get) == "function" then
        return PNC.Communities.Get(cid)
    end
    return nil
end

local function relationBetween(factionA, factionB)
    if not factionA or not factionB then return 0 end
    if tostring(factionA) == tostring(factionB) then return 100 end
    if PNC.Factions and type(PNC.Factions.GetRelation) == "function" then
        local ok, rel = pcall(PNC.Factions.GetRelation, factionA, factionB)
        if ok and tonumber(rel) then return tonumber(rel) end
    end
    return 0
end

local function participantPower(memberIds, fallbackCount)
    if type(memberIds) == "table" and #memberIds > 0
        and PNC.AbstractCombatProfile
        and type(PNC.AbstractCombatProfile.BuildForParticipants) == "function"
    then
        local ok, profile = pcall(PNC.AbstractCombatProfile.BuildForParticipants, memberIds)
        if ok and type(profile) == "table" and tonumber(profile.power) and profile.power > 0 then
            return profile.power
        end
    end
    return math.max(1, finite(fallbackCount, 3)) * 12.0
end

local function syncHubDemand(community)
    if not community or not CorridorGraph
        or type(CorridorGraph.UpdateSettlementState) ~= "function"
    then
        return
    end
    local res = type(community.resources) == "table" and community.resources or {}
    local food = finite(res.food, 0)
    local water = finite(res.water, 0)
    local foodRatio = math.max(0, math.min(1, food / 40.0))
    local waterRatio = math.max(0, math.min(1, water / 40.0))
    local demandLevel = (foodRatio <= 0.10 or waterRatio <= 0.10) and "critical"
        or ((foodRatio < 0.30 or waterRatio < 0.30) and "shortage" or "normal")
    CorridorGraph.UpdateSettlementState(community.id, {
        foodRatio = foodRatio,
        waterRatio = waterRatio,
        demandLevel = demandLevel,
    })
end

function Service.OnGroupArriveAtSettlement(group, target, at)
    if type(group) ~= "table" or type(target) ~= "table" then
        return false, "invalid_args"
    end
    if target.type ~= "SETTLEMENT" and not target.communityId then
        return false, "not_settlement"
    end
    local community = resolveCommunity(target)
    if not community or community.status == "COLLAPSED" then
        return false, "community_not_found"
    end
    -- Own home community: handled by scavenger deposit, never raided.
    if group.homeCommunityId and tostring(group.homeCommunityId) == tostring(community.id) then
        return false, "home_community"
    end

    at = finite(at, 0)
    local rel = relationBetween(group.factionId, community.factionId)
    local stance, isHostile, stanceReason = Diplomacy.EvaluateEncounterStance(
        group,
        { type = "SETTLEMENT", factionId = community.factionId },
        rel
    )

    -- 1. Hostile Raid (Looters, hostile Refugees, or desperate starving squads).
    if isHostile then
        local attPower = participantPower(group.memberIds, group.memberIds and #group.memberIds or 3)
        local defPower = participantPower(community.memberIds, community.population or 4)
        local report, reason = SettlementOps.ResolveRaid({
            attacker = group,
            community = community,
            attackerPower = attPower,
            defenderPower = defPower,
            nowHours = at,
        })
        if not report then return false, reason end

        local home = type(community.home) == "table" and community.home or target
        local cx, cy, cz = finite(home.x, target.x), finite(home.y, target.y), finite(home.z, 0)

        if report.outcome == "PLAYER_BASE_PERIMETER_WARNING" then
            if PNC.AbstractAftermathService
                and type(PNC.AbstractAftermathService.BroadcastRadioNotice) == "function"
            then
                pcall(
                    PNC.AbstractAftermathService.BroadcastRadioNotice,
                    "PLAYER_BASE_RAID_WARNING",
                    cx,
                    cy,
                    "Hostile " .. tostring(group.groupType or "raiders")
                        .. " spotted probing the perimeter of your base!"
                )
            end
            return true, report
        end

        syncHubDemand(community)

        if WorldEvents and type(WorldEvents.Publish) == "function" then
            WorldEvents.Publish({
                id = "raid_aftermath:" .. tostring(community.id) .. ":" .. tostring(math.floor(at)),
                kind = "RAID_AFTERMATH",
                ownerMod = "ProjectHoomans",
                x = cx,
                y = cy,
                z = cz,
                createdAt = at,
                ttlHours = 24,
                severity = report.outcome == "DECISIVE_RAID" and 3 or 2,
                summary = tostring(community.name or community.id)
                    .. " raid outcome: " .. tostring(report.outcome)
                    .. " (" .. tostring(stanceReason) .. ")",
                tags = { raid_aftermath = true },
            }, at)
        end

        if PNC.AbstractAftermathService
            and type(PNC.AbstractAftermathService.BroadcastRadioNotice) == "function"
        then
            local msg = report.outcome == "REPELLED"
                and (tostring(community.name or "A nearby settlement") .. " repelled a raid!")
                or (tostring(community.name or "A nearby settlement") .. " was raided for supplies.")
            pcall(PNC.AbstractAftermathService.BroadcastRadioNotice, "SETTLEMENT_RAIDED", cx, cy, msg)
        end

        if report.attackerShouldFlee
            and PNC.AbstractTraversal
            and type(PNC.AbstractTraversal.BeginFarMigration) == "function"
        then
            PNC.AbstractTraversal.BeginFarMigration(group, { threatX = cx, threatY = cy }, at)
        end
        return true, report
    end

    -- 2. Trader / Caravan visiting an AI settlement: O(1) supply barter.
    local gType = string.upper(tostring(group.groupType or ""))
    if gType == "TRADER" or gType == "CARAVAN" then
        local barter, reason = SettlementOps.ResolveTraderBarter(group, community, at)
        if not barter or barter.traded ~= true then
            return false, reason or "no_trade"
        end
        syncHubDemand(community)
        if barter.savedFromStarvation
            and PNC.AbstractAftermathService
            and type(PNC.AbstractAftermathService.BroadcastRadioNotice) == "function"
        then
            local home = type(community.home) == "table" and community.home or target
            pcall(
                PNC.AbstractAftermathService.BroadcastRadioNotice,
                "CARAVAN_RESUPPLY",
                finite(home.x, target.x),
                finite(home.y, target.y),
                "A passing caravan delivered food and water to "
                    .. tostring(community.name or "a struggling settlement") .. "."
            )
        end
        return true, barter
    end

    return false, stance
end

return Service
