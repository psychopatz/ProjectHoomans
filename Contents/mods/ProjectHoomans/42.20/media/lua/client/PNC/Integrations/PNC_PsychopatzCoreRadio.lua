-- Requiring the host here makes the integration deterministic even when the
-- engine's automatic client-file order changes between Build 42 revisions.
require "PsychopatzCore/UI/Radio/PsychopatzRadioSignalHost"
require "PsychopatzCore/Radio/PsychopatzCustomRadioClient"

PNC = PNC or {}

local RadioActions = PsychopatzCore and PsychopatzCore.RadioActions
local CustomRadio = PsychopatzCore and PsychopatzCore.CustomRadio
local ScanChannel = PNC.RadioDiscoveryChannel
local lastProbeAt = {}
local PROBE_INTERVAL_MS = 40000

PNC.RadioDiscoveryPresentation = PNC.RadioDiscoveryPresentation or {}
local Presentation = PNC.RadioDiscoveryPresentation
Presentation.lastNotificationID = Presentation.lastNotificationID or nil

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function noticeKey(result)
    if (tonumber(result.phase) or 0) >= 2 then
        return result.kind == "settlement"
            and "UI_PNC_DiscoveryLocatedSettlement"
            or "UI_PNC_DiscoveryLocatedMobileGroup"
    end
    if result.kind == "settlement" then
        return "UI_PNC_DiscoveryFoundSettlement"
    end
    local groupType = string.upper(tostring(result.groupType or ""))
    if groupType == "REFUGEE" then
        return "UI_PNC_DiscoveryFoundRefugees"
    elseif groupType == "LOOTER" then
        return "UI_PNC_DiscoveryFoundLooters"
    elseif groupType == "TRADER" then
        return "UI_PNC_DiscoveryFoundTraders"
    end
    return "UI_PNC_DiscoveryFoundMobileGroup"
end

function Presentation.ShowResult(payload)
    local result = payload and payload.result
    local notificationID = result and tostring(result.notificationID or "")
    if not result or result.ok ~= true or notificationID == ""
        or notificationID == Presentation.lastNotificationID
    then return false end
    Presentation.lastNotificationID = notificationID
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not HaloTextHelper
        or not HaloTextHelper.addTextWithArrow
    then return false end
    local key = noticeKey(result)
    HaloTextHelper.addTextWithArrow(
        player, tr(key, "Radio signal discovered"), true,
        HaloTextHelper.getColorGreen()
    )
    if result.identityRevealed == true then
        HaloTextHelper.addTextWithArrow(
            player,
            tr("UI_PNC_DiscoveryIdentityLearned", "Radio contact identified"),
            true, HaloTextHelper.getColorGreen()
        )
    end
    return true
end

if CustomRadio and CustomRadio.RegisterListener and ScanChannel then
    CustomRadio.RegisterListener(ScanChannel.ID,
        "projecthoomans.discovery", function(context)
            local player = context and context.player
            local key = player and player.getUsername
                and tostring(player:getUsername())
                or tostring(context and context.playerNum or 0)
            local at = tonumber(context and context.now) or PNC.Core.Now()
            local previous = lastProbeAt[key]
            if previous and at - previous < PROBE_INTERVAL_MS then return true end
            lastProbeAt[key] = at
            if PNC.Client and PNC.Client.RequestWorldDiscovery then
                PNC.Client.RequestWorldDiscovery("radio_scan", {
                    channelID = ScanChannel.ID,
                    frequency = ScanChannel.FREQUENCY,
                })
            end
            return true
        end)
end

if RadioActions and RadioActions.Register then
    RadioActions.Register({
        id = "projecthoomans.contacts",
        label = tr("UI_PNC_Contacts", "Contacts"),
        signalLabel = tr("UI_PNC_Contacts", "Contacts"),
        placement = RadioActions.PLACEMENT_SIGNAL
            or "psychopatz.radio.signal",
        order = 90,
        isAvailable = function()
            return PNC.ContactsUI and PNC.ContactsUI.Open ~= nil
        end,
        onClick = function()
            PNC.ContactsUI.Open()
            return true
        end,
    })
    RadioActions.Register({
        id = "projecthoomans.colony_management",
        label = tr("UI_PNC_ProjectHoomansColony", "Project Hoomans Colony"),
        signalLabel = tr(
            "UI_PNC_ProjectHoomansColony",
            "Project Hoomans Colony"
        ),
        placement = RadioActions.PLACEMENT_SIGNAL or "psychopatz.radio.signal",
        order = 100,
        isAvailable = function()
            return PNC.ColonyManagementUI and PNC.ColonyManagementUI.Open ~= nil
        end,
        onClick = function()
            PNC.ColonyManagementUI.Open()
            return true
        end,
    })
end

return RadioActions
