-- Built-in command flavor. Translation authors only need to provide the keys
-- below; fallbacks keep third-party commands usable while translations catch up.

PNC = PNC or {}

local Flavor = PNC.CompanionCommandFlavor

local function register(commandID, playerLines, npcLines)
    Flavor.Register(commandID, {
        player = playerLines,
        npc = npcLines,
    })
end

register("follow", {
    { key = "UI_PNC_Flavor_Follow_Player_1", fallback = "{names}, on me." },
    { key = "UI_PNC_Flavor_Follow_Player_2", fallback = "Stay close, {names}." },
    { key = "UI_PNC_Flavor_Follow_Player_3", fallback = "{names}, let's move." },
}, {
    { key = "UI_PNC_Flavor_Follow_NPC_1", fallback = "Right behind you." },
    { key = "UI_PNC_Flavor_Follow_NPC_2", fallback = "I'm with you." },
    { key = "UI_PNC_Flavor_Follow_NPC_3", fallback = "Lead the way." },
})

register("stay", {
    { key = "UI_PNC_Flavor_Stay_Player_1", fallback = "{names}, wait here." },
    { key = "UI_PNC_Flavor_Stay_Player_2", fallback = "Hold this position, {names}." },
    { key = "UI_PNC_Flavor_Stay_Player_3", fallback = "{names}, stay put for now." },
}, {
    { key = "UI_PNC_Flavor_Stay_NPC_1", fallback = "I'll stay here." },
    { key = "UI_PNC_Flavor_Stay_NPC_2", fallback = "Holding position." },
    { key = "UI_PNC_Flavor_Stay_NPC_3", fallback = "I'll keep watch." },
})

register("attack_auto", {
    { key = "UI_PNC_Flavor_AttackAuto_Player_1", fallback = "{name}, use your best judgment." },
    { key = "UI_PNC_Flavor_AttackAuto_Player_2", fallback = "{name}, handle threats as you see fit." },
    { key = "UI_PNC_Flavor_AttackAuto_Player_3", fallback = "Watch our backs, {name}." },
}, {
    { key = "UI_PNC_Flavor_AttackAuto_NPC_1", fallback = "I'll handle it." },
    { key = "UI_PNC_Flavor_AttackAuto_NPC_2", fallback = "I'll stay alert." },
    { key = "UI_PNC_Flavor_AttackAuto_NPC_3", fallback = "Leave it to me." },
})

register("attack_melee", {
    { key = "UI_PNC_Flavor_AttackMelee_Player_1", fallback = "{name}, keep it close." },
    { key = "UI_PNC_Flavor_AttackMelee_Player_2", fallback = "Take the front line, {name}." },
    { key = "UI_PNC_Flavor_AttackMelee_Player_3", fallback = "{name}, save your ammunition." },
}, {
    { key = "UI_PNC_Flavor_AttackMelee_NPC_1", fallback = "Going in close." },
    { key = "UI_PNC_Flavor_AttackMelee_NPC_2", fallback = "I'll take the front." },
    { key = "UI_PNC_Flavor_AttackMelee_NPC_3", fallback = "Keeping it quiet." },
})

register("attack_ranged", {
    { key = "UI_PNC_Flavor_AttackRanged_Player_1", fallback = "{name}, keep your distance." },
    { key = "UI_PNC_Flavor_AttackRanged_Player_2", fallback = "Give us ranged cover, {name}." },
    { key = "UI_PNC_Flavor_AttackRanged_Player_3", fallback = "{name}, engage from a safe distance." },
}, {
    { key = "UI_PNC_Flavor_AttackRanged_NPC_1", fallback = "I'll cover you." },
    { key = "UI_PNC_Flavor_AttackRanged_NPC_2", fallback = "Keeping my distance." },
    { key = "UI_PNC_Flavor_AttackRanged_NPC_3", fallback = "I've got a clear shot." },
})

register("attack_none", {
    { key = "UI_PNC_Flavor_AttackNone_Player_1", fallback = "{name}, stay out of the fight." },
    { key = "UI_PNC_Flavor_AttackNone_Player_2", fallback = "Avoid trouble, {name}." },
    { key = "UI_PNC_Flavor_AttackNone_Player_3", fallback = "{name}, don't engage unless I change the order." },
}, {
    { key = "UI_PNC_Flavor_AttackNone_NPC_1", fallback = "I'll avoid trouble." },
    { key = "UI_PNC_Flavor_AttackNone_NPC_2", fallback = "I won't engage." },
    { key = "UI_PNC_Flavor_AttackNone_NPC_3", fallback = "Staying out of it." },
})

return Flavor
