require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.UnifiedAIDebugUI = PNC.UnifiedAIDebugUI or {}

local DebugUI = PNC.UnifiedAIDebugUI
local ClientState = PNC.Network and PNC.Network.ClientState or {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function tr(key, fallback)
    if PNC.Translation and type(PNC.Translation.GetKey) == "function" then
        local text = PNC.Translation.GetKey(key)
        if text and text ~= "" and text ~= key then
            return text
        end
    end
    return fallback
end

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function drawNPCRow(list, y, entry, alternate)
    local item = entry.item or {}
    UI.DrawListSelection(
        list, y, list.itemheight,
        list.selected == entry.index, alternate
    )
    local title = tostring(item.name or item.id or "?")
    list:drawText(
        Layout.Ellipsize(title, UIFont.Small, list:getWidth() - 14),
        7, y + 4,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a, UIFont.Small
    )
    local detail = tostring(item.id or "")
        .. " | " .. tostring(item.orderKind or "-")
        .. " | ag=" .. tostring(item.agitationStage or "calm")
    list:drawText(
        Layout.Ellipsize(detail, UIFont.Small, list:getWidth() - 14),
        7, y + 22,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small
    )
    return y + list.itemheight
end

local function addKV(window, label, value)
    window.details:addItem(label, {
        label = label,
        value = value == nil and "-" or tostring(value),
    })
end

ISPNCUnifiedAIDebugWindow =
    PsychopatzWindow:derive("ISPNCUnifiedAIDebugWindow")

function ISPNCUnifiedAIDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCUnifiedAIDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.npcs = UI.CreateList(self, {
        itemHeight = 42,
        doDrawItem = drawNPCRow,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 24,
        labelX = 8,
        labelY = 4,
        valueY = 4,
        valueX = 210,
        valueRightPadding = 8,
    })
    self.controls = {}
    local buttonDefs = {
        { "refresh", tr("UI_PNC_UnifiedAI_Action_Refresh", "REFRESH"), "quiet" },
        { "toggle_cone", tr("UI_PNC_UnifiedAI_Action_ConeOverlay", "CONE OVERLAY"), "primary" },
        { "cycle_detail_mode", tr("UI_PNC_UnifiedAI_Action_DetailMode", "OVERLAY MODE"), "quiet" },
        { "test_warn_allies", tr("UI_PNC_UnifiedAI_Action_TestWarnAllies", "TEST: WARN ALLIES"), "primary" },
        { "emit_gunfire", tr("UI_PNC_UnifiedAI_Action_Gunfire", "SHOCK: GUNFIRE"), "danger" },
        { "emit_explosion", tr("UI_PNC_UnifiedAI_Action_Explosion", "SHOCK: EXPLOSION"), "danger" },
        { "emit_weapon_aimed", tr("UI_PNC_UnifiedAI_Action_WeaponAim", "SHOCK: WEAPON AIM"), "warning" },
        { "emit_suspicious_sound", tr("UI_PNC_UnifiedAI_Action_Sound", "WORLD SOUND"), "quiet" },
        { "street_greet", tr("UI_PNC_UnifiedAI_Action_Greet", "ACT: GREET"), "success" },
        { "street_antagonize", tr("UI_PNC_UnifiedAI_Action_Taunt", "ACT: ANTAGONIZE"), "warning" },
        { "street_defuse", tr("UI_PNC_UnifiedAI_Action_Defuse", "ACT: DEFUSE"), "success" },
        { "trigger_copresence", tr("UI_PNC_UnifiedAI_Action_CoPresence", "START SCENE"), "quiet" },
        { "inject_mixin", tr("UI_PNC_UnifiedAI_Action_Mixin", "INJECT MIX-IN"), "quiet" },
        { "reevaluate_ai", tr("UI_PNC_UnifiedAI_Action_Reevaluate", "REEVALUATE"), "quiet" },
        { "clear_npc_ai", tr("UI_PNC_UnifiedAI_Action_Clear", "CLEAR NPC AI"), "danger" },
    }
    for _, definition in ipairs(buttonDefs) do
        self.controls[#self.controls + 1] = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = ISPNCUnifiedAIDebugWindow.onAction,
            variant = definition[3],
        })
    end
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCUnifiedAIDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local flow = Layout.Flow(
        self.controls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 108 }
    )
    local top = flow.bottom + 24
    local gap = 8
    local listWidth = math.max(250, math.floor(rect.width * 0.34))
    local height = math.max(120, rect.height - (top - rect.y))
    self.layout = {
        npcs = {
            x = rect.x, y = top,
            width = listWidth, height = height,
        },
        details = {
            x = rect.x + listWidth + gap, y = top,
            width = rect.width - listWidth - gap, height = height,
        },
    }
    Layout.SetBounds(
        self.npcs,
        self.layout.npcs.x, self.layout.npcs.y,
        self.layout.npcs.width, self.layout.npcs.height
    )
    Layout.SetBounds(
        self.details,
        self.layout.details.x, self.layout.details.y,
        self.layout.details.width, self.layout.details.height
    )
end

function ISPNCUnifiedAIDebugWindow:selectedNpcId()
    local row = selected(self.npcs)
    if row and row.id then return tostring(row.id) end
    local snap = ClientState.unifiedAIDebug
    return snap and snap.selectedId or nil
end

function ISPNCUnifiedAIDebugWindow:requestSnapshot(npcId)
    if not PNC.Client or not PNC.Client.RequestUnifiedAIDebug then
        return false
    end
    local ok = PNC.Client.RequestUnifiedAIDebug(npcId or self:selectedNpcId())
    self.lastRequestAt = PNC.Core.Now()
    return ok
end

function ISPNCUnifiedAIDebugWindow:refreshSnapshot()
    local snapshot = ClientState.unifiedAIDebug or {}
    local targetId = self:selectedNpcId() or snapshot.selectedId
    self.npcs:clear()
    for _, row in ipairs(snapshot.npcs or {}) do
        self.npcs:addItem(tostring(row.id or ""), row)
    end
    if targetId then
        for index, entry in ipairs(self.npcs.items or {}) do
            if entry.item and tostring(entry.item.id) == tostring(targetId) then
                self.npcs.selected = index
                break
            end
        end
    end
    if (self.npcs.selected or 0) < 1 and #self.npcs.items > 0 then
        self.npcs.selected = 1
    end
    self.lastReceiveAt = ClientState.lastUnifiedAIDebugReceiveAt
        or PNC.Core.Now()
    self:refreshDetails()
end

function ISPNCUnifiedAIDebugWindow:refreshDetails()
    local snapshot = ClientState.unifiedAIDebug or {}
    local g = snapshot.globals or {}
    local pStats = g.perceptionStats or {}
    local bStats = g.shockBusStats or {}
    local dStats = g.dialogueStats or {}
    local lStats = g.jointLeaseStats or {}
    local sel = snapshot.selected
    local combatConeOn = PNC.Nameplates
        and type(PNC.Nameplates.IsCombatDebugEnabled) == "function"
        and PNC.Nameplates.IsCombatDebugEnabled() == true

    self.details:clear()
    addKV(self, "Last Action", snapshot.lastActionStatus or "-")
    addKV(self, "Combat Cone Overlay", combatConeOn and "ON" or "OFF")
    local overlayMode = PNC.Nameplates and type(PNC.Nameplates.GetCombatDebugDetailMode) == "function"
        and tostring(PNC.Nameplates.GetCombatDebugDetailMode() or "cones") or "cones"
    addKV(self, "Combat Overlay Mode", string.upper(overlayMode))
    local globals = type(snapshot.globals) == "table" and snapshot.globals or {}
    local warnStats = type(globals.allyWarningStats) == "table" and globals.allyWarningStats or {}
    addKV(self, "Ally Warnings",
        "pub=" .. tostring(tonumber(warnStats.published) or 0)
        .. " notified=" .. tostring(tonumber(warnStats.notified) or 0)
        .. " pending=" .. tostring(tonumber(globals.pendingAllyReplies) or 0))
    local sel = type(snapshot.selected) == "table" and snapshot.selected or nil
    if sel and sel.allyWarnedBy then
        addKV(self, "Warned By", tostring(sel.allyWarnedBy)
            .. " (" .. tostring(sel.allyWarnedKind or "?") .. ")")
    end
    addKV(self, "Live NPCs / Active Claims", tostring(g.liveNpcCount or 0) .. " / " .. tostring(g.activeClaims or 0))
    addKV(self, "Perception ConeSkipped / LOS Exec", tostring(pStats.coneRejected or 0) .. " / " .. tostring(pStats.losExecuted or 0))
    addKV(self, "WorldSounds / CluesRecorded", tostring(pStats.worldSoundsProcessed or 0) .. " / " .. tostring(pStats.cluesRecorded or 0))
    addKV(self, "ShockBus Active / Emitted / Dedup", tostring(bStats.activeCount or 0) .. " / " .. tostring(bStats.emitted or 0) .. " / " .. tostring(bStats.deduplicated or 0))
    addKV(self, "Agitation Active / Work Reconcilers", tostring(g.agitationActiveCount or 0) .. " | " .. tostring(g.workReconcilers or "none"))
    addKV(self, "Dialogue Started / Aborted | Leases", tostring(dStats.started or 0) .. " / " .. tostring(dStats.aborted or 0) .. " | acq=" .. tostring(lStats.acquired or 0))

    if not sel then
        addKV(self, "Selected NPC", "None (spawn or promote an NPC first)")
        return
    end

    addKV(self, "Selected NPC", tostring(sel.name) .. " (" .. tostring(sel.id) .. ")")
    addKV(self, "Position", tostring(sel.x) .. ", " .. tostring(sel.y) .. ", z=" .. tostring(sel.z))
    addKV(self, "Task Band / Kind / Domain", tostring(sel.activeBand or "-") .. " / " .. tostring(sel.activeTaskKind or "-") .. " / " .. tostring(sel.activeSourceDomain or "-"))
    addKV(self, "Claims / Scenario / AutonomyAd", tostring(sel.claimsCount or 0) .. " | " .. tostring(sel.scenarioId or "-") .. " | " .. tostring(sel.autonomyAdId or "-"))
    addKV(self, "Autonomy Rejection", sel.autonomyTopRejection or "-")
    addKV(self, "Perception Profile", tostring(sel.perceptionProfileId or "-") .. " (FOV=" .. tostring(sel.fovDegrees or "-") .. " deg, range=" .. tostring(sel.visionRange or "-") .. "m, hear=" .. tostring(sel.hearingRange or "-") .. "m)")
    addKV(self, "Frame Clues / ConeSkipped", tostring(sel.clueCount or 0) .. " (" .. tostring(sel.latestClueKind or "none") .. ") / skipped=" .. tostring(sel.coneRejectedCount or 0))
    addKV(self, "Agitation Stage / Score / Trigger", tostring(sel.agitationStage or "calm") .. " (" .. tostring(sel.agitationScore or 0) .. ") / " .. tostring(sel.lastTrigger or "-"))
    addKV(self, "Secondary Channel", "alert=" .. tostring(sel.secondaryAlertLevel or "calm") .. " posture=" .. tostring(sel.secondaryPosture or "relaxed") .. " state=" .. tostring(sel.secondaryState or "-") .. " bark=" .. tostring(sel.lastBarkId or "-"))
    addKV(self, "Dialogue Beat / Stage / Tension", tostring(sel.dialogueBeatId or "-") .. " / " .. tostring(sel.dialogueStage or "-") .. " / " .. tostring(sel.dialogueTension or "-") .. " (joint=" .. tostring(sel.jointSceneId or "-") .. ")")
    addKV(self, "Social Memory Bank Entries", sel.socialMemoryCount or 0)
end

function ISPNCUnifiedAIDebugWindow:onAction(button)
    local id = button and button.internal or ""
    if id == "refresh" then
        self:requestSnapshot()
        return
    end
    if id == "toggle_cone" then
        if PNC.Nameplates and type(PNC.Nameplates.ToggleCombatDebug) == "function" then
            PNC.Nameplates.ToggleCombatDebug()
        end
        self:refreshDetails()
        return
    end
    if id == "cycle_detail_mode" then
        if PNC.Nameplates and type(PNC.Nameplates.CycleCombatDebugDetailMode) == "function" then
            PNC.Nameplates.CycleCombatDebugDetailMode()
        end
        self:refreshDetails()
        return
    end
    if not PNC.Client or not PNC.Client.SendDebug then return end
    PNC.Client.SendDebug("unified_ai_debug_action", {
        debugAction = id,
        npcId = self:selectedNpcId(),
    })
end

function ISPNCUnifiedAIDebugWindow:prerender()
    local received = ClientState.lastUnifiedAIDebugReceiveAt or 0
    if received > (self.lastReceiveAt or 0) then
        self:refreshSnapshot()
    end

    local row = selected(self.npcs)
    local npcId = row and row.id or nil
    if npcId ~= self.lastSelectedNpcId then
        self.lastSelectedNpcId = npcId
        self:requestSnapshot(npcId)
    end
    if PNC.Core and type(PNC.Core.Now) == "function"
        and PNC.Core.Now() - (self.lastRequestAt or 0) > 1500
    then
        self:requestSnapshot(npcId)
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCUnifiedAIDebugWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then
        UI.DrawSectionTitle(
            self, tr("UI_PNC_UnifiedAI_Section_NPCs", "LIVE NPCS"),
            self.layout.npcs.x, self.layout.npcs.y - 20,
            self.layout.npcs.width
        )
        UI.DrawSectionTitle(
            self, tr("UI_PNC_UnifiedAI_Section_Details", "UNIFIED AI & CONE TELEMETRY"),
            self.layout.details.x, self.layout.details.y - 20,
            self.layout.details.width
        )
    end
end

function ISPNCUnifiedAIDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DebugUI.instance = nil
end

function ISPNCUnifiedAIDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DebugUI.ReceiveSnapshot()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:refreshSnapshot()
    end
end

function DebugUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    local window = DebugUI.instance
    if not window then
        window = UI.NewWindow(ISPNCUnifiedAIDebugWindow, {
            title = tr("UI_PNC_UnifiedAI_Title", "UNIFIED AI & CONE DEBUG LAB"),
            resizable = true,
            persistenceKey = "PNC.UnifiedAIDebug",
            responsiveSpec = {
                width = 1140, height = 700,
                minWidth = 780, minHeight = 500,
                maxWidth = 1600, maxHeight = 1000,
            },
        })
        window:initialise()
        window:instantiate()
        DebugUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close()
        return false
    end
    return DebugUI.Open() ~= nil
end

function DebugUI.IsOpen()
    return DebugUI.instance
        and DebugUI.instance.getIsVisible
        and DebugUI.instance:getIsVisible() == true or false
end

return DebugUI
