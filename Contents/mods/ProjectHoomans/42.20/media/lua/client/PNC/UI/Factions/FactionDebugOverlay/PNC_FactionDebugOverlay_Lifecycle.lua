-- Construction and public visibility controls for the faction debug overlay.

PNC = PNC or {}
local Overlay = PNC.FactionDebugOverlay
local Internal = Overlay._Internal
local WIDTH = Internal.WIDTH
local HEIGHT = Internal.HEIGHT

function ISPNCFactionDebugOverlay:new(
    x,
    y,
    width,
    height,
    embedded
)
    local screenWidth = getCore and getCore()
        and getCore():getScreenWidth() or 1280
    local object = ISUIElement:new(
        x or math.max(8, screenWidth - WIDTH - 18),
        y or 54,
        width or WIDTH,
        height or HEIGHT
    )
    setmetatable(object, self)
    self.__index = self
    object.embedded = embedded == true
    object:setCapture(false)
    return object
end

function Overlay.IsVisible()
    return PNC.Nameplates
        and PNC.Nameplates.IsFactionDebugEnabled
        and PNC.Nameplates.IsFactionDebugEnabled()
        or false
end

function Overlay.SetSelection(sourceFactionID, targetFactionID, npcID)
    Overlay.sourceFactionID = sourceFactionID
    Overlay.targetFactionID = targetFactionID
    Overlay.npcID = npcID
    Overlay.lastRequestAt = 0
    if Overlay.IsVisible() then Overlay.Update() end
end

function Overlay.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    if PNC.Nameplates
        and PNC.Nameplates.SetFactionDebugEnabled
    then
        PNC.Nameplates.SetFactionDebugEnabled(true, true)
        Overlay.lastRequestAt = 0
        Overlay.Update()
        return true
    end
    return nil
end

function Overlay.Close()
    if PNC.Nameplates
        and PNC.Nameplates.SetFactionDebugEnabled
    then
        PNC.Nameplates.SetFactionDebugEnabled(false, true)
    end
end

function Overlay.Toggle()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return false
    end
    if PNC.Nameplates
        and PNC.Nameplates.ToggleFactionDebug
    then
        local enabled = PNC.Nameplates.ToggleFactionDebug()
        Overlay.lastRequestAt = 0
        if enabled then Overlay.Update() end
        return enabled
    end
    return false
end

function Overlay.NewDashboard(x, y, width, height)
    local dashboard = ISPNCFactionDebugOverlay:new(
        x or 0,
        y or 0,
        width or WIDTH,
        height or HEIGHT,
        true
    )
    dashboard:initialise()
    return dashboard
end

return Overlay

