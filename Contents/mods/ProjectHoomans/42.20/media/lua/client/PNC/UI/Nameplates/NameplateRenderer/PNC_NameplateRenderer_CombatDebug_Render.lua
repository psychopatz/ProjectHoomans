local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Presentation = PNC.NameplatePresentation
local Fonts = Presentation.Fonts
local screenPoint = Internal.ScreenPoint
local drawVisionConeOnly = Internal.DrawVisionConeOnly
local drawCombatRanges = Internal.DrawCombatRanges
local drawCombatTargets = Internal.DrawCombatTargets
local appendCombatAnimationLines = Internal.AppendCombatAnimationLines
local drawCombatText = Internal.DrawCombatText
local resolveZombieAttacker = Internal.ResolveZombieAttacker

local function resolveDetailMode(settings)
    if type(settings) ~= "table" then
        return "full"
    end
    local mode = settings.combatDebugDetailMode
        or (PNC.Nameplates and PNC.Nameplates.Settings
            and PNC.Nameplates.Settings.combatDebugDetailMode)
        or "cones"
    mode = tostring(mode)
    if mode ~= "cones" and mode ~= "compact" and mode ~= "full" then
        return "cones"
    end
    return mode
end

local function isEntrySelectedOrHovered(manager, entry, worldX, worldY, worldZ, renderState)
    local npcId = tostring(
        entry.uuid or (entry.snapshot and entry.snapshot.id) or ""
    )
    local selectedId = type(renderState) == "table" and renderState.selectedId or nil
    if selectedId == nil then
        local clientState = PNC.Network and PNC.Network.ClientState or nil
        selectedId = clientState and clientState.unifiedAIDebug
            and tostring(clientState.unifiedAIDebug.selectedId or "") or ""
    end
    if npcId ~= "" and selectedId ~= "" and npcId == selectedId then
        return true
    end
    local mx = type(renderState) == "table" and renderState.mouseX or nil
    local my = type(renderState) == "table" and renderState.mouseY or nil
    if mx == nil and type(getMouseX) == "function" then
        mx = (tonumber(getMouseX()) or -9999) - (tonumber(manager.x) or 0)
    end
    if my == nil and type(getMouseY) == "function" then
        my = (tonumber(getMouseY()) or -9999) - (tonumber(manager.y) or 0)
    end
    if mx and my and mx > -9000 and my > -9000 and type(screenPoint) == "function" then
        local sx, sy = screenPoint(manager, worldX, worldY, worldZ)
        local dx = mx - sx
        local dy = my - sy
        if (dx * dx) + (dy * dy) <= (36 * 36) then
            return true
        end
    end
    return false
end

local function drawCombatDebug(manager, entry, settings, renderState)
    local zombie = entry.zombie
    local debugState = entry.snapshot
        and entry.snapshot.combatDebugState or nil
    if not zombie
        or zombie:isDead()
        or type(debugState) ~= 'table'
    then
        return
    end
    local worldX = zombie:getX()
    local worldY = zombie:getY()
    local worldZ = zombie:getZ()
    local target = debugState.target
    local active = type(target) == 'table'
        or type(debugState.action) == 'table'
        or type(debugState.tacticalMove) == 'table'
        or type(debugState.zombieAttacker) == 'table'
        or entry.snapshot.attackMode == true
        or entry.snapshot.inCombat == true
    local detailMode = resolveDetailMode(settings)
    local isSelected = isEntrySelectedOrHovered(
        manager, entry, worldX, worldY, worldZ, renderState
    )
    local usedRects = type(renderState) == "table"
        and renderState.usedLabelRects or nil

    if detailMode == "full" then
        if not active then
            if type(drawVisionConeOnly) == 'function' then
                drawVisionConeOnly(
                    manager, zombie, debugState,
                    worldX, worldY, worldZ, isSelected
                )
            end
            if type(Renderer.BuildVisionDebugLines) == 'function' then
                local visionLines = Renderer.BuildVisionDebugLines(debugState)
                if #visionLines > 0 then
                    drawCombatText(manager, zombie, debugState, visionLines, {
                        usedLabelRects = usedRects,
                    })
                end
            end
            return
        end
        drawCombatRanges(
            manager, zombie, debugState, worldX, worldY, worldZ, isSelected
        )
        local targetDistance = drawCombatTargets(
            manager, zombie, debugState, worldX, worldY, worldZ
        )
        local lines = Renderer.BuildCombatDebugLines(debugState, targetDistance)
        appendCombatAnimationLines(lines, zombie, debugState)
        if #lines <= 0 then return end
        drawCombatText(manager, zombie, debugState, lines, {
            usedLabelRects = usedRects,
        })
        return
    end

    if type(drawVisionConeOnly) == 'function' then
        drawVisionConeOnly(
            manager, zombie, debugState, worldX, worldY, worldZ, isSelected
        )
    end
    local targetDistance = nil
    if active then
        targetDistance = drawCombatTargets(
            manager, zombie, debugState, worldX, worldY, worldZ
        )
    end

    if isSelected then
        local lines
        if active and detailMode == "compact" then
            lines = Renderer.BuildCombatDebugLines(debugState, targetDistance)
            appendCombatAnimationLines(lines, zombie, debugState)
        elseif type(Renderer.BuildCompactCombatDebugLines) == 'function' then
            lines = Renderer.BuildCompactCombatDebugLines(debugState, targetDistance)
            local visionLines = type(Renderer.BuildVisionDebugLines) == 'function'
                and Renderer.BuildVisionDebugLines(debugState) or {}
            for i = 1, #visionLines do
                lines[#lines + 1] = visionLines[i]
            end
        end
        if type(lines) == 'table' and #lines > 0 then
            drawCombatText(manager, zombie, debugState, lines, {
                usedLabelRects = usedRects,
            })
        end
        return
    end

    if detailMode == "compact"
        and type(Renderer.BuildCompactCombatDebugLines) == 'function'
    then
        local compactLines = Renderer.BuildCompactCombatDebugLines(
            debugState, targetDistance
        )
        if #compactLines > 0 then
            drawCombatText(manager, zombie, debugState, compactLines, {
                usedLabelRects = usedRects,
            })
        end
    end
end

Renderer.RenderCombatDebug = drawCombatDebug
Renderer.ResolveZombieAttacker = resolveZombieAttacker

return Renderer
