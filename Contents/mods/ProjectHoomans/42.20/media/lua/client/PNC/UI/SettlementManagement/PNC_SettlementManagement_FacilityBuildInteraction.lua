-- Facility build window interaction and lifecycle.
--
-- This provider owns build confirmation, debug-material actions, snapshot
-- refresh, and the public open/reopen flow. The modal root keeps layout and
-- rendering while this module consumes its explicit BuildInternal seam.

local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"

local BuildUI = PNC.FacilityBuildUI
local Internal = BuildUI.Internal
local UI = Internal.UI
local Layout = Internal.Layout
local tr = Internal.Translate
local canUseDebug = Internal.CanUseDebug
local facilityWindowSpec = Internal.WindowSpec

function ISPNCFacilityBuildWindow:setBuildError(reason)
    reason = tostring(reason or "")
    if reason == "" then reason = "BUILD_FAILED" end
    self.buildError = tr("UI_PNC_Building_BuildFailed", "BUILD FAILED") .. ": "
        .. Shared.SettlementReason(reason)
    self:requestResponsiveLayout(true)
end


function ISPNCFacilityBuildWindow:onAction(button)
    local category = tostring(button.internal or ""):match("^category:(.+)$")
    if category then self:setCategory(category); return end
    if button.internal == "page_previous" then
        self:setCategoryPage((self.categoryPage or 1) - 1); return
    end
    if button.internal == "page_next" then
        self:setCategoryPage((self.categoryPage or 1) + 1); return
    end
    if button.internal == "debug_materials" then
        if canUseDebug() and self.selectedOption then
            local client = PNC.Client
            if client and client.RequestDebugFacilityMaterials then
                local ok = client.RequestDebugFacilityMaterials({
                    definitionId = self.selectedOption.id,
                })
                if ok ~= false then
                    self.debugMaterialsPending = true
                    self.debugMaterialsButton:setEnable(false)
                end
            end
        end
        return
    end
    if button.internal == "build" and self.selectedOption
        and self.selectedOption.enabled
    then
        local started, reason
        if self.onConfirm then
            started, reason = self.onConfirm(self.selectedOption.id)
        end
        if started == false then
            -- Never close on a rejected build. Closing here is what made the
            -- window vanish with no selector, no build and no explanation.
            self:setBuildError(reason)
            return
        end
        self.buildError = nil
        self:close()
        return
    end
    self:close()
end


function ISPNCFacilityBuildWindow:refreshFromSnapshot()
    local client = PNC.ColonyManagementClient
    if not client or type(client.ReadSnapshot) ~= "function" then return end
    local update = client.ReadSnapshot()
    local revision = tonumber(update and update.revision) or 0
    if revision <= (tonumber(self.snapshotRevision) or 0) then return end
    local snapshot = update.snapshot or {}
    local settlement = snapshot.settlement
    if not settlement then return end
    if self.settlement and self.settlement.id
        and tostring(self.settlement.id) ~= tostring(settlement.id)
    then return end

    local selectedId = self.selectedId
    local options = BuildUI.BuildOptions(settlement,
        snapshot.storage or self.storage, snapshot.research or self.research)
    local byId = {}
    for _, option in ipairs(options) do byId[option.id] = option end
    for _, card in ipairs(self.cards or {}) do
        local id = card.option and card.option.id
        card.option = id and byId[id] or card.option
    end
    self.options = options
    self.settlement = settlement
    self.storage = snapshot.storage or self.storage
    self.research = snapshot.research or self.research
    if BuildUI.lastOpenArgs then
        BuildUI.lastOpenArgs.settlement = self.settlement
        BuildUI.lastOpenArgs.storage = self.storage
        BuildUI.lastOpenArgs.research = self.research
    end
    self.snapshotRevision = revision
    self.debugMaterialsPending = false
    self:setSelected(selectedId)
    self:requestResponsiveLayout(true)
end

function BuildUI.Reopen()
    local args = BuildUI.lastOpenArgs
    if not args then return nil end
    return BuildUI.Open(args.settlement, args.onConfirm, args.storage,
        args.research, args.focusDefinitionId)
end

function BuildUI.Open(settlement, onConfirm, storage, research,
    focusDefinitionId)
    if not settlement then return nil end
    if BuildUI.instance then BuildUI.instance:close() end
    BuildUI.lastOpenArgs = {
        settlement = settlement, onConfirm = onConfirm,
        storage = storage, research = research,
        focusDefinitionId = focusDefinitionId,
    }
    local options = BuildUI.BuildOptions(settlement, storage, research)
    local spec = facilityWindowSpec()
    local bounds = Layout.ResolveWindow(spec)
    local window = ISPNCFacilityBuildWindow:new(
        bounds.x, bounds.y, bounds.width, bounds.height, {
            title = tr("UI_PNC_Facility_BuildTitle", "BUILD A BUILDING"),
            options = options, onConfirm = onConfirm,
            focusDefinitionId = focusDefinitionId,
            responsiveSpec = spec,
            -- This modal should follow the current screen instead of using a
            -- fixed geometry that can clip the build screen.
            persistenceKey = false,
            resizable = true,
            settlement = settlement, storage = storage, research = research,
            snapshotRevision = PNC.Network and PNC.Network.ClientState
                and PNC.Network.ClientState.colonyManagementRevision or 0,
            openArgs = BuildUI.lastOpenArgs,
        })
    window:initialise(); window:instantiate(); window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    window:bringToTop(); BuildUI.instance = window
    return window
end

return BuildUI

