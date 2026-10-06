-- Corpse haul automatic assignment and queueing.
--
-- This provider selects eligible corpses and creates bounded background
-- orders. Manual requests are loaded by the sibling manual provider.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Work = PNC.WorkService
local WorkRepository = PNC.WorkRepository

local function findBaseAssignment(base)
    local configuration = Internal.configurationFor(base)
    if not configuration or not configuration.sourceRegion then
        return nil, "CORPSE_HAUL_NOT_CONFIGURED"
    end
    local destinationRegion = configuration.destinationRegion
    local facilities = destinationRegion and {} or Internal.stockpileFacilities(base)
    local corpses = Internal.scanBaseCorpses(base)
    local sawReserved = false
    local sawDropFailure = false
    if #corpses <= 0 then
        return nil, "NO_CORPSE_IN_SOURCE_REGION"
    end
    if not destinationRegion and #facilities <= 0 then
        return nil, "NO_STOCKPILE_DESTINATION"
    end
    for _, candidate in ipairs(corpses) do
        local data = candidate.corpse:getModData()
        local token = candidate.token
        local active = token and (Internal.workOrderForToken(token)
            or Service.Runtime.byToken[token]) or nil
        local stale = data and data.PNC_CorpseHaulTaskId
        if not active and (not stale or not Service.IsLifecycleProtected(stale)) then
            if stale then
                data.PNC_CorpseHaulTaskId = nil
                Internal.transmit(candidate.corpse)
                stale = nil
            end
            if not stale then
                local destinations = destinationRegion and { {} } or facilities
                for _, facility in ipairs(destinations) do
                    local facilityId = facility and facility.id or nil
                    local drop = Internal.findDropPoint(facilityId, candidate.x,
                        candidate.y, candidate.z, destinationRegion)
                    if drop then
                        token = Service.GetCorpseToken(candidate.corpse, true)
                        if not token then
                            return nil, "CORPSE_TOKEN_UNAVAILABLE"
                        end
                        return {
                            haulToken = token,
                            deathMarkerId = candidate.deathMarkerId,
                            baseId = base.id, facilityId = facilityId,
                            sourceX = candidate.x, sourceY = candidate.y,
                            sourceZ = candidate.z,
                            interactionX = candidate.x,
                            interactionY = candidate.y,
                            interactionZ = candidate.z,
                            dropX = drop.x, dropY = drop.y, dropZ = drop.z,
                            destinationRegion = destinationRegion
                                and (Core.DeepCopy
                                    and Core.DeepCopy(destinationRegion)
                                    or destinationRegion) or nil,
                        }
                    end
                    sawDropFailure = true
                end
            end
        else
            sawReserved = true
        end
        if not token and data and data.PNC_CorpseHaulTaskId then
            sawReserved = true
        end
    end
    if sawDropFailure then return nil, "NO_DROP_POINT" end
    if sawReserved then return nil, "CORPSE_ALREADY_RESERVED" end
    return nil, "NO_DROP_POINT"
end


local function queuePendingOrders()
    local settlements = PNC.SettlementRepository
    local queued = 0
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not settlements or not settlements.Load
    then return queued end
    settlements.Load()
    for _, base in pairs(settlements.State and settlements.State.bases or {}) do
        if Internal.pendingCorpseOrderCount(base.id)
            < Service.MAX_PENDING_CORPSE_ORDERS_PER_BASE
        then
            local assignment = findBaseAssignment(base)
            if assignment then
                local configuration = Internal.configurationFor(base)
                local order = Work.Commands.Queue({
                    operation = "CORPSE_HAUL", colonyId = base.colonyId,
                    factionId = base.factionId, baseId = base.id,
                    quantity = 1, requiredWork = 1, priority = 10,
                    locationPolicy = { start = "HOME", execution = "REMOTE",
                        returnHome = "HOME" },
                    phase = "SOURCE_APPROACH",
                    payload = {
                        haulToken = assignment.haulToken,
                        deathMarkerId = assignment.deathMarkerId,
                        sourceX = assignment.sourceX,
                        sourceY = assignment.sourceY,
                        sourceZ = assignment.sourceZ,
                        interactionX = assignment.interactionX,
                        interactionY = assignment.interactionY,
                        interactionZ = assignment.interactionZ,
                        dropX = assignment.dropX, dropY = assignment.dropY,
                        dropZ = assignment.dropZ,
                        facilityId = assignment.facilityId,
                        destinationRegion = assignment.destinationRegion,
                        configurationRevision = configuration
                            and configuration.revision or 0,
                    },
                })
                if order then queued = queued + 1 end
            end
        end
    end
    return queued
end

Internal.findBaseAssignment = findBaseAssignment
Internal.queuePendingOrders = queuePendingOrders

return Service
