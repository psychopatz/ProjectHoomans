PNC = PNC or {}
PNC.NameplatePresentation = PNC.NameplatePresentation or {}

local Presentation = PNC.NameplatePresentation
local DisplaySettings = PNC.NameplateDisplaySettings

Presentation.Layout = {
    barWidth = 60,
    barHeight = 6,
    barGap = 6,
    padding = 2,
    maxDrawDistance = 22,
    floorTolerance = 1,
    nameYOffset = 152,
    barYOffset = 130,
    debugTextGap = 14,
    nameDebugGap = 16,
    speechMaxCharsPerLine = 42,
    speechGap = 3,
}

Presentation.Fonts = {
    name = UIFont.Small,
    debug = UIFont.Small,
    speech = UIFont.Medium,
}

Presentation.DefaultSpeechColor = {
    r = 0.82,
    g = 0.96,
    b = 0.94,
    a = 1.0,
}


require "PNC/UI/Nameplates/PNC_NameplatePresentation_Core"
require "PNC/UI/Nameplates/PNC_NameplatePresentation_Actions"
require "PNC/UI/Nameplates/PNC_NameplatePresentation_Display"

return Presentation
