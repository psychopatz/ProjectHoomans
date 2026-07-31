-- Pure tactical intent resolution from already-resolved faction context.

PNC = PNC or {}
PNC.FactionIntent = PNC.FactionIntent or {}

local Intent = PNC.FactionIntent
local Balance = PNC.FactionBalance

local function tuning(name, fallback)
    local value = Balance and Balance.Get and Balance.Get(name)
    return value == nil and fallback or value
end

local function result(intent, attack, pursue, commandable, reason)
    return {
        intent = intent,
        attackAllowed = attack == true,
        pursueAllowed = pursue == true,
        commandable = commandable == true,
        reason = tostring(reason or "unspecified"),
    }
end

function Intent.Resolve(spec)
    spec = type(spec) == "table" and spec or {}
    local state = tostring(spec.diplomaticState or "unknown")
    local policy = type(spec.policy) == "table"
        and spec.policy or {}
    local archetypeID = tostring(spec.archetypeID or "")
    local targetStrength = tonumber(spec.targetStrength) or 1
    local observerStrength = math.max(
        0.01,
        tonumber(spec.observerStrength) or 1
    )

    if spec.immediateSelfDefense == true
        or spec.targetAggression == true
    then
        return result("attack", true, true, false,
            "immediate_self_defense")
    end
    if spec.samePlayerOwnedFaction == true then
        return result(
            spec.targetIsOwner and "obey" or "protect",
            false,
            false,
            spec.commandable == true,
            "same_player_faction"
        )
    end
    if spec.sameFaction == true then
        return result("cooperate", false, false,
            spec.commandable == true, "same_faction")
    end
    -- A temporary player-scoped exception suppresses proactive faction
    -- aggression, including war aggression. Immediate self-defense above
    -- deliberately remains authoritative.
    if spec.playerPacified == true then
        return result("tolerate", false, false, false,
            "player_pacification")
    end
    if spec.atWar == true or state == "war" then
        return result("attack", true, true, false,
            "faction_war")
    end
    if spec.activeTruce == true or state == "truce" then
        return result("avoid", false, false, false,
            "active_truce")
    end
    if spec.allied == true or state == "allied" then
        return result("cooperate", false, false, false,
            "faction_alliance")
    end
    -- Territorial looter settlements demand tribute inside their home
    -- radius. They do not inherit roaming-gang shoot-on-sight behavior;
    -- refusal can escalate through the normal war/incident path above.
    if spec.territorialToll == true then
        if spec.targetInsideTerritory == true then
            return result("threaten", false, false, false,
                "territorial_toll_required")
        end
        return result("observe", false, false, false,
            "territorial_boundary")
    end
    if state == "hostile" then
        if archetypeID == "looter"
            or policy.outsiderPolicy == "predatory"
        then
            return result("attack", true, true, false,
                "hostile_predatory_default")
        end
        return result(
            (tonumber(policy.caution) or 0.5)
                >= tuning("hostileCautionMinimum", 0.65)
                and "avoid" or "threaten",
            false,
            false,
            false,
            "hostile_nonwar"
        )
    end
    if state == "wary" then
        return result(
            targetStrength > observerStrength
                and "avoid" or "observe",
            false,
            false,
            false,
            "wary_relation"
        )
    end
    if state == "friendly" then
        return result("tolerate", false, false, false,
            "friendly_relation")
    end

    if archetypeID == "looter"
        or policy.outsiderPolicy == "predatory"
    then
        return result("attack", true, true, false,
            "predatory_default_hostility")
    end
    if archetypeID == "refugee"
        or policy.outsiderPolicy == "cautious"
    then
        return result("avoid", false, false, false,
            "cautious_outsider_policy")
    end
    if archetypeID == "trader"
        or policy.outsiderPolicy == "commercial"
    then
        return result("tolerate", false, false, false,
            "commercial_outsider_policy")
    end
    if spec.personalState == "enemy" then
        return result("threaten", false, false, false,
            "personal_enemy_nonofficial")
    end
    return result("observe", false, false, false,
        "neutral_outsider_policy")
end

function Intent.ResolveWithTrace(spec)
    spec = type(spec) == "table" and spec or {}
    local resolved = Intent.Resolve(spec)
    local policy = type(spec.policy) == "table"
        and spec.policy or {}
    return {
        result = resolved,
        trace = {
            immediateSelfDefense =
                spec.immediateSelfDefense == true,
            targetAggression = spec.targetAggression == true,
            samePlayerFaction =
                spec.samePlayerOwnedFaction == true,
            sameFaction = spec.sameFaction == true,
            playerPacified = spec.playerPacified == true,
            playerPacifiedUntil =
                tonumber(spec.playerPacifiedUntil) or 0,
            playerPacificationReason = tostring(
                spec.playerPacificationReason or ""
            ),
            diplomaticState = tostring(
                spec.diplomaticState or "unknown"
            ),
            atWar = spec.atWar == true,
            allied = spec.allied == true,
            truceActive = spec.activeTruce == true,
            archetype = tostring(spec.archetypeID or ""),
            aggression = tonumber(policy.aggression) or 0,
            retaliation = tonumber(policy.retaliation) or 0,
            caution = tonumber(policy.caution) or 0,
            personalState = tostring(
                spec.personalState or "unknown"
            ),
            observerStrength =
                tonumber(spec.observerStrength) or 1,
            targetStrength = tonumber(spec.targetStrength) or 1,
            territorialToll =
                spec.territorialToll == true,
            targetInsideTerritory =
                spec.targetInsideTerritory == true,
            selectedRule = resolved.reason,
            fallback = "observe",
        },
    }
end

return Intent
