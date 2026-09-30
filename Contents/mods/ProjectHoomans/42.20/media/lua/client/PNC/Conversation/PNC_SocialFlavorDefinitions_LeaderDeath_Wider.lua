--[[
    Leadership-loss lanes: the functional and cold lanes.

    COLONIST is a member with no close bond, DISTANT has no bond at all, and
    DISSENT is a rival who does not pretend to mourn.  The succession-only
    lanes catch the case where the grief axis is unknown but the structural
    outcome is known.  Lanes only; registration lives in
    PNC_SocialFlavorDefinitions_LeaderDeath.lua.
]]

local function line(key, fallback)
    return { key = key, fallback = fallback }
end

local function when(grief, succession)
    local spec = { leaderDied = true }
    if grief then spec.leaderGrief = grief end
    if succession then spec.leaderSuccession = succession end
    return spec
end

return {
    {
        id = "colonist_promoted",
        when = when("colonist", "promoted"),
        npc = {
            line("UI_PNC_LeaderDeath_Colonist_Lead_1",
                "{leaderName} is dead. {successorName} is leading us now. Fall in."),
            line("UI_PNC_LeaderDeath_Colonist_Lead_2",
                "We lost our leader. {successorName} takes the group. We keep it together."),
            line("UI_PNC_LeaderDeath_Colonist_Lead_3",
                "{leaderName} is gone. {successorName} is in charge. Nobody wanders off."),
        },
    },
    {
        id = "colonist_player",
        when = when("colonist", "player"),
        npc = {
            line("UI_PNC_LeaderDeath_Colonist_Player_1",
                "{leaderName} is dead. We need a new leader before we fall apart."),
            line("UI_PNC_LeaderDeath_Colonist_Player_2",
                "Our leader is gone. Someone here has to take control."),
            line("UI_PNC_LeaderDeath_Colonist_Player_3",
                "We lost {leaderName}. We need to sort out who's leading this group."),
        },
    },
    {
        id = "colonist",
        when = when("colonist"),
        npc = {
            line("UI_PNC_LeaderDeath_Colonist_1",
                "{leaderName} is dead. We need a new leader or we're done."),
            line("UI_PNC_LeaderDeath_Colonist_2",
                "We just lost our leader. Everybody stay calm and stay together."),
            line("UI_PNC_LeaderDeath_Colonist_3",
                "{leaderName} is gone. Someone has to be in charge."),
        },
    },
    {
        id = "distant_promoted",
        when = when("distant", "promoted"),
        npc = {
            line("UI_PNC_LeaderDeath_Distant_Lead_1",
                "So {leaderName} is dead. {successorName} runs the group now. Fine."),
            line("UI_PNC_LeaderDeath_Distant_Lead_2",
                "That's the leader gone. {successorName} takes over. Let's move."),
        },
    },
    {
        id = "distant",
        when = when("distant"),
        npc = {
            line("UI_PNC_LeaderDeath_Distant_1",
                "{leaderName} is dead. Somebody needs to lead. I'm not volunteering."),
            line("UI_PNC_LeaderDeath_Distant_2",
                "Their leader is gone. That's their problem to sort out."),
        },
    },
    {
        id = "dissent",
        when = when("dissent"),
        npc = {
            line("UI_PNC_LeaderDeath_Dissent_1",
                "{leaderName} is dead. Good. Now find someone better."),
            line("UI_PNC_LeaderDeath_Dissent_2",
                "Your leader is gone. About time somebody else made the calls."),
            line("UI_PNC_LeaderDeath_Dissent_3",
                "{leaderName} is finished. Pick a new leader. Anyone but the last one."),
        },
    },
    -- Succession-only lanes: reached when the grief axis is unknown but the
    -- structural outcome is known.
    {
        id = "promoted",
        when = when(nil, "promoted"),
        npc = {
            line("UI_PNC_LeaderDeath_Promoted_1",
                "Our leader is dead. {successorName} is taking over the group."),
            line("UI_PNC_LeaderDeath_Promoted_2",
                "We lost them. {successorName} leads us now. Keep together."),
            line("UI_PNC_LeaderDeath_Promoted_3",
                "The group follows {successorName} now. We're still moving."),
        },
    },
    {
        id = "player",
        when = when(nil, "player"),
        npc = {
            line("UI_PNC_LeaderDeath_Player_1",
                "Our leader is dead. We need a new one. Now."),
            line("UI_PNC_LeaderDeath_Player_2",
                "They're gone. Who's leading us? Somebody decide."),
        },
    },
}
