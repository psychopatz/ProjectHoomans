-- Traversal animation signals, completion checks, and engine-variable reset.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Runtime = Internal.TraversalRuntime
local TraversalQuery = PNC.TraversalQuery
local FINISHED_VARIABLE = "PNCTraversalFinished"
local KIND_VARIABLE = "PNCTraversalKind"
local PHASE_VARIABLE = "PNCTraversalPhase"

Runtime.KIND_VARIABLE = KIND_VARIABLE

local function isBumpFinished(zombie)
    local value
    if not zombie then return true end
    if zombie.getVariableBoolean
        and zombie:getVariableBoolean("BumpAnimFinished") == true
    then
        return true
    end
    if zombie.getVariableString then
        value = string.lower(tostring(
            zombie:getVariableString("BumpAnimFinished") or ""
        ))
        return value == "true" or value == "1"
    end
    return false
end

function Runtime.getTraversalPhase(zombie)
    if not zombie then return "" end
    if zombie.getVariableString then
        return string.lower(tostring(
            zombie:getVariableString(PHASE_VARIABLE) or ""
        ))
    end
    return ""
end

function Runtime.isTraversalFinished(zombie, action)
    local value
    if isBumpFinished(zombie) then return true end
    if Runtime.getTraversalPhase(zombie) == "finished" then return true end
    if not zombie or not action then return false end
    if zombie.getVariableBoolean
        and zombie:getVariableBoolean(FINISHED_VARIABLE) == true
    then
        return true
    end
    if zombie.getVariableString then
        value = string.lower(tostring(
            zombie:getVariableString(FINISHED_VARIABLE) or ""
        ))
        return value == "true" or value == "1"
    end
    return false
end

function Runtime.isFenceCrossed(zombie, action)
    local query = Internal.TraversalQuery
        or TraversalQuery
        or PNC.TraversalQuery
    if not action or action.kind ~= "fence_climb" then return true end
    if query and query.IsFenceCrossed then
        return query.IsFenceCrossed(
            zombie and zombie:getX() or nil,
            zombie and zombie:getY() or nil,
            zombie and zombie:getZ() or nil,
            action.fromSquare,
            action.toSquare
        )
    end
    if not zombie or not action.toSquare then return false end
    return math.floor(zombie:getX()) == action.toSquare:getX()
        and math.floor(zombie:getY()) == action.toSquare:getY()
        and math.floor(zombie:getZ()) == action.toSquare:getZ()
end

function Runtime.getActionStateName(zombie)
    if zombie and zombie.getActionStateName then
        return string.lower(tostring(zombie:getActionStateName() or ""))
    end
    return ""
end

function Runtime.resetTraversalVariables(zombie)
    if not zombie or not zombie.setVariable then return end
    zombie:setVariable(FINISHED_VARIABLE, false)
    zombie:setVariable(KIND_VARIABLE, "")
    zombie:setVariable(PHASE_VARIABLE, "")
end

function Runtime.resetEngineTraversalVariables(zombie, kind)
    if not zombie or not zombie.setVariable then return end
    if kind == "fence_climb" then
        zombie:setVariable("ClimbFenceStarted", false)
        zombie:setVariable("ClimbFenceFinished", true)
        zombie:setVariable("ClimbFenceOutcome", "")
    elseif kind == "window_climb" then
        zombie:setVariable("ClimbWindowStarted", false)
        zombie:setVariable("ClimbWindowOutcome", "")
    end
end
