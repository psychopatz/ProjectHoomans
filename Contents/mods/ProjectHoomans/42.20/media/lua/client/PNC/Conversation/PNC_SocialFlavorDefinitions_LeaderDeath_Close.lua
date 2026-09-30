--[[
    Leadership-loss lanes: the personal-loss lanes.

    DEVOTED is a partner or family member; CLOSE is a bonded companion or warm
    friend.  Both grieve first and ask about leadership second.  Lanes only;
    registration lives in PNC_SocialFlavorDefinitions_LeaderDeath.lua.
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
        id = "devoted_promoted",
        when = when("devoted", "promoted"),
        npc = {
            line("UI_PNC_LeaderDeath_Devoted_Lead_1",
                "{leaderName} is dead. {successorName} is in charge now. I... I can't think about that yet."),
            line("UI_PNC_LeaderDeath_Devoted_Lead_2",
                "They're gone and {successorName} is taking over. I just need a moment."),
            line("UI_PNC_LeaderDeath_Devoted_Lead_3",
                "{leaderName} is gone. We follow {successorName} now. I didn't want it to be this way."),
        },
    },
    {
        id = "devoted_player",
        when = when("devoted", "player"),
        npc = {
            line("UI_PNC_LeaderDeath_Devoted_Player_1",
                "{leaderName} is dead. {playerFirstName}, please tell me this group still stands."),
            line("UI_PNC_LeaderDeath_Devoted_Player_2",
                "They're gone. I can't lose anyone else today. Someone lead us."),
            line("UI_PNC_LeaderDeath_Devoted_Player_3",
                "{leaderName} is gone. I don't care who takes over. Just don't leave us."),
        },
    },
    {
        id = "devoted",
        when = when("devoted"),
        npc = {
            line("UI_PNC_LeaderDeath_Devoted_1",
                "{leaderName} is gone. I loved them. I can't do this alone."),
            line("UI_PNC_LeaderDeath_Devoted_2",
                "They're dead. Please, someone tell me what we do now."),
            line("UI_PNC_LeaderDeath_Devoted_3",
                "I just lost {leaderName}. I don't care about anything else right now."),
        },
    },
    {
        id = "close_promoted",
        when = when("close", "promoted"),
        npc = {
            line("UI_PNC_LeaderDeath_Close_Lead_1",
                "{leaderName} is dead. {successorName} leads us now. I will follow."),
            line("UI_PNC_LeaderDeath_Close_Lead_2",
                "We lost {leaderName}. {successorName}, we're with you, but this hurts."),
            line("UI_PNC_LeaderDeath_Close_Lead_3",
                "{leaderName} is gone. {successorName} takes over. We keep moving, for them."),
        },
    },
    {
        id = "close_player",
        when = when("close", "player"),
        npc = {
            line("UI_PNC_LeaderDeath_Close_Player_1",
                "{leaderName} is dead. We need someone to step up. Now."),
            line("UI_PNC_LeaderDeath_Close_Player_2",
                "They're gone. Who leads us? Somebody has to say it out loud."),
            line("UI_PNC_LeaderDeath_Close_Player_3",
                "{leaderName} is gone and I don't know who's in charge. Do any of you?"),
        },
    },
    {
        id = "close",
        when = when("close"),
        npc = {
            line("UI_PNC_LeaderDeath_Close_1",
                "{leaderName} is dead. We need a new leader, and we need one now."),
            line("UI_PNC_LeaderDeath_Close_2",
                "We just lost {leaderName}. Someone has to take charge."),
            line("UI_PNC_LeaderDeath_Close_3",
                "They're gone. We can't keep standing around. Who's next?"),
        },
    },
}
