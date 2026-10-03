local CommunityUI = PNC.CommunityDebugUI
local Model = PNC.CommunityDebugModel
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local CONTROLS = CommunityUI.Internal.Controls
local selected = CommunityUI.Internal.selected

local function text(key)
    return getText and PNC.Translation.GetKey(key) or key
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
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(27, self.uiScale),
        labelX = 10,
        labelY = 6,
        valueY = 6,
        labelWidth = 155,
        labelWidthRatio = 0.38,
        valueXOffset = 2,
        valueRightPadding = 12,
        valueMinimumWidth = 40,
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
