local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Presentation = PNC.NameplatePresentation
local Fonts = Presentation.Fonts
local screenPoint = Internal.ScreenPoint
local drawCombatRanges = Internal.DrawCombatRanges
local drawCombatTargets = Internal.DrawCombatTargets
local appendCombatAnimationLines = Internal.AppendCombatAnimationLines
local drawCombatText = Internal.DrawCombatText
local resolveZombieAttacker = Internal.ResolveZombieAttacker

local function drawCombatDebug(manager, entry)
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
    if not active then return end
    drawCombatRanges(manager, zombie, debugState, worldX, worldY, worldZ)
    local targetDistance = drawCombatTargets(
        manager, zombie, debugState, worldX, worldY, worldZ
    )
    local lines = Renderer.BuildCombatDebugLines(
        debugState,
        targetDistance
    )
    appendCombatAnimationLines(lines, zombie, debugState)
    if #lines <= 0 then return end
    drawCombatText(manager, zombie, debugState, lines)
end

Renderer.RenderCombatDebug = drawCombatDebug
Renderer.ResolveZombieAttacker = resolveZombieAttacker


Renderer.RenderCombatDebug = drawCombatDebug
Renderer.ResolveZombieAttacker = resolveZombieAttacker

return Renderer
