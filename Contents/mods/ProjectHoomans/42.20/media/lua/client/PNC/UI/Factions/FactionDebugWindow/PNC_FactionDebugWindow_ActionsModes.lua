-- Faction debug window mode actions.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local ClientState = Internal.ClientState
local text = Internal.Text
function Internal.HandleModeAction(self, button, internal, faction)
    if internal == "next_scenario" then
        local names = ClientState.factionDebug
            and ClientState.factionDebug.scenarioNames or {}
        if #names > 0 then
            self.scenarioIndex =
                ((tonumber(self.scenarioIndex) or 1) % #names) + 1
            self.scenarioName = names[self.scenarioIndex]
            if button.setTitle then
                button:setTitle(
                    text("UI_PNC_FactionNextScenario")
                        .. ": " .. self.scenarioName
                )
                self:requestResponsiveLayout(true)
            end
        end
        return true
    end
    if internal == "presence_mode" then
        local modes = { "auto", "abstract", "live" }
        local nextIndex = 1
        for index, mode in ipairs(modes) do
            if mode == self.presenceMode then
                nextIndex = (index % #modes) + 1
                break
            end
        end
        self.presenceMode = modes[nextIndex]
        button:setTitle(
            text("UI_PNC_FactionPresenceMode")
                .. ": " .. self.presenceMode
        )
        self:requestResponsiveLayout(true)
        return true
    end
    if internal == "mobile_control_mode" then
        local modes = { "ambient", "strategic" }
        local nextIndex = 1
        for index, mode in ipairs(modes) do
            if mode == self.mobileControlMode then
                nextIndex = (index % #modes) + 1
                break
            end
        end
        self.mobileControlMode = modes[nextIndex]
        self.mobilePathMode = self.mobileControlMode == "strategic"
            and "player" or "random"
        button:setTitle(
            text("UI_PNC_FactionMobileControlMode")
                .. ": " .. self.mobileControlMode
        )
        if faction and faction.faction
            and faction.faction.mobile
            and faction.faction.mobile.active == true
        then
            PNC.Client.SendDebug(
                "faction_debug_action",
                {
                    factionAction = "mobile_control_mode",
                    factionID = faction.id,
                    mobileControlMode = self.mobileControlMode,
                    refreshMobileObjective = true,
                }
            )
        end
        self:requestResponsiveLayout(true)
        return true
    end
    if internal == "mobile_path_mode" then
        local modes = { "random", "player" }
        local nextIndex = 1
        for index, mode in ipairs(modes) do
            if mode == self.mobilePathMode then
                nextIndex = (index % #modes) + 1
                break
            end
        end
        self.mobilePathMode = modes[nextIndex]
        self.mobileControlMode = self.mobilePathMode == "player"
            and "strategic" or "ambient"
        button:setTitle(
            text("UI_PNC_FactionMobilePathMode")
                .. ": " .. self.mobilePathMode
        )
        if faction and faction.faction
            and faction.faction.mobile
            and faction.faction.mobile.active == true
        then
            PNC.Client.SendDebug(
                "faction_debug_action",
                {
                    factionAction = "mobile_path_mode",
                    factionID = faction.id,
                    mobilePathMode = self.mobilePathMode,
                    refreshMobileObjective = true,
                }
            )
        end
        self:requestResponsiveLayout(true)
        return true
    end
    return false
end
