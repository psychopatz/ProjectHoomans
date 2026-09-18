-- Render coordinator for the Puppet Opera anchor grid.

PNC = PNC or {}

local Class = ISPNCPuppetOperaAnchorGrid
local Internal = PNC.PuppetOperaAnchorGridInternal or {}
PNC.PuppetOperaAnchorGridInternal = Internal

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and type(translation.GetKey) == "function"
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

Internal.tr = tr

require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnchorGrid_Presentation_Frame"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnchorGrid_Presentation_Actors"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnchorGrid_Presentation_Overlays"

function Class:render()
    ISPanel.render(self)
    local left, top, _, _, cell = self:graphBounds()
    local _, centerX, centerY = self:geometry()
    local size = 17 * cell

    Internal.drawGridFrame(self, left, top, centerX, centerY, cell, size)

    local rows = {}
    if self.model and type(self.model.GetGridActors) == "function" then
        rows = self.model.GetGridActors() or {}
    end
    if type(rows) ~= "table" then rows = {} end
    local byID = {}
    for _, row in ipairs(rows) do byID[tostring(row.id)] = row end

    Internal.drawActors(self, rows, byID, cell)
    Internal.drawOverlays(self, left, top, cell)
end

return Class
