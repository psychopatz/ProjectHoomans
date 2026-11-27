--[[
    PNC Nameplate Renderer: Combat Debug Zombie AI Thought Overlay
    Renders concise, color-coded AI thought labels and steering vectors over
    nearby zombies whenever the Combat Debug overlay is active.
    Strictly bounded (<= 12 nearest zombies within 16 tiles) and zero-cost
    when Combat Debug is disabled.
]]

local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Presentation = PNC.NameplatePresentation
local Fonts = Presentation and Presentation.Fonts or nil
local screenPoint = Internal.ScreenPoint
local drawWorldLine = Internal.DrawWorldLine

local MAX_ZOMBIES_DRAWN = 12
local MAX_SCAN_RADIUS_SQ = 16 * 16

local COLOR_NPC_PURSUIT = { r = 0.25, g = 0.95, b = 0.72, a = 0.96 }
local COLOR_NPC_BITE = { r = 1.0, g = 0.22, b = 0.42, a = 0.98 }
local COLOR_PLAYER_PURSUIT = { r = 1.0, g = 0.52, b = 0.14, a = 0.96 }
local COLOR_IDLE = { r = 0.72, g = 0.78, b = 0.84, a = 0.86 }
local COLOR_DETAIL = { r = 0.86, g = 0.92, b = 1.0, a = 0.92 }

local function isManagedNPC(zombie)
    return PNC.Core and PNC.Core.IsManagedNPCBody
        and PNC.Core.IsManagedNPCBody(zombie) == true
end

local function npcDisplayLabel(npcId)
    if npcId == nil then return "none" end
    local idStr = tostring(npcId)
    local rec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(idStr) or nil
    if rec then
        return tostring(rec.displayName or rec.name or idStr)
    end
    return idStr
end

local function nativeTargetLabel(zombie)
    local target = zombie and zombie.getTarget and zombie:getTarget() or nil
    if not target then return "none" end
    if isManagedNPC(target) then return "npc_shell" end
    if instanceof and instanceof(target, "IsoPlayer") then
        local name = target.getUsername and target:getUsername() or "player"
        return "player:" .. tostring(name)
    end
    return "other"
end

local function activeBiteFor(zombie)
    local aggro = PNC.ZombieAggro
    local bites = aggro and aggro.State and aggro.State.bites or nil
    if type(bites) ~= "table" then return nil end
    for _, entry in pairs(bites) do
        if entry and entry.zombie == zombie then
            return entry
        end
    end
    return nil
end

local function buildZombieThought(zombie, now)
    local modData = zombie.getModData and zombie:getModData() or nil
    local action = zombie.getActionStateName
        and string.lower(tostring(zombie:getActionStateName() or "-")) or "-"
    local moving = zombie.isMoving and zombie:isMoving() == true
    local bPathfind = zombie.getVariableBoolean
        and zombie:getVariableBoolean("bPathfind") == true
    local lungeVis = zombie.getVariableBoolean
        and zombie:getVariableBoolean("PNCZombieLunge") == true
    local noLunge = zombie.getVariableBoolean
        and zombie:getVariableBoolean("NoLungeAttack") == true
    local nativeTgt = nativeTargetLabel(zombie)
    local bite = activeBiteFor(zombie)

    local leaseOwner = modData and modData.PNC_ZombiePursuitOwner or nil
    local leaseUntil = modData and tonumber(modData.PNC_ZombiePursuitUntil) or 0
    local leaseActive = leaseOwner ~= nil and leaseUntil > now
    local leaseTarget = modData and modData.PNC_ZombiePursuitTarget or nil
    local forcedNpcId = modData and modData.PNC_AggroNPCId or nil
    local nativeCombatReason = modData and modData.PNC_NativeCombatReason or nil
    local nativeCombatUntil = modData and tonumber(modData.PNC_NativeCombatUntil) or 0
    local backoffMs = modData and tonumber(modData.PNC_AggroBackoffMs) or 0

    local headerColor = COLOR_IDLE
    local line1
    if bite then
        headerColor = COLOR_NPC_BITE
        line1 = "ZAI BITE[" .. tostring(bite.phase or "?") .. "] -> "
            .. npcDisplayLabel(bite.npcId)
            .. " bump=" .. tostring(bite.bumpType or "-")
    elseif leaseActive and leaseOwner == "ProjectHoomans" then
        headerColor = COLOR_NPC_PURSUIT
        local mode = bPathfind and "A*" or (moving and "walk" or "idle")
        line1 = "ZAI NPC -> " .. npcDisplayLabel(leaseTarget or forcedNpcId)
            .. " [" .. mode .. (lungeVis and "+LUNGE" or "") .. "]"
    elseif string.sub(nativeTgt, 1, 7) == "player:" then
        headerColor = COLOR_PLAYER_PURSUIT
        local why = (nativeCombatUntil > now and nativeCombatReason)
            or (action == "attack" and "player_attack")
            or (action == "lunge" and "player_lunge")
            or "vanilla_sight"
        line1 = "ZAI " .. nativeTgt .. " why=" .. tostring(why)
    elseif leaseActive then
        headerColor = COLOR_NPC_PURSUIT
        line1 = "ZAI owner=" .. tostring(leaseOwner)
            .. " tgt=" .. tostring(leaseTarget or "-")
    else
        line1 = "ZAI idle st=" .. action
    end

    local line2 = "st=" .. action
        .. " mv=" .. (moving and "1" or "0")
        .. " pf=" .. (bPathfind and "1" or "0")
        .. " lng=" .. (lungeVis and "1" or "0")
        .. " nl=" .. (noLunge and "1" or "0")
        .. " nat=" .. nativeTgt
    if backoffMs > 0 then
        line2 = line2 .. " bk=" .. tostring(math.floor(backoffMs)) .. "ms"
    end

    local fx, fy, fz = nil, nil, nil
    local behavior = zombie.getPathFindBehavior2
        and zombie:getPathFindBehavior2() or nil
    if behavior and type(behavior.getTargetX) == "function"
        and type(behavior.getTargetY) == "function"
    then
        local tx = tonumber(behavior:getTargetX())
        local ty = tonumber(behavior:getTargetY())
        local tz = type(behavior.getTargetZ) == "function"
            and tonumber(behavior:getTargetZ()) or zombie:getZ()
        if tx and ty and (tx ~= 0 or ty ~= 0) then
            fx, fy, fz = tx, ty, tz or zombie:getZ()
        end
    end

    return line1, line2, headerColor, fx, fy, fz
end

local function drawCenteredOutline(manager, text, sx, sy, color, font)
    if not manager or not manager.drawTextCentre then return end
    manager:drawTextCentre(text, sx + 1, sy + 1, 0, 0, 0, 0.9, font)
    manager:drawTextCentre(text, sx, sy, color.r, color.g, color.b, color.a, font)
end

function Renderer.RenderCombatZombieThoughts(manager, settings, renderState)
    if not manager or not manager.player or not settings
        or settings.showCombatDebug ~= true
    then
        return
    end
    -- Iterate only the bounded ZombieAggro.ActiveSet (never the full world
    -- getCell():getZombieList() at 60 FPS) so Combat Debug adds near-zero cost.
    local activeSet = PNC.ZombieAggro and PNC.ZombieAggro.ActiveSet or nil
    local order = activeSet and activeSet.order or nil
    local byID = activeSet and activeSet.byID or nil
    if type(order) ~= "table" or type(byID) ~= "table" then return end
    local px, py, pz = manager.player:getX(), manager.player:getY(), manager.player:getZ()
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local font = (Fonts and (Fonts.Small or Fonts.Default))
        or (UIFont and UIFont.Small) or nil
    local drawn = 0
    for i = 1, #order do
        if drawn >= MAX_ZOMBIES_DRAWN then break end
        local id = order[i]
        local entry = id and byID[id] or nil
        local zombie = entry and entry.zombie or nil
        if zombie and not (zombie.isDead and zombie:isDead())
            and not isManagedNPC(zombie)
        then
            local zx, zy, zz = zombie:getX(), zombie:getY(), zombie:getZ()
            if math.abs((zz or 0) - pz) <= 1.5 then
                local dx, dy = (zx or 0) - px, (zy or 0) - py
                if ((dx * dx) + (dy * dy)) <= MAX_SCAN_RADIUS_SQ then
                    drawn = drawn + 1
                    local line1, line2, color, fx, fy, fz = buildZombieThought(zombie, now)
                    if fx and fy and drawWorldLine
                        and ((fx - zx) * (fx - zx) + (fy - zy) * (fy - zy)) > 0.25
                    then
                        drawWorldLine(manager, zx, zy, zz, fx, fy, fz, color)
                    end
                    if type(screenPoint) == "function" then
                        local sx, sy = screenPoint(manager, zx, zy, zz)
                        if sx and sy then
                            drawCenteredOutline(manager, line1, sx, sy - 42, color, font)
                            drawCenteredOutline(manager, line2, sx, sy - 28, COLOR_DETAIL, font)
                        end
                    end
                end
            end
        end
    end
end

Internal.BuildCombatZombieThought = buildZombieThought

return Renderer
