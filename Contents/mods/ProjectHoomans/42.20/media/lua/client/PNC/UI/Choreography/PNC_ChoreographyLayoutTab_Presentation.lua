-- Header rendering coordinator for the Puppet Opera layout editor.

PNC = PNC or {}

local Internal = PNC.ChoreographyLayoutTabInternal
local Layout = Internal.Layout
local tr
local Class = ISPNCChoreographyLayoutTab

require "PNC/UI/Choreography/PNC_ChoreographyLayoutTab_Presentation_Rows"
tr = Internal.tr

function Class:render()
    ISPanel.render(self)
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    self:drawText(
        tr("UI_PNC_Choreography_SceneActors", "Scene actors"),
        pad,
        2,
        0.82,
        0.88,
        0.94,
        1,
        UIFont.Small
    )
    self:drawText(
        tr("UI_PNC_Choreography_LiveActors", "Nearby live actors"),
        pad,
        self.liveList and self.liveList:getY() - Layout.Pixels(18, scale) or 0,
        0.82,
        0.88,
        0.94,
        1,
        UIFont.Small
    )
end

return Class
