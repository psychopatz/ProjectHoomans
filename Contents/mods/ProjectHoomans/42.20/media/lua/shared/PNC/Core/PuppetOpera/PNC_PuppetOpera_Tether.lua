-- Shared actor-to-actor tether & safe-drop controller for Puppet Opera.
--
-- Used server-side for authoritative coupled movement (carry, handhold, drag,
-- close partner beats) and client-side for zero-jitter MP visual lockstep.
-- Explicitly avoids vanilla grapple/pickUpCorpse APIs.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Tether = PNC.PuppetOpera.Tether or {}

local Tether = PNC.PuppetOpera.Tether

local function readForward(body)
    if not body then return 0, 1 end
    if body.getForwardDirection then
        local dir = body:getForwardDirection()
        if dir and dir.getX and dir.getY then
            local dx = tonumber(dir:getX()) or 0
            local dy = tonumber(dir:getY()) or 0
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0.0001 then return dx / len, dy / len end
        end
    end
    if body.getForwardDirectionX and body.getForwardDirectionY then
        local dx = tonumber(body:getForwardDirectionX()) or 0
        local dy = tonumber(body:getForwardDirectionY()) or 0
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0.0001 then return dx / len, dy / len end
    end
    return 0, 1
end

local function squareAt(x, y, z)
    if type(getCell) ~= "function" then return nil end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

local function isWalkableDropSquare(sq)
    if not sq then return false end
    if sq.HasStairs and sq:HasStairs() then return false end
    if sq.isSolid and sq:isSolid() then return false end
    if sq.isSolidTrans and sq:isSolidTrans() then return false end
    if sq.TreatAsSolidFloor and not sq:TreatAsSolidFloor() then return false end
    return true
end

function Tether.ComputeTarget(leaderBody, coupling)
    if not leaderBody or not leaderBody.getX or not leaderBody.getY then
        return nil, "tether_leader_unavailable"
    end
    coupling = type(coupling) == "table" and coupling or {}
    local lx = tonumber(leaderBody:getX()) or 0
    local ly = tonumber(leaderBody:getY()) or 0
    local lz = leaderBody.getZ and tonumber(leaderBody:getZ()) or 0
    local fx, fy = readForward(leaderBody)
    local rx, ry = -fy, fx

    local offR = tonumber(coupling.offsetRight) or 0
    local offF = tonumber(coupling.offsetForward) or 0
    local offZ = tonumber(coupling.offsetZ) or 0

    local tx = lx + rx * offR + fx * offF
    local ty = ly + ry * offR + fy * offF
    local tz = lz + offZ

    local sq = squareAt(tx, ty, tz)
    if sq and sq.HasStairs and sq:HasStairs() and sq.getApparentZ then
        local appZ = tonumber(sq:getApparentZ(tx - sq:getX(), ty - sq:getY()))
        if appZ then tz = appZ + offZ end
    end

    local facingMode = tostring(coupling.facingMode or "match")
    local faceX, faceY = fx, fy
    if facingMode == "opposite" then
        faceX, faceY = -fx, -fy
    elseif facingMode == "face_target" then
        local dx = lx - tx
        local dy = ly - ty
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0.0001 then
            faceX, faceY = dx / len, dy / len
        end
    end

    return {
        x = tx,
        y = ty,
        z = tz,
        square = sq,
        faceX = faceX,
        faceY = faceY,
        facingMode = facingMode,
    }
end

function Tether.ApplyBody(followerBody, leaderBody, coupling)
    if not followerBody or not leaderBody then
        return false, "tether_body_missing"
    end
    coupling = type(coupling) == "table" and coupling or {}
    local target, reason = Tether.ComputeTarget(leaderBody, coupling)
    if not target then return false, reason end

    if coupling.groundedCheck == true then
        local leaderSq = leaderBody.getSquare and leaderBody:getSquare()
            or squareAt(leaderBody:getX(), leaderBody:getY(),
                leaderBody.getZ and leaderBody:getZ() or 0)
        if not target.square then
            return false, "tether_grounded_square_missing"
        end
        if leaderSq and leaderSq.canReachTo
            and not leaderSq:canReachTo(target.square)
        then
            return false, "tether_grounded_blocked"
        end
    end

    if coupling.disableCollision ~= false then
        if followerBody.setCollidable then followerBody:setCollidable(false) end
        if followerBody.setSolid then followerBody:setSolid(false) end
    end
    if followerBody.setMoving then followerBody:setMoving(false) end
    if followerBody.setX then followerBody:setX(target.x) end
    if followerBody.setY then followerBody:setY(target.y) end
    if followerBody.setZ then followerBody:setZ(target.z) end
    if target.square and followerBody.setCurrent then
        followerBody:setCurrent(target.square)
    end
    if followerBody.setMovingSquareNow then
        followerBody:setMovingSquareNow()
    end
    if target.facingMode ~= "free" then
        if followerBody.setTargetAndCurrentDirection then
            followerBody:setTargetAndCurrentDirection(target.faceX, target.faceY)
        elseif followerBody.faceLocation then
            followerBody:faceLocation(
                target.x + target.faceX,
                target.y + target.faceY
            )
        end
    end
    return true, target
end

function Tether.FindSafeDropSquare(carrierBody)
    if not carrierBody or not carrierBody.getX or not carrierBody.getY then
        return nil
    end
    local cx = math.floor(tonumber(carrierBody:getX()) or 0)
    local cy = math.floor(tonumber(carrierBody:getY()) or 0)
    local cz = math.floor(carrierBody.getZ and tonumber(carrierBody:getZ()) or 0)
    local carrierSq = carrierBody.getSquare and carrierBody:getSquare()
        or squareAt(cx, cy, cz)
    local fx, fy = readForward(carrierBody)
    local ox = math.floor(fx + 0.5)
    local oy = math.floor(fy + 0.5)

    local candidates = {
        { cx + ox, cy + oy },
        { cx - oy, cy + ox },
        { cx + oy, cy - ox },
        { cx - ox, cy - oy },
        { cx + 1, cy },
        { cx - 1, cy },
        { cx, cy + 1 },
        { cx, cy - 1 },
        { cx, cy },
    }
    for _, pt in ipairs(candidates) do
        local sq = squareAt(pt[1], pt[2], cz)
        if isWalkableDropSquare(sq)
            and (not carrierSq or not carrierSq.canReachTo
                or carrierSq:canReachTo(sq))
        then
            return sq
        end
    end
    return carrierSq
end

function Tether.RestoreBody(followerBody, dropSquare)
    if not followerBody then return false end
    if dropSquare then
        local sx = dropSquare.getX and tonumber(dropSquare:getX()) or nil
        local sy = dropSquare.getY and tonumber(dropSquare:getY()) or nil
        local sz = dropSquare.getZ and tonumber(dropSquare:getZ()) or 0
        if sx and sy then
            if followerBody.setX then followerBody:setX(sx + 0.5) end
            if followerBody.setY then followerBody:setY(sy + 0.5) end
            if followerBody.setZ then followerBody:setZ(sz) end
            if followerBody.setCurrent then
                followerBody:setCurrent(dropSquare)
            end
            if followerBody.setMovingSquareNow then
                followerBody:setMovingSquareNow()
            end
        end
    end
    if followerBody.setCollidable then followerBody:setCollidable(true) end
    if followerBody.setSolid then followerBody:setSolid(true) end
    return true
end

function Tether.SyncAbstractPair(carrierRecord, passengerRecord)
    if type(carrierRecord) ~= "table" or type(passengerRecord) ~= "table" then
        return false
    end
    if carrierRecord.x ~= nil then passengerRecord.x = carrierRecord.x end
    if carrierRecord.y ~= nil then passengerRecord.y = carrierRecord.y end
    if carrierRecord.z ~= nil then passengerRecord.z = carrierRecord.z end
    if carrierRecord.lastX ~= nil then
        passengerRecord.lastX = carrierRecord.lastX
    end
    if carrierRecord.lastY ~= nil then
        passengerRecord.lastY = carrierRecord.lastY
    end
    if carrierRecord.lastZ ~= nil then
        passengerRecord.lastZ = carrierRecord.lastZ
    end
    return true
end

function Tether.SampleTrackProgress(leaderBody, clipName, durationSec)
    if not leaderBody or not leaderBody.dbgGetAnimTrackName then return nil end
    durationSec = tonumber(durationSec) or 1.0
    if durationSec <= 0.01 then durationSec = 1.0 end
    local targetLower = clipName and string.lower(tostring(clipName)) or nil
    local bestWeight, bestTime = -1, nil
    for i = 0, 15 do
        local name = leaderBody:dbgGetAnimTrackName(0, i)
        if not name or name == "" then break end
        if not targetLower or string.lower(tostring(name)) == targetLower then
            local weight = leaderBody.dbgGetAnimTrackWeight
                and tonumber(leaderBody:dbgGetAnimTrackWeight(0, i)) or 0
            if weight > bestWeight then
                bestWeight = weight
                bestTime = leaderBody.dbgGetAnimTrackTime
                    and tonumber(leaderBody:dbgGetAnimTrackTime(0, i)) or 0
            end
        end
    end
    if bestTime then return (bestTime / durationSec) % 1 end
    return nil
end

return Tether
