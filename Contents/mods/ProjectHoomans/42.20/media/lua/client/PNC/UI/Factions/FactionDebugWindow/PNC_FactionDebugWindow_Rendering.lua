-- Faction debug window visual section rendering.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local Model = Internal.Model
local ClientState = Internal.ClientState
local UI = Internal.UI
local Layout = Internal.Layout
local text = Internal.Text
function ISPNCFactionDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    if self.viewMode == "mobile" then
        local snapshot = ClientState.factionDebug or {}
        local counts = Model.BuildMobilePoolCounts(snapshot)
        local shown = #(self.mobileGroups.items or {})
        local total = Model.MobileFilterCount(counts, "all")
        local filterLabel = Model.MobileFilterLabel(self.mobileFilter)
        local selected = self:getFaction()
        local selectedFaction = selected and selected.faction or nil
        local selectedMobile = selectedFaction
            and selectedFaction.mobile or nil
        local selectedCategory = selectedMobile
            and Model.MobileCategory(
                selectedMobile, snapshot.currentPlayerFactionID)
            or nil
        UI.DrawSectionTitle(
            self,
            text("UI_PNC_FactionSectionMobile"),
            self.layout.mobile.x,
            self.layout.mobile.y - Layout.Pixels(21, self.uiScale),
            self.layout.mobile.width,
            filterLabel .. "  /  " .. tostring(shown)
                .. " shown of " .. tostring(total)
        )
        UI.DrawSectionTitle(
            self,
            text("UI_PNC_FactionSectionMobileDetails"),
            self.layout.detail.x,
            self.layout.detail.y - Layout.Pixels(21, self.uiScale),
            self.layout.detail.width,
            selectedCategory
                and Model.MobileCategoryLabel(selectedCategory)
                or "NO SELECTION"
        )
        return
    end
    UI.DrawSectionTitle(
        self, text("UI_PNC_FactionSectionPersistent"),
        self.layout.faction.x,
        self.layout.faction.y - Layout.Pixels(21, self.uiScale),
        self.layout.faction.width
    )
    UI.DrawSectionTitle(
        self, text("UI_PNC_FactionSectionTarget"),
        self.layout.target.x,
        self.layout.target.y - Layout.Pixels(21, self.uiScale),
        self.layout.target.width
    )
    UI.DrawSectionTitle(
        self, text("UI_PNC_FactionSectionNPC"),
        self.layout.npc.x,
        self.layout.npc.y - Layout.Pixels(21, self.uiScale),
        self.layout.npc.width
    )
    UI.DrawSectionTitle(
        self, text(
            "UI_PNC_FactionSection"
                .. string.upper(string.sub(
                    self.viewMode, 1, 1
                ))
                .. string.sub(self.viewMode, 2)
        ),
        self.layout.detail.x,
        self.layout.detail.y - Layout.Pixels(21, self.uiScale),
        self.layout.detail.width
    )
end
