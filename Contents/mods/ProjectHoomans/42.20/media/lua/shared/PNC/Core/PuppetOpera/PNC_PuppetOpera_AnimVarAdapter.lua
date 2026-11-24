-- Shared AnimSet variable adapter for Puppet Opera `anim_vars` tracks.
--
-- Drives continuous, phase-locked animations on both `IsoZombie` NPCs and
-- `IsoPlayer` characters using `PNC_Opera*` AnimSet variables, mirroring the
-- proven non-grapple pattern from SilesCarryB42 with guaranteed cleanup.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.AnimVarAdapter = PNC.PuppetOpera.AnimVarAdapter or {}

local Adapter = PNC.PuppetOpera.AnimVarAdapter

local MANAGED_VARS = {
    "PNC_OperaActive",
    "PNC_OperaStyle",
    "PNC_OperaRole",
    "PNC_OperaPhase",
    "PNC_OperaMoving",
    "PNC_OperaProgress",
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
    setVar(body, "PNC_OperaActive", true)
    setVar(body, "PNC_OperaStyle", tostring(track.style or track.anim or "custom"))
    setVar(body, "PNC_OperaRole", tostring(track.role or "Actor"))
    setVar(body, "PNC_OperaPhase", tostring(track.phase or options.phase or "play"))
    setVar(body, "PNC_OperaMoving", options.moving == true)
    setVar(body, "PNC_OperaProgress", tonumber(options.progress) or 0)
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
        setVar(body, "PNC_OperaProgress", tonumber(progress) or 0)
    end
    if moving ~= nil then
        setVar(body, "PNC_OperaMoving", moving == true)
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
