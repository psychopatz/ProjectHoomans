-- Runtime/editor status rendering for the Puppet Opera window.

PNC = PNC or {}

local Internal = PNC.PuppetOperaDebugWindow.Internal
local Layout = Internal.Layout
local Class = ISPNCPuppetOperaDebugWindow
local tr = Internal.tr

function Class:render()
    PsychopatzWindow.render(self)
    local Client = Internal.Client
    local status, runtimeError = Client.GetStatus()
    local editorMessage = self.editorStatus
        or (Internal.Model.GetEditorStatus
            and Internal.Model.GetEditorStatus())
        or nil
    local runtimeLabel = tr("UI_PNC_PuppetOpera_RuntimeStatus", "runtime")
    local editorLabel = tr("UI_PNC_PuppetOpera_EditorStatus", "editor")
    local message = runtimeLabel .. "=" .. tostring(status)
        .. (runtimeError and " " .. tostring(runtimeError) or "")
    if editorMessage then
        message = message .. " | " .. editorLabel .. "="
            .. tostring(editorMessage)
    end
    local statusY = self.showDescription and (self.descriptionY or 34)
        or math.max(1, (self.actionY or self:getHeight()) - 16)
    if self.showDescription then
        local description = Layout.Ellipsize(Internal.TEXT_DESCRIPTION, UIFont.Small,
            math.floor(self:getWidth() * 0.54))
        self:drawText(
            description,
            12, self.descriptionY or 34,
            0.62, 0.76, 0.84, 1,
            UIFont.Small
        )
    end
    self:drawTextRight(
        Layout.Ellipsize(message, UIFont.Small,
            math.floor(self:getWidth() * 0.42)),
        self:getWidth() - 12,
        statusY,
        runtimeError and 1.00 or editorMessage and 1.00 or 0.72,
        runtimeError and 0.55 or editorMessage and 0.55 or 0.78,
        runtimeError and 0.55 or editorMessage and 0.55 or 0.84,
        1,
        UIFont.Small
    )
end

return Class
