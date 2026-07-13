PNC = PNC or {}
PNC.OrderSystem = PNC.OrderSystem or {}

local OrderSystem = PNC.OrderSystem
local Const = PNC.Const
local Core = PNC.Core
local Skills = PNC.Skills

OrderSystem.Normalizers = OrderSystem.Normalizers or {}

function OrderSystem.RegisterNormalizer(kind, normalizer)
    kind = tostring(kind or "")
    if kind == "" or type(normalizer) ~= "function" then return false end
    OrderSystem.Normalizers[kind] = normalizer
    return true
end

local function fallbackOrder(record)
    if record.faction == "hostile" then
        return { kind = Const.ORDER_HOSTILE_HUNT }
    end
    return { kind = Const.ORDER_GUARD, x = record.anchorX, y = record.anchorY, z = record.anchorZ }
end

function OrderSystem.Normalize(record, orderSpec)
    local spec = orderSpec or fallbackOrder(record)
    local kind = tostring(spec.kind or spec.mode or "")
    local normalizer
    local normalized

    if kind == "" then
        return fallbackOrder(record)
    end

    normalizer = OrderSystem.Normalizers[kind]
    if normalizer then
        normalized = normalizer(record, spec)
        if type(normalized) == "table" then return normalized end
        return fallbackOrder(record)
    end

    if kind == Const.ORDER_FOLLOW then
        return {
            kind = kind,
            ownerUsername = spec.ownerUsername or record.ownerUsername,
            ownerOnlineID = spec.ownerOnlineID or record.ownerOnlineID,
        }
    end

    if kind == Const.ORDER_GUARD then
        return {
            kind = kind,
            x = tonumber(spec.x) or record.anchorX,
            y = tonumber(spec.y) or record.anchorY,
            z = tonumber(spec.z) or record.anchorZ,
        }
    end

    if kind == Const.ORDER_PATROL then
        return {
            kind = kind,
            points = Core.DeepCopy(spec.points or record.patrolPoints or {
                { x = record.anchorX, y = record.anchorY, z = record.anchorZ },
            }),
        }
    end

    if kind == Const.ORDER_HOSTILE_HUNT then
        return {
            kind = kind,
            x = tonumber(spec.x) or record.anchorX,
            y = tonumber(spec.y) or record.anchorY,
            z = tonumber(spec.z) or record.anchorZ,
        }
    end

    return fallbackOrder(record)
end

function OrderSystem.SetOrder(record, orderSpec)
    record.orderSpec = OrderSystem.Normalize(record, orderSpec)
    if record.orderSpec.kind == Const.ORDER_FOLLOW then
        record.ownerUsername = record.orderSpec.ownerUsername
        record.ownerOnlineID = record.orderSpec.ownerOnlineID
    end
    record.runtime.target = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.followState = nil
    record.runtime.roaming = nil
    record.runtime.roamGoalX = nil
    record.runtime.roamGoalY = nil
    record.runtime.roamGoalZ = nil
    if record.orderSpec.kind == Const.ORDER_PATROL and record.patrolIndex == nil then
        record.patrolIndex = 1
    end
    if Skills and Skills.SyncRecruitment then
        Skills.SyncRecruitment(record)
    end
end

function OrderSystem.SetHostility(record, modeSpec)
    record.hostility = record.hostility or {}
    if modeSpec and modeSpec.mode ~= nil then
        record.hostility.mode = tostring(modeSpec.mode)
    else
        record.hostility.mode = tostring(record.hostility.mode or "neutral")
    end
    if modeSpec and modeSpec.attackPlayers ~= nil then
        record.hostility.attackPlayers = modeSpec.attackPlayers == true
    else
        record.hostility.attackPlayers = record.hostility.attackPlayers == true
    end
    if modeSpec and modeSpec.attackNPCs ~= nil then
        record.hostility.attackNPCs = modeSpec.attackNPCs == true
    else
        record.hostility.attackNPCs = record.hostility.attackNPCs == true
    end
    if modeSpec and modeSpec.attackZombies ~= nil then
        record.hostility.attackZombies = modeSpec.attackZombies == true
    else
        record.hostility.attackZombies = record.hostility.attackZombies == true
    end
end
