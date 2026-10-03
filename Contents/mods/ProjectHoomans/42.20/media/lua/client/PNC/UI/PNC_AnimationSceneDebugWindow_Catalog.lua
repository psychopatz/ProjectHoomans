-- Animation-scene debug catalog and target provider.

PNC = PNC or {}
PNC.AnimationSceneDebugWindow = PNC.AnimationSceneDebugWindow or {}
local WindowAPI = PNC.AnimationSceneDebugWindow
local Model = PNC.AnimationSceneDebugModel
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

function ISPNCAnimationSceneDebugWindow:setTarget(entry)
    entry = entry or {}
    self.contextEntry = entry
    self.npcId = tostring(entry.id or "")
    self.npcName = tostring(
        entry.name
            or entry.record and entry.record.name
            or self.npcId
    )
    self.body = entry.zombie
    self.record = entry.record or entry.snapshot
    local title = "NPC Scene Lab — " .. self.npcName
    if self.setTitle then self:setTitle(title)
    else self.title = title end
    self:refreshDetails(true)
end

function ISPNCAnimationSceneDebugWindow:refreshGroups()
    local previous = self:selectedGroup()
    local previousKey = previous and previous.key or "all"
    self.groups = Model.GetGroups()
    self.groupFilter:clear()
    self.groupFilter.selected = 1
    for index, group in ipairs(self.groups) do
        self.groupFilter:addOption(group.label)
        if group.key == previousKey then
            self.groupFilter.selected = index
        end
    end
end

function ISPNCAnimationSceneDebugWindow:selectedGroup()
    return self.groups
        and self.groups[
            tonumber(self.groupFilter.selected) or 1
        ] or nil
end

function ISPNCAnimationSceneDebugWindow:onGroupChanged()
    self:refreshCatalog()
end

function ISPNCAnimationSceneDebugWindow:getSelectedScene()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function ISPNCAnimationSceneDebugWindow:refreshCatalog()
    if not self.list then return end
    local previous = self:getSelectedScene()
    local previousId = previous and previous.id or nil
    self.totalCount = #PNC.AnimationScenes.List()
    local scenes = Model.GetScenes(
        self.search and self.search:getText() or "",
        self:selectedGroup()
    )
    self.list:clear()
    for _, scene in ipairs(scenes) do
        self.list:addItem(scene.id, scene)
        if scene.id == previousId then
            self.list.selected = #self.list.items
        end
    end
    if #self.list.items > 0
        and (tonumber(self.list.selected) or 0) < 1
    then
        self.list.selected = 1
    end
    self.visibleCount = #self.list.items
    self:refreshDetails(true)
end

function ISPNCAnimationSceneDebugWindow:resolveBody()
    if self.body
        and (not self.body.isDead
            or self.body:isDead() ~= true)
    then
        return self.body
    end
    local sync = PNC.ClientPresenceSync
    self.body = sync
        and sync.BodyByID
        and sync.BodyByID[self.npcId] or nil
    return self.body
end

return WindowAPI
