--[[
    Authored incapacitated-state flavor -- shared header and helpers.

    Loaded before both halves of the matrix.  Keeps the doc block, the `cell`
    and `line` helpers, and the registry guard in one place so the call and
    update definition files stay small and single-purpose.
]]

PNC = PNC or {}
PNC.SocialFlavorDefinitions = PNC.SocialFlavorDefinitions or {}

local Flavor = PsychopatzCore and PsychopatzCore.SocialFlavor
if not Flavor then return PNC.SocialFlavorDefinitions end

local Const = PNC.FlavorTextConst or {}

-- Helper: build the `when` table for one audience/need/threat cell.  Omitted
-- fields are simply not matched, which is what produces the fallback ladder.
local function cell(audience, need, threat)
    local when = {}
    if audience then when.downedAudience = audience end
    if need then when.downedNeed = need end
    if threat then when.downedThreat = threat end
    return when
end

-- Shared address tokens available to every line.
--   {playerFirstName} the listener's name, {name} the downed NPC's own name
--   {attackerName} the named hostile, when one is known
local function line(key, fallback)
    return { key = key, fallback = fallback }
end

PNC.SocialFlavorDefinitions.Incapacitated = {
    cell = cell,
    line = line,
    Flavor = Flavor,
    Const = Const,
}

return PNC.SocialFlavorDefinitions.Incapacitated
