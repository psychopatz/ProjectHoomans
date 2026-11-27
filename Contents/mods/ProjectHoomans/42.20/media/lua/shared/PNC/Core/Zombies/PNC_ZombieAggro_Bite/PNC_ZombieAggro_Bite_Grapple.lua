--[[
    PNC Zombie Aggro Bite Grapple
    Coordinates paired zombie + NPC grapple/struggle/shove-off/drag-down
    animations and bounded NPC movement holds across SP and MP.
]]

local ZombieAggro = PNC.ZombieAggro
local BiteInternal = ZombieAggro.BiteInternal
local Core = PNC.Core
local Const = PNC.Const
local State = ZombieAggro.State

local DRAG_DOWN_MIN_GRAPPLERS = 3

local function isDragDownAllowed()
    local lore = type(SandboxVars) == "table" and SandboxVars.ZombieLore or nil
    if type(lore) == "table" and lore.ZombiesDragDown == false then
        return false
    end
    return true
end

function BiteInternal.CountActiveGrapplers(npcId)
    local bites = State and State.bites or nil
    local count = 0
    if not npcId or type(bites) ~= "table" then return 0 end
    local targetKey = tostring(npcId)
    for _, entry in pairs(bites) do
        if entry and tostring(entry.npcId or "") == targetKey
            and entry.phase ~= "release" and entry.phase ~= "finished"
        then
            count = count + 1
        end
    end
    return count
end

function BiteInternal.ResolveNPCStruggleBump(zombie, npcBody)
    if zombie and npcBody then
        if type(npcBody.testDotSide) == "function" then
            local side = string.lower(tostring(npcBody:testDotSide(zombie) or "front"))
            if side == "behind" or side == "left" or side == "right" then
                return "PNC_Anim_bite"
            end
        elseif type(zombie.isBehind) == "function" and zombie:isBehind(npcBody) == true then
            return "PNC_Anim_bite"
        end
    end
    return "PNC_BiteDefended"
end

function BiteInternal.ResolveNPCShoveBump(npcBody)
    local item = npcBody and npcBody.getPrimaryHandItem
        and npcBody:getPrimaryHandItem() or nil
    if item then
        local isRanged = item.isRanged and item:isRanged() == true
        local twoHanded = item.isTwoHandWeapon and item:isTwoHandWeapon() == true
        if isRanged then
            return twoHanded and "PNC_ShoveRifle" or "PNC_ShoveHandgun"
        end
        if twoHanded then
            return "PNC_ShoveBat"
        end
    end
    return "PNC_Shove"
end

local function playNPCBump(npcBody, record, bumpType, durationMs, now)
    local Animation = PNC.Animation
    if not npcBody or not bumpType or not Animation
        or type(Animation.PlayBump) ~= "function"
    then
        return false
    end
    local ok, accepted = pcall(
        Animation.PlayBump,
        npcBody,
        record,
        bumpType,
        {
            leaseUntil = now + math.max(300, tonumber(durationMs) or 600),
            allowInCombat = true,
        }
    )
    return ok and accepted == true
end

function BiteInternal.BeginGrapple(entry, record, zombie, npcBody, now)
    if not entry or not zombie or not npcBody then return nil end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if zombie.faceThisObject then zombie:faceThisObject(npcBody) end
    if npcBody.faceThisObject then npcBody:faceThisObject(zombie) end

    local grapplers = BiteInternal.CountActiveGrapplers(entry.npcId)
    local dragDown = isDragDownAllowed() and grapplers >= DRAG_DOWN_MIN_GRAPPLERS
    if dragDown then
        entry.dragDown = true
        entry.bumpType = "BiteLow"
        if npcBody.setOnFloor then npcBody:setOnFloor(true) end
    end

    local npcBump = dragDown and "PNC_Anim_bite"
        or BiteInternal.ResolveNPCStruggleBump(zombie, npcBody)
    entry.npcStruggleBump = npcBump

    local applyDelay = tonumber(Const and Const.ZOMBIE_BITE_APPLY_DELAY_MS) or 450
    if record then
        record.runtime = record.runtime or {}
        record.runtime.grappleHoldUntil = now + applyDelay + 150
    end

    if not (isServer and isServer() == true) then
        playNPCBump(npcBody, record, npcBump, applyDelay + 150, now)
    end
    return npcBump
end

function BiteInternal.ResolveGrappleOutcome(
    entry, record, zombie, npcBody, applied, avoided, now
)
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if avoided and entry and entry.pushed == true then
        local shoveBump = BiteInternal.ResolveNPCShoveBump(npcBody)
        entry.npcOutcomeBump = shoveBump
        if record and record.runtime then
            record.runtime.grappleHoldUntil = nil
        end
        if not (isServer and isServer() == true) then
            playNPCBump(npcBody, record, shoveBump, 500, now)
        end
        local reaction = PNC.CombatZombieReaction
        if reaction and type(reaction.ApplyHitReaction) == "function" then
            pcall(reaction.ApplyHitReaction, zombie, npcBody, {
                shove = true,
                knockdown = false,
                source = "grapple_break_free",
            })
        end
        return "defended", shoveBump
    end
    if applied then
        local hitBump = "PNC_Anim_bite"
        entry.npcOutcomeBump = hitBump
        if not (isServer and isServer() == true) then
            playNPCBump(npcBody, record, hitBump, 550, now)
        end
        return "impact", hitBump
    end
    return nil, nil
end

function BiteInternal.ReleaseGrappleHold(record, entry)
    if not record or not record.runtime or not entry then return end
    if BiteInternal.CountActiveGrapplers(entry.npcId) <= 0 then
        record.runtime.grappleHoldUntil = nil
    end
end

return ZombieAggro
