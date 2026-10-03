local Nameplates = PNC.Nameplates
local Settings = Nameplates.Settings

local function announce(setting, enabled, onKey, offKey)
    PNC.SettingsStore:Set(setting, enabled, true)
    local player = getSpecificPlayer(0)
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(
            player,
            PNC.Translation.GetKey(enabled and onKey or offKey)
        )
    end
    return enabled
end

function Nameplates.IsNameplateDebugEnabled()
    return Settings.showNameplateDebug == true
end
Nameplates.IsDebugEnabled = Nameplates.IsNameplateDebugEnabled

function Nameplates.IsCampDebugEnabled()
    return Settings.showCampDebug == true
end
function Nameplates.ToggleCampDebug()
    Settings.showCampDebug = not Settings.showCampDebug
    return announce("showCampDebug", Settings.showCampDebug,
        "UI_PNC_CampOverlayEnabled", "UI_PNC_CampOverlayDisabled")
end

function Nameplates.ToggleNameplateDebug()
    Settings.showNameplateDebug = not Settings.showNameplateDebug
    Settings.showAIDebug = Settings.showNameplateDebug
    local enabled = Settings.showNameplateDebug
    PNC.SettingsStore:Set("showNameplateDebug", enabled, true)
    PNC.Runtime = PNC.Runtime or {}
    PNC.Runtime.nameplateDebugEnabled = enabled == true
    local player = getSpecificPlayer(0)
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, PNC.Translation.GetKey(
            enabled and "UI_PNC_NameplateDebugEnabled"
                or "UI_PNC_NameplateDebugDisabled"))
    end
    return enabled
end
Nameplates.ToggleDebug = Nameplates.ToggleNameplateDebug

function Nameplates.IsPathDebugEnabled()
    return Settings.showPathDebug == true
end
function Nameplates.TogglePathDebug()
    Settings.showPathDebug = not Settings.showPathDebug
    return announce("showPathDebug", Settings.showPathDebug,
        "UI_PNC_PathOverlayEnabled", "UI_PNC_PathOverlayDisabled")
end

function Nameplates.IsCombatDebugEnabled()
    return Settings.showCombatDebug == true
end
function Nameplates.ToggleCombatDebug()
    Settings.showCombatDebug = not Settings.showCombatDebug
    return announce("showCombatDebug", Settings.showCombatDebug,
        "UI_PNC_CombatOverlayEnabled", "UI_PNC_CombatOverlayDisabled")
end

function Nameplates.IsFactionDebugEnabled()
    return Settings.showFactionDebug == true
end
function Nameplates.SetFactionDebugEnabled(enabled, announceResult)
    Settings.showFactionDebug = enabled == true
    if announceResult ~= false then
        return announce("showFactionDebug", Settings.showFactionDebug,
            "UI_PNC_FactionOverlayEnabled", "UI_PNC_FactionOverlayDisabled")
    end
    PNC.SettingsStore:Set("showFactionDebug", Settings.showFactionDebug, true)
    return Settings.showFactionDebug
end
function Nameplates.ToggleFactionDebug()
    return Nameplates.SetFactionDebugEnabled(not Settings.showFactionDebug, true)
end

function Nameplates.IsCommunityDebugEnabled()
    return Settings.showCommunityDebug == true
end
function Nameplates.SetCommunityDebugEnabled(enabled, announceResult)
    Settings.showCommunityDebug = enabled == true
    if announceResult ~= false then
        return announce("showCommunityDebug", Settings.showCommunityDebug,
            "UI_PNC_CommunityOverlayEnabled",
            "UI_PNC_CommunityOverlayDisabled")
    end
    PNC.SettingsStore:Set("showCommunityDebug", Settings.showCommunityDebug, true)
    return Settings.showCommunityDebug
end
function Nameplates.ToggleCommunityDebug()
    return Nameplates.SetCommunityDebugEnabled(
        not Settings.showCommunityDebug, true)
end

function Nameplates.IsZombieDebugEnabled()
    return Settings.showZombieDebug == true
end
function Nameplates.ToggleZombieDebug()
    Settings.showZombieDebug = not Settings.showZombieDebug
    local player = getSpecificPlayer(0)
    PNC.SettingsStore:Set("showZombieDebug", Settings.showZombieDebug, true)
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, Settings.showZombieDebug
            and "PNC zombie AI overlay enabled"
            or "PNC zombie AI overlay disabled")
    end
    return Settings.showZombieDebug
end

function Nameplates.IsAnimationDebugEnabled()
    return Settings.showAnimationDebug == true
end
function Nameplates.ToggleAnimationDebug()
    Settings.showAnimationDebug = not Settings.showAnimationDebug
    local enabled = Settings.showAnimationDebug
    PNC.SettingsStore:Set("showAnimationDebug", enabled, true)
    local player = getSpecificPlayer(0)
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, enabled
            and "PNC animation tracks enabled"
            or "PNC animation tracks disabled")
    end
    return enabled
end

function Nameplates.IsAnimationSceneDebugEnabled()
    return Settings.showAnimationSceneDebug == true
end
function Nameplates.ToggleAnimationSceneDebug()
    Settings.showAnimationSceneDebug = not Settings.showAnimationSceneDebug
    local enabled = Settings.showAnimationSceneDebug
    PNC.SettingsStore:Set("showAnimationSceneDebug", enabled, true)
    local player = getSpecificPlayer(0)
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, enabled
            and "PNC scene overlay enabled"
            or "PNC scene overlay disabled")
    end
    return enabled
end

function Nameplates.ToggleOverlay(id)
    id = tostring(id or "")
    if id == "ai" or id == "nameplate_debug" then
        return Nameplates.ToggleNameplateDebug()
    elseif id == "camp" then return Nameplates.ToggleCampDebug()
    elseif id == "path" then return Nameplates.TogglePathDebug()
    elseif id == "combat" then return Nameplates.ToggleCombatDebug()
    elseif id == "zombie" then return Nameplates.ToggleZombieDebug()
    elseif id == "animation" then return Nameplates.ToggleAnimationDebug()
    elseif id == "scenes" then return Nameplates.ToggleAnimationSceneDebug()
    elseif id == "faction" then return Nameplates.ToggleFactionDebug()
    elseif id == "community" then return Nameplates.ToggleCommunityDebug()
    end
    return nil
end

function Nameplates.DebugDescribeSnapshot(snapshot)
    return PNC.NameplateDebug.DescribeSnapshot(snapshot)
end
