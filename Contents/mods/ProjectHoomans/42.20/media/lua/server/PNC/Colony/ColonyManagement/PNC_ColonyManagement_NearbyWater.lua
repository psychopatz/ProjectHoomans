if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
local canUseDebug = Internal.canUseDebug
local owned = Internal.owned

local function startNearbyWaterAction(player, args, debugOnly)
    if debugOnly and not canUseDebug(player) then
        return false, "not_authorized"
    end
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    local runtime = record.runtime or {}
    if runtime.workOrderId or runtime.attackAction or runtime.target
        or record.health and record.health.state == "incapacitated"
        or PNC.NeedFacilityAwayRoutes
            and PNC.NeedFacilityAwayRoutes.IsCombatActive
            and PNC.NeedFacilityAwayRoutes.IsCombatActive(record)
    then return false, "NPC_BUSY" end
    local service = PNC.NearbyWaterService
    local exact = args.sourceX ~= nil and args.sourceY ~= nil
    if exact and player and player.getX and player.getY then
        local dx = player:getX() - (tonumber(args.sourceX) or 0)
        local dy = player:getY() - (tonumber(args.sourceY) or 0)
        if dx * dx + dy * dy > 64
            or math.floor(tonumber(player:getZ()) or 0)
                ~= math.floor(tonumber(args.sourceZ) or 0)
        then return false, "WATER_SOURCE_TOO_FAR" end
    end
    local source
    if exact then
        source = service and service.FindAt
            and service.FindAt(record, args.sourceX, args.sourceY, args.sourceZ)
            or nil
    else
        source = service and service.Find and service.Find(record) or nil
    end
    if not source then return false, "NEARBY_WATER_NOT_FOUND" end
    local target, approaches = service.BuildApproach(record, source)
    if not target then return false, approaches end
    if PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
        and PNC.TaskLeaseService.ForNPC(record.id)
        and PNC.Tasking and PNC.Tasking.Commands
    then
        PNC.Tasking.Commands.CancelForNPC(
            record.id, debugOnly and "debug_water_command"
                or "player_water_command")
    end
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local facility = {
        id = "nearby_water:" .. (debugOnly and "debug:" or "command:")
            .. tostring(source.key),
        baseId = "nearby", definitionId = "nearby_water",
    }
    local acquired = {
        ok = true, facilityId = facility.id, componentId = "",
        reservationId = "", target = target,
        approachCandidates = approaches,
    }
    return PNC.FacilityJobs.Start(record, facility, "water.nearby", {
        acquired = acquired, nearby = true, resource = source,
        resourceKey = source.key,
        resourceKind = "nearby_water",
        approachCandidates = approaches,
        debugForceWater = debugOnly == true,
        abstract = live == nil,
    })
end

local function debugNearbyWaterAction(player, args)
    return startNearbyWaterAction(player, args, true)
end

Internal.startNearbyWaterAction = startNearbyWaterAction
Internal.debugNearbyWaterAction = debugNearbyWaterAction

return Management
