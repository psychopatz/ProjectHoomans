if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Factions.DeclareWar(firstFactionID, secondFactionID, options)
    options = type(options) == "table" and options or {}
    local warReason = Constants.WAR_REASONS[options.reason]
        and options.reason or nil
    if not warReason then return false, "invalid_war_reason" end
    return Internal.mutateTreaty(
        firstFactionID,
        secondFactionID,
        "war_declared",
        options,
        function(forward, reverse, at)
            if forward.atWar and reverse.atWar then
                return false, "unchanged"
            end
            forward.atWar = true
            reverse.atWar = true
            forward.allied = false
            reverse.allied = false
            forward.truceUntil = 0
            reverse.truceUntil = 0
            forward.warStartedAt = at
            reverse.warStartedAt = at
            forward.warReason = warReason
            reverse.warReason = warReason
            forward.initiatingFactionID =
                options.instigatorFactionID or firstFactionID
            reverse.initiatingFactionID =
                forward.initiatingFactionID
            forward.triggeringIncidentID =
                options.triggeringIncidentID
            reverse.triggeringIncidentID =
                options.triggeringIncidentID
            return true
        end
    )
end

function Factions.EndWar(firstFactionID, secondFactionID, options)
    return Internal.mutateTreaty(
        firstFactionID,
        secondFactionID,
        "peace_made",
        options,
        function(forward, reverse, at)
            if not forward.atWar and not reverse.atWar then
                return false, "not_at_war"
            end
            forward.atWar = false
            reverse.atWar = false
            forward.warEndedAt = at
            reverse.warEndedAt = at
            return true
        end
    )
end

function Factions.StartTruce(firstFactionID, secondFactionID, options)
    options = type(options) == "table" and options or {}
    local at = Internal.finiteTimestamp(options.worldAgeHours, 0)
    local untilAt = options.truceUntil ~= nil
        and Internal.finiteTimestamp(options.truceUntil, 0)
        or at + (
            PNC.FactionBalance
            and PNC.FactionBalance.Get("defaultTruceHours")
            or 24
        )
    return Internal.mutateTreaty(
        firstFactionID,
        secondFactionID,
        "truce_started",
        options,
        function(forward, reverse, at)
            if untilAt <= at then
                return false, "invalid_truce_expiry"
            end
            forward.atWar = false
            reverse.atWar = false
            forward.allied = false
            reverse.allied = false
            forward.truceUntil = untilAt
            reverse.truceUntil = untilAt
            forward.warEndedAt = at
            reverse.warEndedAt = at
            return true
        end
    )
end

function Factions.MakePeace(firstFactionID, secondFactionID, options)
    return Internal.mutateTreaty(
        firstFactionID,
        secondFactionID,
        "peace_made",
        options,
        function(forward, reverse, at)
            local changed = forward.atWar or reverse.atWar
                or forward.allied or reverse.allied
                or forward.truceUntil > 0
                or reverse.truceUntil > 0
            if not changed then return false, "unchanged" end
            for _, relation in ipairs({ forward, reverse }) do
                relation.atWar = false
                relation.allied = false
                relation.truceUntil = 0
                relation.warEndedAt = at
                relation.standing =
                    PNC.FactionDiplomacyMath.ClampStanding(
                        relation.standing + (
                            PNC.FactionBalance
                            and PNC.FactionBalance.Get(
                                "peaceStandingGain"
                            ) or 15
                        )
                    )
                relation.trust =
                    PNC.FactionDiplomacyMath.ClampTrust(
                        relation.trust + (
                            PNC.FactionBalance
                            and PNC.FactionBalance.Get(
                                "peaceTrustGain"
                            ) or 10
                        )
                    )
                relation.grievance =
                    PNC.FactionDiplomacyMath.ClampGrievance(
                        relation.grievance * (
                            PNC.FactionBalance
                            and PNC.FactionBalance.Get(
                                "peaceGrievanceMultiplier"
                            ) or 0.5
                        )
                    )
            end
            return true
        end
    )
end

function Factions.FormAlliance(firstFactionID, secondFactionID, options)
    options = type(options) == "table" and options or {}
    return Internal.mutateTreaty(
        firstFactionID,
        secondFactionID,
        "alliance_formed",
        options,
        function(forward, reverse)
            if forward.allied and reverse.allied then
                return false, "unchanged"
            end
            if forward.atWar or reverse.atWar then
                return false, "cannot_ally_during_war"
            end
            if options.override ~= true and (
                forward.standing < 30 or forward.trust < 10
                or reverse.standing < 30 or reverse.trust < 10
            ) then
                return false, "alliance_threshold_not_met"
            end
            forward.atWar = false
            reverse.atWar = false
            forward.truceUntil = 0
            reverse.truceUntil = 0
            forward.allied = true
            reverse.allied = true
            return true
        end
    )
end

function Factions.BreakAlliance(firstFactionID, secondFactionID, options)
    return Internal.mutateTreaty(
        firstFactionID,
        secondFactionID,
        "alliance_broken",
        options,
        function(forward, reverse)
            if not forward.allied and not reverse.allied then
                return false, "not_allied"
            end
            for _, relation in ipairs({ forward, reverse }) do
                relation.allied = false
                relation.trust =
                    PNC.FactionDiplomacyMath.ClampTrust(
                        relation.trust - 15
                    )
                relation.grievance =
                    PNC.FactionDiplomacyMath.ClampGrievance(
                        relation.grievance + 10
                    )
            end
            return true
        end
    )
end

return Factions
