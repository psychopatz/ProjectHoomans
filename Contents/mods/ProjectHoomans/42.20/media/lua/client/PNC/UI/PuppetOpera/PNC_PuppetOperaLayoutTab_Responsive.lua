-- Responsive layout coordinator for the Puppet Opera layout editor.
--
-- Keep the public class method stable while the mode-specific geometry lives
-- in private spokes.  The metrics table is intentionally short-lived and
-- contains only scalar layout inputs, so no UI object graph is retained.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
local Layout = Internal.Layout
local resizeRows = Internal.resizeRows
local Class = ISPNCPuppetOperaLayoutTab

require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_Responsive_Stacked"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_Responsive_Wide"

function Class:onResponsiveLayout()
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    local gap = Layout.Pixels(8, scale)
    local width = self:getWidth()
    local height = self:getHeight()
    local compact = height < Layout.Pixels(430, scale)
    local actorRowHeight = Layout.Pixels(compact and 36 or 48, scale)
    local liveRowHeight = Layout.Pixels(compact and 36 or 44, scale)
    resizeRows(self.actorList, actorRowHeight)
    resizeRows(self.liveList, liveRowHeight)
    resizeRows(self.details, Layout.Pixels(25, scale))
    if self.actorList then self.actorList.uiScale = scale end
    if self.liveList then self.liveList.uiScale = scale end

    local columnsWidth = math.max(1, width - pad * 2 - gap * 2)
    local stacked = width < Layout.Pixels(720, scale)
        or columnsWidth < Layout.Pixels(430, scale)
    local metrics = {
        scale = scale,
        pad = pad,
        gap = gap,
        width = width,
        height = height,
        compact = compact,
        actorRowHeight = actorRowHeight,
        liveRowHeight = liveRowHeight,
        columnsWidth = columnsWidth,
    }
    if stacked then
        Internal.applyStackedLayout(self, metrics)
    else
        Internal.applyWideLayout(self, metrics)
    end
end

return Class
