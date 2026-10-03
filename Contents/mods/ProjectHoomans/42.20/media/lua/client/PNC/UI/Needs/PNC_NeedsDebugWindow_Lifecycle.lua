local NeedsUI = PNC.NeedsDebugUI

function ISPNCNeedsDebugWindow:prerender()
    local received = ClientState.lastNeedsDebugReceiveAt or 0
    if received > (self.lastReceiveAt or 0) then self:refreshSnapshot() end
    if PNC.Core.Now() - (self.lastRequestAt or 0) > 3000 then self:requestSnapshot() end
    PsychopatzWindow.prerender(self)
end
function ISPNCNeedsDebugWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then UI.DrawSectionTitle(self, (self.mode == "group" and "[ACTIVE] " or "") .. "GROUP NEEDS", self.layout.groups.x, self.layout.groups.y - 20, self.layout.groups.width); UI.DrawSectionTitle(self, (self.mode == "individual" and "[ACTIVE] " or "") .. "INDIVIDUAL NPC", self.layout.individuals.x, self.layout.individuals.y - 20, self.layout.individuals.width); UI.DrawSectionTitle(self, "DETAIL / HISTORY", self.layout.details.x, self.layout.details.y - 20, self.layout.details.width) end
end
function ISPNCNeedsDebugWindow:close() self:setVisible(false); self:removeFromUIManager(); NeedsUI.instance=nil end
function ISPNCNeedsDebugWindow:new(x,y,w,h,options) local object=PsychopatzWindow:new(x,y,w,h,options); setmetatable(object,self); self.__index=self; return object end
function NeedsUI.Open()
    if not PNC.Client.CanUseDebug() then return nil end
    local window=NeedsUI.instance
    if not window then window=UI.NewWindow(ISPNCNeedsDebugWindow,{ title="NPC NEEDS DEBUG",resizable=true,responsiveSpec={width=1100,height=680,minWidth=760,minHeight=480,maxWidth=1500,maxHeight=960} }); window:initialise(); window:instantiate(); NeedsUI.instance=window end
    window:addToUIManager(); window:setVisible(true); window:bringToTop(); window:requestSnapshot(); return window
end
function NeedsUI.Toggle() if NeedsUI.instance and NeedsUI.instance:getIsVisible() then NeedsUI.instance:close(); return false end return NeedsUI.Open() ~= nil end
