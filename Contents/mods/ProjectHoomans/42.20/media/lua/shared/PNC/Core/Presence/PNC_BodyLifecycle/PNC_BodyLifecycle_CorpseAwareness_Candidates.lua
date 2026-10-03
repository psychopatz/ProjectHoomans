local Awareness = PNC and PNC.CorpseAwareness
if not Awareness then return end

local Internal = Awareness.Internal or {}
local Deps = Internal.CandidateDeps or {}
local relationFor = Deps.relationFor
local classify = Deps.classify
local RELATION_PRIORITY = Deps.RELATION_PRIORITY
local DETECTION_RADIUS = Deps.DETECTION_RADIUS
local DETECTION_RADIUS_SQ = Deps.DETECTION_RADIUS_SQ
local MAX_NPCS_TO_SCORE = Deps.MAX_NPCS_TO_SCORE

local function corpsePosition(record, corpse)
    local x = corpse and corpse.getX and corpse:getX() or record and record.x
    local y = corpse and corpse.getY and corpse:getY() or record and record.y
    local z = corpse and corpse.getZ and corpse:getZ() or record and record.z
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z) or 0
    if not x or not y then return nil end
    return x, y, z
end

local function candidateRelation(observer, deceased, identity)
    local targetKey
    local relationship
    local rawRelationship
    local observerFactionID = observer and observer.affiliation
        and tostring(observer.affiliation.factionID or "") or ""
    local corpseFactionID = tostring(identity and identity.factionID or "")
    local sameFaction = observerFactionID ~= ""
        and corpseFactionID ~= ""
        and observerFactionID == corpseFactionID
    targetKey, relationship, rawRelationship = relationFor(
        observer,
        identity.npcID
    )
    local category = classify(
        observer,
        deceased,
        identity,
        relationship,
        rawRelationship,
        sameFaction
    )
    return targetKey, relationship, category, sameFaction
end

local function collectCandidates(record, corpse, corpseData, identity)
    local spatial = PNC.SpatialIndex
    local registry = PNC.Registry
    local x, y, z = corpsePosition(record, corpse)
    local indexed
    local candidates = {}
    local indexedCount
    local cursor
    local scanCount
    local offset
    local index
    local observer
    local actor
    local actorX
    local actorY
    local actorZ
    local dx
    local dy
    local dz
    local targetKey
    local relationship
    local category
    local sameFaction
    local corpsePresenceState = PNC.Const
        and PNC.Const.PRESENCE_CORPSE or "corpse"
    if not x or not y or not spatial
        or type(spatial.QueryNPCs) ~= "function"
    then
        return candidates
    end
    indexed = spatial.QueryNPCs(x, y, DETECTION_RADIUS)
    if type(indexed) ~= "table" then return candidates end
    indexedCount = #indexed
    if indexedCount <= 0 then return candidates end
    cursor = math.floor(tonumber(
        corpseData.PNC_CorpseAwarenessCandidateCursor
    ) or 0) % indexedCount
    scanCount = math.min(indexedCount, MAX_NPCS_TO_SCORE)
    for offset = 0, scanCount - 1 do
        index = ((cursor + offset) % indexedCount) + 1
        observer = indexed[index]
        if observer and observer.id ~= nil
            and tostring(observer.id) ~= identity.npcID
            and observer.alive ~= false
            and observer.presenceState ~= corpsePresenceState
        then
            actor = registry and registry.GetLiveZombie
                and registry.GetLiveZombie(observer.id) or nil
            if actor and not (actor.isDead and actor:isDead()) then
                actorX = actor.getX and actor:getX() or observer.x
                actorY = actor.getY and actor:getY() or observer.y
                actorZ = actor.getZ and actor:getZ() or observer.z
                dx = (tonumber(actorX) or x) - x
                dy = (tonumber(actorY) or y) - y
                dz = math.abs((tonumber(actorZ) or z) - z)
                if dz < 1 and dx * dx + dy * dy <= DETECTION_RADIUS_SQ then
                    targetKey, relationship, category, sameFaction =
                        candidateRelation(observer, record, identity)
                    candidates[#candidates + 1] = {
                        record = observer,
                        actor = actor,
                        targetKey = targetKey,
                        relationship = relationship,
                        category = category,
                        sameFaction = sameFaction,
                        priority = (sameFaction and 10 or 0)
                            + (RELATION_PRIORITY[category] or 1),
                        distanceSq = dx * dx + dy * dy,
                    }
                end
            end
        end
    end
    corpseData.PNC_CorpseAwarenessCandidateCursor =
        (cursor + scanCount) % indexedCount
    table.sort(candidates, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return tostring(left.record.id) < tostring(right.record.id)
    end)
    return candidates
end


Awareness.Internal.Candidates = { collectCandidates = collectCandidates }
