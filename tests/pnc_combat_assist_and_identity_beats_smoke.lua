local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 30000
local currentHour = 22
local delivered = {}
local relStore = {}
local profileBuildCalls = 0

isClient = function() return false end
isServer = function() return true end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end
getCurrentSaveName = function() return "combat-assist-beats-smoke" end
getText = function(k) return k end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return 10 end,
        getWorldAgeHours = function() return 240 end,
        getTimeOfDay = function() return currentHour end,
    }
end
getClimateManager = function()
    return {
        isRaining = function() return false end,
        getRainIntensity = function() return 0 end,
        getFogIntensity = function() return 0 end,
        isSnowing = function() return false end,
        getTemperature = function() return 16 end,
    }
end
getCell = function()
    return {
        getGridSquare = function()
            return { getRoom = function() return nil end }
        end,
    }
end
instanceof = function(obj, cls)
    return type(obj) == "table" and obj._class == cls
end
Events = {
    OnWorldSound = { Add = function() end },
    OnAmbientSound = { Add = function() end },
    OnElectricityChanged = { Add = function() end },
    OnDeviceText = { Add = function() end },
    OnTick = { Add = function() end },
    OnResetLua = { Add = function() end },
}

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

local playerObj = {
    _class = "IsoPlayer",
    isPlayer = true,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 1 end,
    getUsername = function() return "Pat" end,
    getDisplayName = function() return "Patrick Patz" end,
    getDescriptor = function()
        return {
            getForename = function() return "Patrick" end,
            getSurname = function() return "Patz" end,
        }
    end,
    getStats = function()
        return {
            getFatigue = function() return 0.25 end,
            getPanic = function() return 10 end,
            getStress = function() return 0.1 end,
            getPain = function() return 0 end,
        }
    end,
    getBodyDamage = function()
        return {
            getOverallBodyHealth = function() return 95 end,
            getNumPartsBleeding = function() return 0 end,
        }
    end,
}

local registryRecords = {}

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return nowMs end,
        ForEachPlayer = function(cb) cb(playerObj) end,
    },
    EntityRef = {
        IsNPC = function(key) return string.sub(tostring(key or ""), 1, 4) == "npc:" end,
        ForNPC = function(id) return "npc:" .. tostring(id) end,
        ForPlayer = function() return "player:Pat" end,
    },
    SocialEventHooks = {
        ResolvePlayerKey = function() return "player:Pat" end,
    },
    Perception = {
        CanSeeWorldObject = function() return true end,
    },
    Registry = {
        Get = function(id) return registryRecords[tostring(id)] end,
    },
    Relationships = {
        Get = function(npcID, targetKey)
            return relStore[tostring(npcID) .. "->" .. tostring(targetKey)]
        end,
        GetOrCreate = function(npcID, targetKey)
            local k = tostring(npcID) .. "->" .. tostring(targetKey)
            relStore[k] = relStore[k] or { state = "stranger", trust = 0, approval = 0, identityTrust = "unknown" }
            return relStore[k]
        end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(_, npcID, evType, payload)
            delivered[#delivered + 1] = { npcID = npcID, eventType = evType, payload = payload }
            return true
        end,
    },
    Semantics = {
        CombatReactionProfile = {
            Build = function(rec)
                profileBuildCalls = profileBuildCalls + 1
                local p = (rec.social and rec.social.personality) or {}
                return {
                    allyWarnStyle = rec._testStyle or "supportive",
                    styleProfile = rec._testStyle or "supportive",
                    combatReactionStyle = rec._testStyle or "supportive",
                    effectiveDisposition = {
                        sociability = p.sociability or 65,
                        compassion = p.compassion or 65,
                        bravery = p.bravery or 60,
                        aggression = p.aggression or 30,
                    },
                    bravery = (p.bravery or 60) / 100,
                    aggression = (p.aggression or 30) / 100,
                    compassion = (p.compassion or 65) / 100,
                    panic = rec.conditionStats and rec.conditionStats.panic or 0,
                    stress = 0,
                    fatigue = rec.conditionStats and rec.conditionStats.fatigue or 0,
                    pain = 0,
                    bleeding = rec.health and rec.health.bleeding == true,
                    healthState = rec.health and rec.health.state or "okay",
                    hpRatio = 1,
                    isCowardly = false,
                    isBrave = (p.bravery or 60) >= 68,
                    isExhausted = (rec.conditionStats and rec.conditionStats.fatigue or 0) >= 0.75,
                }
            end,
        },
    },
    ConvoEngine = {
        ResponseCatalog = {
            _pools = {},
            Register = function(poolID, def)
                PNC.ConvoEngine.ResponseCatalog._pools[poolID] = def
            end,
        },
        SocialReactions = {
            Resolve = function(req)
                local pool = PNC.ConvoEngine.ResponseCatalog._pools[req.poolID]
                if not pool or type(pool.variants) ~= "table" then return nil end
                local best, bestPri = nil, -1
                for _, item in ipairs(pool.variants) do
                    local match = true
                    for k, expected in pairs(item.when or {}) do
                        if (req.context and req.context[k]) ~= expected then
                            match = false
                            break
                        end
                    end
                    if match and (item.priority or 0) > bestPri then
                        best, bestPri = item, item.priority or 0
                    end
                end
                if not best then return nil end
                return {
                    realizationID = best.id,
                    templateID = best.templateID,
                    fallback = best.fallback,
                    presentationClass = "BARK",
                }
            end,
        },
    },
}

local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
ConvoDSL.EnsureActiveLanguage()
ConvoDSL.FlushStream()
local Beats = require "PNC/Semantics/PNC_SemanticDialogueBeats"
local BC = PNC.Semantics.BeatContext
local IdentityBeat = PNC.Semantics.CombatAssistIdentity

local stranger = {
    id = "npc_stranger_1",
    name = "Elena Brooks",
    alive = true,
    presenceState = "live",
    x = 12, y = 10, z = 0,
    _testStyle = "supportive",
    social = { personality = { sociability = 70, compassion = 75, bravery = 55, aggression = 25 } },
}
local colonistOpen = {
    id = "npc_colonist_open",
    name = "Myrna Patz",
    alive = true,
    presenceState = "live",
    isCompanion = true,
    x = 11, y = 11, z = 0,
    _testStyle = "supportive",
    social = { personality = { sociability = 80, compassion = 75, bravery = 65, aggression = 20 } },
}
local colonistWary = {
    id = "npc_colonist_wary",
    name = "Randolph Patz",
    alive = true,
    presenceState = "live",
    isCompanion = true,
    x = 11, y = 12, z = 0,
    _testStyle = "cold",
    social = { personality = { sociability = 20, compassion = 15, bravery = 70, aggression = 80 } },
}
registryRecords[stranger.id] = stranger
registryRecords[colonistOpen.id] = colonistOpen
registryRecords[colonistWary.id] = colonistWary

-- 1. Dual-actor BeatContext + short-TTL actor memoization
local ctx1 = BC.Build(stranger, playerObj, { now = nowMs, partnerKey = "player:Pat", addresseeIsPlayer = true, earnedDelta = 1 })
T.equal(ctx1.actor.style, "supportive", "speaker style resolved")
T.equal(ctx1.partner.isPlayer, true, "player partner resolved")
T.equal(ctx1.relationship.tier, "stranger", "stranger tier resolved")
T.equal(ctx1.relationship.knowsName, false, "stranger does not know player name")
T.equal(ctx1.env.timeOfDay, "night", "night timeOfDay resolved")
local callsAfterFirst = profileBuildCalls
local _ = BC.Build(stranger, playerObj, { now = nowMs + 500, partnerKey = "player:Pat", addresseeIsPlayer = true })
T.equal(profileBuildCalls, callsAfterFirst, "actor stats memoized within TTL")

-- 2. Single-zombie protection triggers gratitude beat + proactive "what's your name?" SOCIAL_PROMPT
local okProt, tid = Beats.OnCombatAssistProtected({
    encounterID = "enc_1",
    actorKey = "player:Pat",
    targetKey = "npc:npc_stranger_1",
    earnedDelta = 1,
    now = nowMs,
})
T.truthy(okProt == true and tid ~= nil, "OnCombatAssistProtected starts beat thread")
T.equal(#delivered, 1, "opening gratitude delivered immediately")
T.truthy(string.find(delivered[1].payload.ambientFlavor.text, "cutting it close", 1, true) ~= nil
    and not string.find(delivered[1].payload.ambientFlavor.text, "{", 1, true),
    "night-time compositional gratitude line expanded cleanly")

-- Pump forward to fire delayed proactive ask-name turn
nowMs = nowMs + 1600
local fired = Beats.Pump(nowMs)
T.equal(fired, 1, "delayed proactive ask-name turn fired")
T.equal(#delivered, 2, "ask-name prompt delivered")
local askPayload = delivered[2].payload
T.equal(askPayload.ambientFlavor.presentationClass, "SOCIAL_PROMPT", "proactive ask-name uses SOCIAL_PROMPT")
T.equal(askPayload.ambientFlavor.observerOnly, false, "proactive ask-name is interactive for player")
T.equal(#askPayload.offerIDs, 3, "proactive ask-name carries 3 identity choice offerIDs")
T.equal(askPayload.offerIDs[1], "identity.choice.real_name", "real_name offer present")
T.equal(askPayload.offerIDs[2], "identity.choice.refuse_name", "refuse_name offer present")
T.equal(askPayload.offerIDs[3], "identity.choice.lie_name", "lie_name offer present")

-- Encounter dedupe prevents spam for same encounterID
local okDup, dupReason = Beats.OnCombatAssistProtected({
    encounterID = "enc_1",
    actorKey = "player:Pat",
    targetKey = "npc:npc_stranger_1",
    now = nowMs,
})
T.equal(okDup, false, "duplicate encounter assist suppressed")
T.equal(dupReason, "encounter_already_celebrated", "encounter dedupe reason")

-- 3. Cross-group companion <-> external NPC cleared encounter + autonomous colonist name exchange
Beats.ResetRuntime()
delivered = {}
relStore = {}
nowMs = 90000
currentHour = 14 -- daytime

local okCleared = Beats.OnCombatEncounterCleared({
    encounterID = "enc_companion_1",
    actorKey = "npc:npc_colonist_open",
    targetKey = "npc:npc_stranger_1",
    hordeAttack = true,
    threatCount = 5,
    earnedDelta = 2,
    now = nowMs,
})
T.truthy(okCleared == true, "cross-group companion exchange starts")
T.equal(#delivered, 1, "external NPC opens horde companion exchange")
T.equal(delivered[1].npcID, "npc_stranger_1", "external NPC selected as opener")

-- Pump through companion reply + ask name + colonist real_name answer + asker ack
nowMs = nowMs + 1200; Beats.Pump(nowMs) -- companion reply
nowMs = nowMs + 1200; Beats.Pump(nowMs) -- ask name
nowMs = nowMs + 1300; Beats.Pump(nowMs) -- colonist answers with real name
nowMs = nowMs + 1300; Beats.Pump(nowMs) -- asker reacts
T.equal(#delivered, 5, "all 5 turns of cross-group exchange + autonomous identity exchange delivered")
local relAfterOpen = relStore["npc_stranger_1->npc:npc_colonist_open"]
T.truthy(relAfterOpen and relAfterOpen.identityTrust == "trusted" and relAfterOpen.knownName == "Myrna Patz",
    "open colonist truthfully introduced and persisted on relationship")

-- 4. Wary/deceptive colonist chooses to lie with generated alias
relStore["npc_stranger_1->npc:npc_colonist_wary"] = { state = "wary", trust = -12, approval = -10, identityTrust = "unknown" }
local waryCtx = BC.Build(stranger, colonistWary, { now = nowMs, partnerKey = "npc:npc_colonist_wary" })
local waryChoice, waryAlias = IdentityBeat.DecideAutonomousChoice(colonistWary, stranger, waryCtx)
T.equal(waryChoice, "lie_name", "wary deceptive colonist chooses to lie")
T.truthy(type(waryAlias) == "string" and waryAlias ~= "" and waryAlias ~= "Randolph Patz",
    "wary colonist generates a non-canonical alias")

-- 5. Client CombatResponseSurface accepts SOCIAL_PROMPT and surfaces the 3 StaticProvider_Identity buttons
local shownActive = nil
local Surface = require "PNC/ConvoEngine/CombatResponseSurface"
Surface.ResetRuntime()
Surface.SetClock(function() return nowMs end)
Surface.SetConversationProbe(function() return false end)
Surface.SetUIAdapter({
    Show = function(active) shownActive = active; return true end,
    Hide = function() end,
})
PNC.ConvoEngine.DialogueInput = {
    Internal = {
        RouterFor = function() return { state = { sequence = 1 } } end,
        ShallowContext = function(view) return view.spec.context end,
    },
    SubmitSemanticFrame = function() return true, "submitted" end,
}
local origBuild = PNC.ConvoEngine.DialogueSuggestions.Build
PNC.ConvoEngine.DialogueSuggestions.Build = function(_, projCtx)
    T.truthy(type(projCtx.pendingIdentityExchange) == "table", "pendingIdentityExchange propagated to Suggestions.Build")
    return {
        candidates = {
            { id = "identity.choice.real_name", rank = 10, display = { label = "Say your real name" }, frame = { intent = "INFORM", subject = "IDENTITY" } },
            { id = "identity.choice.refuse_name", rank = 20, display = { label = "Don't tell your name" }, frame = { intent = "REFUSE", subject = "IDENTITY" } },
            { id = "identity.choice.lie_name", rank = 30, display = { label = "Lie about your name" }, frame = { intent = "INFORM", subject = "IDENTITY" } },
        },
    }
end

local surfOk, surfReason = Surface.ObserveReceive({
    npcID = "npc_stranger_1",
    eventID = "assist:enc_1:ask_name",
    eventType = "social_identity_prompt",
    context = {
        presentationClass = "SOCIAL_PROMPT",
        eventRef = "assist:enc_1:ask_name",
        pendingIdentityExchange = { kind = "PLAYER_NAME", initiator = "npc" },
    },
    ambientFlavor = {
        presentationClass = "SOCIAL_PROMPT",
        eventRef = "assist:enc_1:ask_name",
        flowID = "social.identity.ask_name_proactive",
        responsePlanID = "semantic.social.identity.ask_name_proactive",
        realizationID = "social.identity.ask_name.after_assist.warm",
        offerIDs = { "identity.choice.real_name", "identity.choice.refuse_name", "identity.choice.lie_name" },
        factRefs = { "assist:enc_1:ask_name" },
        ttlMs = 15000,
    },
})
PNC.ConvoEngine.DialogueSuggestions.Build = origBuild
T.equal(surfOk, true, "CombatResponseSurface accepts SOCIAL_PROMPT")
T.equal(surfReason, "combat_surface_shown", "CombatResponseSurface displays prompt")
T.truthy(shownActive ~= nil and #shownActive.rows == 3, "3 identity buttons shown on floating bar")
T.equal(shownActive.rows[1].label, "Say your real name", "button 1 label")
T.equal(shownActive.rows[2].label, "Don't tell your name", "button 2 label")
T.equal(shownActive.rows[3].label, "Lie about your name", "button 3 label")

-- 6. Dynamic threat-count gratitude scaling in SocialProfileMath
require "PNC/Core/Relationships/PNC_SocialProfileConstants"
require "PNC/Core/Relationships/PNC_SocialProfileGenerator"
require "PNC/Core/Relationships/PNC_SocialProfileTypes"
local ProfileMath = require "PNC/Core/Relationships/PNC_SocialProfileMath"
local baseMem = {
    approvalEffect = 8,
    respectEffect = 14,
    moraleEffect = 5,
    familiarityGain = 4,
}
local neutralProfile = {
    bravery = 0.5, loyalty = 0.5, compassion = 0.5, forgiveness = 0.5,
    sociability = 0.5, materialism = 0.5, aggression = 0.5,
}
local oneKillEffects = ProfileMath.ModifySocialEvent(
    neutralProfile,
    { id = "protected_from_attacker" },
    { type = "protected_from_attacker", context = { threatCount = 1 } },
    baseMem
)
local fiveKillEffects, fiveBreakdown = ProfileMath.ModifySocialEvent(
    neutralProfile,
    { id = "protected_from_attacker" },
    { type = "protected_from_attacker", context = { threatCount = 5 } },
    baseMem
)
local twentyKillEffects, twentyBreakdown = ProfileMath.ModifySocialEvent(
    neutralProfile,
    { id = "protected_from_attacker" },
    { type = "protected_from_attacker", context = { threatCount = 20 } },
    baseMem
)
T.truthy(fiveKillEffects.approvalEffect > oneKillEffects.approvalEffect, "clearing 5 zombies scales approval gratitude up")
T.truthy(fiveKillEffects.respectEffect > oneKillEffects.respectEffect, "clearing 5 zombies scales respect gratitude up")
T.equal(fiveBreakdown.threatScale, 1.5, "5 zombies gives 1.5x scale")
T.equal(twentyBreakdown.threatScale, 2.25, "20 zombies caps cleanly at 2.25x")
T.truthy(twentyKillEffects.approvalEffect >= fiveKillEffects.approvalEffect, "20 zombies >= 5 zombies")

print("pnc_combat_assist_and_identity_beats_smoke: ok")
