-- Shared AnimSet variable adapter for `anim_vars` tracks.
--
-- Drives continuous, phase-locked animations on both `IsoZombie` NPCs and
-- `IsoPlayer` characters using canonical `PNC_Anim*` AnimSet variables with
-- guaranteed cleanup.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.AnimVarAdapter = PNC.PuppetOpera.AnimVarAdapter or {}

local Adapter = PNC.PuppetOpera.AnimVarAdapter

local MANAGED_VARS = {
    "PNC_AnimActive",
    "PNC_AnimStyle",
    "PNC_AnimRole",
    "PNC_AnimPhase",
    "PNC_AnimMoving",
    "PNC_AnimProgress",
}

local function setVar(body, name, value)
    if not body or not body.setVariable then return false end
    body:setVariable(tostring(name), value)
    return true
end

local function clearVar(body, name)
    if not body then return false end
    if body.clearVariable then
        body:clearVariable(tostring(name))
        return true
    end
    if body.setVariable then
        body:setVariable(tostring(name), "")
        return true
    end
    return false
end

function Adapter.Apply(body, track, options)
    if not body or type(track) ~= "table" then
        return false, "anim_vars_arguments_invalid"
    end
    options = type(options) == "table" and options or {}
    local style = tostring(track.style or track.anim or "custom")
    local role = tostring(track.role or "Actor")
    local phase = tostring(track.phase or options.phase or "play")
    local moving = options.moving == true
    local progress = tonumber(options.progress) or 0
    setVar(body, "PNC_AnimActive", true)
    setVar(body, "PNC_AnimStyle", style)
    setVar(body, "PNC_AnimRole", role)
    setVar(body, "PNC_AnimPhase", phase)
    setVar(body, "PNC_AnimMoving", moving)
    setVar(body, "PNC_AnimProgress", progress)
    if type(track.variables) == "table" then
        for _, entry in ipairs(track.variables) do
            if type(entry) == "table" and entry.name then
                setVar(body, entry.name, entry.value)
            end
        end
    end
    return true, "anim_vars_applied"
end

function Adapter.UpdateProgress(body, progress, moving)
    if not body then return false end
    if progress ~= nil then
        setVar(body, "PNC_AnimProgress", tonumber(progress) or 0)
    end
    if moving ~= nil then
        setVar(body, "PNC_AnimMoving", moving == true)
    end
    return true
end

function Adapter.Clear(body, track)
    if not body then return false end
    for _, name in ipairs(MANAGED_VARS) do
        clearVar(body, name)
    end
    if type(track) == "table" and type(track.variables) == "table" then
        for _, entry in ipairs(track.variables) do
            if type(entry) == "table" and entry.name then
                clearVar(body, entry.name)
            end
        end
    end
    return true
end

return Adapter
