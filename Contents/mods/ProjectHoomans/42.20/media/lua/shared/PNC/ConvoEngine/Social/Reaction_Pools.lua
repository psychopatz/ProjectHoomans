-- Pool resolution helpers for semantic social reactions.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Reactions = PNC.ConvoEngine.SocialReactions or {}
PNC.ConvoEngine.SocialReactions = Reactions

local ALLY_WARN_SITUATION_ROLES = {
    blindside_reply = true,
    last_one_reply = true,
    cover_bandage = true,
    injured_has_bandage = true,
    injured_no_bandage = true,
    medic_has_bandage = true,
    medic_no_bandage = true,
    checkin_ok = true,
    weather_rain_reply = true,
    cover_winded = true,
}

local DIRECT_EVENT_POOLS = {
    world_weather_beat = "semantic.world.weather.rain",
    chronology_milestone_beat = "semantic.world.chronology.milestone",
    world_event_food_crisis = "semantic.world.event.food_crisis",
    world_event_raider_surge = "semantic.world.event.raider_surge",
    world_event_surplus = "semantic.world.event.surplus",
    bandit_attack = "semantic.compat.bandits.hooman_hurt",
    necroa_mask_removed = "semantic.compat.necroa.mask_warning",
    necroa_player_mask_removed = "semantic.compat.necroa.player_mask_removed",
    projectalife_meta = "semantic.compat.projectalife.meta",
    projectalife_meta_event = "semantic.compat.projectalife.meta",
    projectalife_encounter = "semantic.compat.projectalife.encounter",
    projectalife_faction_stance = "semantic.compat.projectalife.faction",
    projectalife_faction_conflict = "semantic.compat.projectalife.faction",
    companion_dog_greeting = "semantic.compat.companion_dogs.greeting",
    companion_dog_feed = "semantic.compat.companion_dogs.feed",
    incapacitated_call = "semantic.medical.distress.call",
    ["social.incapacitated_call"] = "semantic.medical.distress.call",
    incapacitated_update = "semantic.medical.distress.update",
    ["social.incapacitated_update"] = "semantic.medical.distress.update",
    incapacitated_repeat = "semantic.medical.distress.repeat",
    ["social.incapacitated_repeat"] = "semantic.medical.distress.repeat",
    witnessed_teammate_hurt = "semantic.medical.distress.teammate",
    treated_wound = "semantic.medical.distress.treatment",
    medical_care_assisted = "semantic.medical.care.assisted",
    combat_fighting_injured_callout = "semantic.combat.fighting.injured_callout",
    combat_wound_received_beat = "semantic.combat.wound.received_beat",
    combat_wound_ally_reaction = "semantic.combat.wound.ally_reaction",
    combat_injury_pain_reaction = "semantic.combat.injury.pain_reaction",
    combat_injury_visible_observation = "semantic.combat.injury.visible_observation",
}

local KILL_STYLES = {
    aggressive = true, supportive = true, shaken = true,
    brave = true, reserved = true, cold = true, practical = true,
}

function Reactions.PoolFor(spec)
    if spec.poolID then return tostring(spec.poolID) end
    local eventType = string.lower(tostring(spec.eventType or ""))
    local direct = DIRECT_EVENT_POOLS[eventType]
    if direct then return direct end

    local context = type(spec.context) == "table" and spec.context or {}
    if eventType == "player_assaulted_npc" then
        local assaultKind = tostring(context.assaultKind or "")
        if assaultKind == "friendly_push" then
            return "semantic.combat.assault.friendly_fire"
        end
        if assaultKind == "looter_taunt" then
            return "semantic.combat.assault.hostile_taunt"
        end
        return "semantic.combat.assault.react"
    end
    if eventType == "world_event_beat" then
        local role = tostring(context.combatReactionRole or "")
        if string.sub(role, 1, 11) == "house_alarm" then
            return "semantic.world.alarm.react"
        end
        return "semantic.world.utility.outage"
    end
    if eventType == "world_television_beat" then
        local role = tostring(context.combatReactionRole or "")
        if string.sub(role, 1, 11) == "tv_watching" then
            return "semantic.world.media.broadcast"
        end
        return "semantic.world.object.notice"
    end
    if eventType == "world_scoped_event_beat" then
        local worldEventType = string.lower(tostring(context.worldEventType or ""))
        if worldEventType == "food_crisis" then
            return "semantic.world.event.food_crisis"
        end
        if worldEventType == "bandit_bonanza" or worldEventType == "raider_surge" then
            return "semantic.world.event.raider_surge"
        end
        if worldEventType == "agricultural_surplus" or worldEventType == "surplus" then
            return "semantic.world.event.surplus"
        end
    end
    if eventType == "zombie_kill_witnessed" or eventType == "zombie_kill_self" then
        local role = tostring(context.combatReactionRole or (
            eventType == "zombie_kill_self" and "killer" or "witness"
        ))
        local style = tostring(context.combatReactionStyle or "practical")
        if role ~= "killer" then role = "witness" end
        if not KILL_STYLES[style] then style = "practical" end
        return "semantic.combat.kill." .. role .. "." .. style
    end
    if eventType == "hostile_npc_kill_self" then
        local style = tostring(context.combatReactionStyle or "practical")
        if not KILL_STYLES[style] then style = "practical" end
        return "semantic.combat.human_kill." .. style
    end
    if eventType == "zombie_horde_encounter" or eventType == "zombie_horde_detected" then
        if context.combatTacticalPrompt == true then
            return "semantic.combat.horde.prompt"
        end
        return "semantic.combat.horde"
    end
    if string.find(eventType, "conversation_safety", 1, true) then
        return "semantic.conversation.safety"
    end
    if string.find(eventType, "corpse", 1, true) or string.find(eventType, "death_reaction", 1, true) then
        return "semantic.corpse.reaction"
    end
    if string.find(eventType, "leader", 1, true) or string.find(eventType, "succession", 1, true) then
        return "semantic.leader_loss.reaction"
    end
    if string.find(eventType, "incapacitated", 1, true)
        or string.find(eventType, "medical", 1, true)
        or string.find(eventType, "treatment", 1, true)
        or string.find(eventType, "hurt", 1, true)
    then
        return "semantic.medical.distress"
    end
    if string.find(eventType, "follower", 1, true) or string.find(eventType, "companion", 1, true) then
        return "semantic.companion.reaction"
    end
    if eventType == "combat_ally_warn_callout" then
        if tostring(context.semanticThreatClass or "") == "zombie" then
            return "semantic.combat.ally_warn.callout.zombie"
        end
        return "semantic.combat.ally_warn.callout.hostile"
    end
    if eventType == "combat_ally_warn_reply_engaging"
        or eventType == "combat_ally_warn_reply_alerted"
        or eventType == "combat_ally_warn_reply_defensive"
    then
        if ALLY_WARN_SITUATION_ROLES[tostring(context.combatReactionRole or "")] then
            return "semantic.combat.ally_warn.reply.defensive"
        end
        if eventType == "combat_ally_warn_reply_engaging" then
            return "semantic.combat.ally_warn.reply.engaging"
        end
        if eventType == "combat_ally_warn_reply_alerted" then
            return "semantic.combat.ally_warn.reply.alerted"
        end
        return "semantic.combat.ally_warn.reply.defensive"
    end
    if string.find(eventType, "combat", 1, true)
        or string.find(eventType, "kill", 1, true)
        or string.find(eventType, "horde", 1, true)
        or string.find(eventType, "zombie", 1, true)
    then
        return "semantic.combat.reaction"
    end
    return "semantic.social.reaction"
end

return Reactions
