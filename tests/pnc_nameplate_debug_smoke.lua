local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function assertContains(actual, expected, label)
    if not string.find(tostring(actual), tostring(expected), 1, true) then
        error((label or "assertContains") .. ": missing=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function assertNotContains(actual, expected, label)
    if string.find(tostring(actual), tostring(expected), 1, true) then
        error((label or "assertNotContains") .. ": unexpected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PNC = {
    Const = { PRESENCE_LIVE = "LIVE" },
    Core = { Now = function() return 1000 end },
}

dofile(ROOT .. "PNC/UI/Nameplates/PNC_NameplateDebug.lua")

local snapshot = {
    id = "npc_debug",
    presenceState = "LIVE",
    aiState = "Combat",
    staminaState = "fresh",
    bodyHealth = {
        infection = {
            active = true,
            stage = "fever",
            fever = 72.4,
            temperatureC = 39.6,
        },
    },
    debugState = {
        aiState = "Combat",
        activeJob = "hostile_hunt",
        orderKind = "attack",
        targetKind = "zombie",
        combatModeResolved = "melee",
        weaponStatus = "melee_ready",
        staminaState = "fresh",
        combatBlockReason = "-",
    },
}

local onlyTarget = {
    debugShowPresence = false,
    debugShowAI = false,
    debugShowJob = false,
    debugShowOrder = false,
    debugShowTarget = true,
    debugShowCombat = false,
    debugShowStamina = false,
    debugShowBlock = false,
}
local filtered = PNC.NameplateDebug.BuildText(snapshot, true, onlyTarget)
assertEqual(filtered, "Target: zombie", "component filtering")
assertNotContains(filtered, "AI:", "hidden AI component")
assertNotContains(filtered, "Weapon:", "hidden combat component")

local infected = PNC.NameplateDebug.InfectionText(snapshot, {
    debugShowInfection = true,
})
assertContains(infected, "INFECTED: YES", "infection marker")
assertContains(infected, "Stage: fever", "infection stage")
assertContains(infected, "Fever: 72%", "infection fever")
assertContains(infected, "Temp: 39.6 C", "infection temperature")
assertEqual(PNC.NameplateDebug.InfectionText(snapshot, {
    debugShowInfection = false,
}), "", "infection component disabled")

snapshot.bodyHealth.infection.active = false
snapshot.bodyHealth.infection.fatal = false
snapshot.bodyHealth.infection.pendingFatal = false
assertEqual(PNC.NameplateDebug.InfectionText(snapshot, {
    debugShowInfection = true,
}), "", "healthy NPC has no infection warning")

print("pnc_nameplate_debug_smoke: ok")
