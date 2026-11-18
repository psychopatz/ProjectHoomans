local Stubble = {}
local maleHair = "Base.M_Hair_Stubble"
local femaleHair = "Base.F_Hair_Stubble"
local beard = "Base.M_Beard_Stubble"

local function setVisual(visual, item, enabled)
    if visual:hasBodyVisualFromItemType(item) == enabled then return end
    if enabled then
        visual:addBodyVisualFromItemType(item)
    else
        visual:removeBodyVisualFromItemType(item)
    end
end

function Stubble.Apply(visual, appearance, female)
    if not visual.hasBodyVisualFromItemType or not visual.addBodyVisualFromItemType
        or not visual.removeBodyVisualFromItemType then return end
    local hair = appearance.hairStubble == true
    setVisual(visual, maleHair, hair and not female)
    setVisual(visual, femaleHair, hair and female)
    setVisual(visual, beard, not female and appearance.beardStubble == true)
end

function Stubble.Matches(visual, appearance, female)
    if not visual.hasBodyVisualFromItemType then return true end
    local hair = appearance.hairStubble == true
    return visual:hasBodyVisualFromItemType(maleHair) == (hair and not female)
        and visual:hasBodyVisualFromItemType(femaleHair) == (hair and female)
        and visual:hasBodyVisualFromItemType(beard) == (not female and appearance.beardStubble == true)
end

return Stubble
