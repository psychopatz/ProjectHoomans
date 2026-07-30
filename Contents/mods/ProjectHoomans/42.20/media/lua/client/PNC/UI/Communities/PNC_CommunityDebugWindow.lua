require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Communities/PNC_CommunityDebugModel"
require "PNC/UI/Communities/PNC_CommunityDebugOverlay"

PNC.CommunityDebugUI = PNC.CommunityDebugUI or {}

local CommunityUI = PNC.CommunityDebugUI
local Model = PNC.CommunityDebugModel
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function text(key)
    return getText and getText(key) or key
end

local CONTROLS = {
    { id = "refresh", key = "UI_PNC_MonitorRefresh", variant = "quiet" },
    { id = "overlay", key = "UI_PNC_CommunityToggleOverlay", variant = "quiet" },
    { id = "create_settlement", key = "UI_PNC_CommunityCreateSettlement", variant = "success" },
    { id = "create_camp", key = "UI_PNC_CommunityCreateCamp", variant = "success" },
    { id = "assign", key = "UI_PNC_CommunityAssignNPC", variant = "success" },
    { id = "transfer", key = "UI_PNC_CommunityTransferNPC", variant = "default" },
    { id = "remove", key = "UI_PNC_CommunityRemoveNPC", variant = "danger" },
    { id = "leader", key = "UI_PNC_CommunitySetLeader", variant = "default" },
    { id = "role", key = "UI_PNC_CommunityNextRole", variant = "quiet" },
    { id = "set_home_to_npc", key = "UI_PNC_CommunitySetHome", variant = "quiet" },
    { id = "security_down", key = "UI_PNC_CommunitySecurityDown", variant = "quiet" },
    { id = "security_up", key = "UI_PNC_CommunitySecurityUp", variant = "quiet" },
    { id = "morale_down", key = "UI_PNC_CommunityMoraleDown", variant = "quiet" },
    { id = "morale_up", key = "UI_PNC_CommunityMoraleUp", variant = "quiet" },
    { id = "supply_add", key = "UI_PNC_CommunityAddSupply", variant = "success" },
    { id = "supply_remove", key = "UI_PNC_CommunityRemoveSupply", variant = "danger" },
    { id = "next_supply", key = "UI_PNC_CommunityNextSupply", variant = "quiet" },
    { id = "validate", key = "UI_PNC_CommunityValidate", variant = "quiet" },
    { id = "repair_indexes", key = "UI_PNC_CommunityRepair", variant = "danger" },
    { id = "archive", key = "UI_PNC_CommunityArchive", variant = "danger" },
    { id = "destroy", key = "UI_PNC_CommunityDestroy", variant = "danger" },
}

local function drawEntity(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(
        list,
        y,
        list.itemheight,
        list.selected == entry.index,
        alternate
    )
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(
        Layout.Ellipsize(
            item.label,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 5,
        color.r, color.g, color.b, color.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.detail or item.id,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 24,
        muted.r, muted.g, muted.b, muted.a,
        UIFont.Small
    )
    return y + list.itemheight
end

local function drawDetail(list, y, entry, alternate)
    local item = entry.item
    local muted = Theme.colors.textMuted
    local color = Theme.colors[item.tone or "text"]
        or Theme.colors.text
    local labelWidth = math.min(
        155,
        math.floor(list:getWidth() * 0.38)
    )
    UI.DrawListSelection(
        list, y, list.itemheight, false, alternate
    )
    list:drawText(
        item.label,
        10, y + 6,
        muted.r, muted.g, muted.b, muted.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.value,
            UIFont.Small,
            math.max(40, list:getWidth() - labelWidth - 24)
        ),
        12 + labelWidth, y + 6,
        color.r, color.g, color.b, color.a,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCCommunityDebugWindow =
    PsychopatzWindow:derive("ISPNCCommunityDebugWindow")

function ISPNCCommunityDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCCommunityDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.communities = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.factions = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.npcs = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.details = UI.CreateList(self, {
        itemHeight = Layout.Pixels(27, self.uiScale),
        doDrawItem = drawDetail,
    })
    self.controls = {}
    self.roleIndex = 1
    self.supplyIndex = 1
    for _, definition in ipairs(CONTROLS) do
        self.controls[#self.controls + 1] =
            UI.CreateButton(self, {
                id = definition.id,
                title = text(definition.key),
                target = self,
                onclick =
                    ISPNCCommunityDebugWindow.onAction,
                variant = definition.variant,
            })
    end
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCCommunityDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({
        top = 28,
        bottom = 12,
    })
    local flow = Layout.Flow(
        self.controls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 78 }
    )
    local top = flow.bottom
        + Layout.Pixels(25, self.uiScale)
    local height = math.max(
        100,
        rect.y + rect.height - top
    )
    local gap = Layout.Pixels(8, self.uiScale)
    local listWidth = math.max(
        145,
        math.floor((rect.width - gap * 3) * 0.19)
    )
    self.layout = {
        community = {
            x = rect.x, y = top,
            width = listWidth, height = height,
        },
        faction = {
            x = rect.x + listWidth + gap, y = top,
            width = listWidth, height = height,
        },
        npc = {
            x = rect.x + listWidth * 2 + gap * 2,
            y = top, width = listWidth, height = height,
        },
        detail = {
            x = rect.x + listWidth * 3 + gap * 3,
            y = top,
            width = rect.width - listWidth * 3 - gap * 3,
            height = height,
        },
    }
    for widget, bounds in pairs({
        [self.communities] = self.layout.community,
        [self.factions] = self.layout.faction,
        [self.npcs] = self.layout.npc,
        [self.details] = self.layout.detail,
    }) do
        Layout.SetBounds(
            widget,
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height
        )
    end
end

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function restore(list, id)
    if not id then return end
    for index, entry in ipairs(list.items or {}) do
        if entry.item and entry.item.id == id then
            list.selected = index
            return
        end
    end
end

function ISPNCCommunityDebugWindow:requestSnapshot()
    local community = selected(self.communities)
    local faction = selected(self.factions)
    local npc = selected(self.npcs)
    PNC.Client.RequestCommunityDebug(
        community and community.id,
        faction and faction.id,
        npc and npc.id
    )
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCCommunityDebugWindow:refreshSnapshot()
    local oldCommunity = selected(self.communities)
    local oldFaction = selected(self.factions)
    local oldNPC = selected(self.npcs)
    local snapshot = ClientState.communityDebug
    self.communities:clear()
    for _, item in ipairs(
        Model.BuildCommunityItems(snapshot)
    ) do
        self.communities:addItem(item.label, item)
    end
    restore(
        self.communities,
        snapshot and snapshot.selectedCommunity
            and snapshot.selectedCommunity.id
            or oldCommunity and oldCommunity.id
    )
    if #self.communities.items > 0
        and (tonumber(self.communities.selected) or 0) < 1
    then
        self.communities.selected = 1
    end
    self.factions:clear()
    for _, item in ipairs(Model.BuildFactionItems(snapshot)) do
        self.factions:addItem(item.label, item)
    end
    restore(
        self.factions,
        snapshot and snapshot.selectedFactionID
            or oldFaction and oldFaction.id
    )
    if #self.factions.items > 0
        and (tonumber(self.factions.selected) or 0) < 1
    then
        self.factions.selected = 1
    end
    self.npcs:clear()
    for _, item in ipairs(Model.BuildNPCItems(snapshot)) do
        self.npcs:addItem(item.label, item)
    end
    restore(
        self.npcs,
        snapshot and snapshot.selectedNPC
            and snapshot.selectedNPC.id
            or oldNPC and oldNPC.id
    )
    if #self.npcs.items > 0
        and (tonumber(self.npcs.selected) or 0) < 1
    then
        self.npcs.selected = 1
    end
    self.details:clear()
    for _, item in ipairs(Model.BuildRows(
        snapshot,
        ClientState.communityDebugAuthorized,
        ClientState.communityDebugReason
    )) do
        self.details:addItem(item.label, item)
    end
    self.lastReceiveAt = tonumber(
        ClientState.lastCommunityDebugReceiveAt
    ) or PNC.Core.Now()
end

function ISPNCCommunityDebugWindow:onAction(button)
    local internal = button.internal
    local community = selected(self.communities)
    local faction = selected(self.factions)
    local npc = selected(self.npcs)
    if internal == "refresh" then
        self:requestSnapshot()
        return
    end
    if internal == "overlay" then
        PNC.CommunityDebugOverlay.Toggle()
        return
    end
    local snapshot = ClientState.communityDebug or {}
    if internal == "next_supply" then
        local values = snapshot.supplyCategories or {}
        if #values > 0 then
            self.supplyIndex =
                ((self.supplyIndex or 1) % #values) + 1
            button:setTitle(
                text("UI_PNC_CommunityNextSupply")
                    .. ": " .. values[self.supplyIndex]
            )
            self:requestResponsiveLayout(true)
        end
        return
    end
    local payload = {
        communityAction = internal,
        communityID = community and community.id,
        factionID = faction and faction.id,
        npcID = npc and npc.id,
    }
    if internal == "security_down" then
        payload.communityAction = "security"
        payload.delta = -5
    elseif internal == "security_up" then
        payload.communityAction = "security"
        payload.delta = 5
    elseif internal == "morale_down" then
        payload.communityAction = "morale"
        payload.delta = -5
    elseif internal == "morale_up" then
        payload.communityAction = "morale"
        payload.delta = 5
    elseif internal == "supply_add"
        or internal == "supply_remove"
    then
        payload.category = (
            snapshot.supplyCategories or {}
        )[self.supplyIndex or 1] or "food"
        payload.amount = 5
    elseif internal == "role" then
        local roles = snapshot.communityRoles or {}
        if #roles > 0 then
            self.roleIndex =
                ((self.roleIndex or 1) % #roles) + 1
            payload.communityRole = roles[self.roleIndex]
        end
    elseif internal == "assign"
        or internal == "transfer"
    then
        local roles = snapshot.communityRoles or {}
        payload.communityRole =
            roles[self.roleIndex or 1] or "resident"
    end
    PNC.Client.SendDebug(
        "community_debug_action",
        payload
    )
end

function ISPNCCommunityDebugWindow:selectionSignature()
    local community = selected(self.communities)
    local faction = selected(self.factions)
    local npc = selected(self.npcs)
    return tostring(community and community.id or "")
        .. "|" .. tostring(faction and faction.id or "")
        .. "|" .. tostring(npc and npc.id or "")
end

function ISPNCCommunityDebugWindow:prerender()
    local now = PNC.Core.Now()
    local received = tonumber(
        ClientState.lastCommunityDebugReceiveAt
    ) or 0
    local signature = self:selectionSignature()
    if received > (tonumber(self.lastReceiveAt) or 0) then
        self:refreshSnapshot()
        signature = self:selectionSignature()
    end
    if signature ~= self.requestedSignature then
        self.requestedSignature = signature
        self:requestSnapshot()
    elseif now - (tonumber(self.lastRequestAt) or 0)
        > 2500
    then
        self:requestSnapshot()
    end
    local community = selected(self.communities)
    local faction = selected(self.factions)
    local npc = selected(self.npcs)
    local selectedCommunity = community
        and community.community or nil
    local npcValue = npc and npc.npc or nil
    for index, button in ipairs(self.controls) do
        local internal = CONTROLS[index].id
        local enabled = internal == "refresh"
            or internal == "overlay"
            or internal == "validate"
            or internal == "repair_indexes"
            or internal == "next_supply"
        if internal == "create_settlement"
            or internal == "create_camp"
        then
            enabled = faction ~= nil
        elseif internal == "assign" then
            enabled = selectedCommunity ~= nil
                and npcValue ~= nil
                and npcValue.factionID
                    == selectedCommunity.factionID
                and npcValue.communityID == nil
        elseif internal == "transfer" then
            enabled = selectedCommunity ~= nil
                and npcValue ~= nil
                and npcValue.factionID
                    == selectedCommunity.factionID
                and npcValue.communityID ~= nil
                and npcValue.communityID
                    ~= selectedCommunity.id
        elseif internal == "remove"
            or internal == "leader"
            or internal == "role"
        then
            enabled = selectedCommunity ~= nil
                and npcValue ~= nil
                and npcValue.communityID
                    == selectedCommunity.id
        elseif internal == "set_home_to_npc" then
            enabled = selectedCommunity ~= nil
                and npcValue ~= nil
        elseif internal == "security_down"
            or internal == "security_up"
            or internal == "morale_down"
            or internal == "morale_up"
            or internal == "supply_add"
            or internal == "supply_remove"
            or internal == "archive"
            or internal == "destroy"
        then
            enabled = selectedCommunity ~= nil
        end
        button:setEnable(enabled)
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCCommunityDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    UI.DrawSectionTitle(
        self,
        text("UI_PNC_CommunitySectionCommunities"),
        self.layout.community.x,
        self.layout.community.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.community.width
    )
    UI.DrawSectionTitle(
        self,
        text("UI_PNC_CommunitySectionFactions"),
        self.layout.faction.x,
        self.layout.faction.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.faction.width
    )
    UI.DrawSectionTitle(
        self,
        text("UI_PNC_CommunitySectionNPCs"),
        self.layout.npc.x,
        self.layout.npc.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.npc.width
    )
    UI.DrawSectionTitle(
        self,
        text("UI_PNC_CommunitySectionDetails"),
        self.layout.detail.x,
        self.layout.detail.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.detail.width
    )
end

function ISPNCCommunityDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    CommunityUI.instance = nil
end

function ISPNCCommunityDebugWindow:new(
    x,
    y,
    width,
    height,
    options
)
    local object = PsychopatzWindow:new(
        x, y, width, height, options
    )
    setmetatable(object, self)
    self.__index = self
    return object
end

function CommunityUI.Open()
    local window = CommunityUI.instance
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    if not window then
        local screenWidth = getCore and getCore()
            and getCore():getScreenWidth() or 1280
        local screenHeight = getCore and getCore()
            and getCore():getScreenHeight() or 800
        window = UI.NewWindow(ISPNCCommunityDebugWindow, {
            title = text("UI_PNC_CommunityInspectorTitle"),
            resizable = true,
            responsiveSpec = {
                width = math.min(1280, screenWidth - 24),
                height = math.min(800, screenHeight - 40),
                minWidth = 820,
                minHeight = 540,
                maxWidth = 1500,
                maxHeight = 960,
            },
        })
        window:initialise()
        window:instantiate()
        CommunityUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function CommunityUI.Toggle()
    if CommunityUI.instance
        and CommunityUI.instance:getIsVisible()
    then
        CommunityUI.instance:close()
        return false
    end
    return CommunityUI.Open() ~= nil
end

return CommunityUI
