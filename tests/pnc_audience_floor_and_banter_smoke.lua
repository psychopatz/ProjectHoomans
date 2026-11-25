local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 80000
local playerHealth = 100
local delivered = {}
local queriedNPCs = {}

isClient = function() return false end
isServer = function() return true end
getTimestampMs = function() return nowMs end
getTimeInMillis = function() return nowMs end
getText = function(k) return k end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return 3.5 end,
        getWorldAgeHours = function() return 3.5 * 24 end,
        getTimeOfDay = function() return 14 end,
    }
end
getClimateManager = function()
    return {
        isRaining = function() return false end,
        getRainIntensity = function() return 0 end,
        getFogIntensity = function() return 0 end,
        isSnowing = function() return false end,
        getTemperature = function() return 20 end,
    }
end
getSandboxOptions = function()
    return {
        doesPowerGridExist = function() return true end,
        getElecShutModifier = function() return 14 end,
        getWaterShutModifier = function() return 14 end,
    }
end
getWorld = function()
    return { isHydroPowerOn = function() return true end }
end
Events = {
    OnWorldSound = { Add = function() end },
    OnAmbientSound = { Add = function() end },
    OnElectricityChanged = { Add = function() end },
    OnDeviceText = { Add = function() end },
    OnTick = { Add = function() end },
    OnResetLua = { Add = function() end },
}
PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local playerObj = {
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 1 end,
    getUsername = function() return "Pat" end,
    getDisplayName = function() return "Pat" end,
    getDescriptor = function() return { getForename = function() return "Pat" end } end,
    getBodyDamage = function()
        return { getOverallBodyHealth = function() return playerHealth end }
    end,
}

local alex = { id = "npc_alex", name = "Alex", team = "team:1", alive = true, presenceState = "live", x = 101, y = 100, z = 0, runtime = {} }
local sam = { id = "npc_sam", name = "Sam", team = "team:1", alive = true, presenceState = "live", x = 102, y = 100, z = 0, runtime = {} }
local morgan = { id = "npc_morgan", name = "Morgan", team = "team:1", alive = true, presenceState = "live", x = 103, y = 100, z = 0, runtime = {} }
queriedNPCs = { alex }

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return nowMs end,
        ForEachPlayer = function(cb) cb(playerObj) end,
        LogInfo = function() end,
    },
    SpatialIndex = { QueryNPCs = function() return queriedNPCs end },
    Perception = {
        GetTeamKey = function(r) return r and r.team or nil end,
        AreWarningAllies = function(a, b) return a.team == b.team end,
        GetActiveSkirmish = function() return nil end,
        CanSeeWorldObject = function() return true end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(_, npcId, _, ctx)
            local af = ctx and ctx.ambientFlavor or {}
            delivered[#delivered + 1] = {
                at = nowMs,
                npcId = npcId,
                topic = af.topic,
                text = af.text,
            }
            return true
        end,
    },
    ConvoEngine = {
        SocialReactions = {
            Resolve = function(spec)
                return {
                    realizationID = "test:" .. tostring(spec.poolID),
                    fallback = "[" .. tostring(spec.context and spec.context.topic or "") .. "|{addressee.name}]",
                    presentationClass = "BARK",
                    poolID = spec.poolID,
                }
            end,
        },
        TokenFormatter = {
            FirstTokenName = function(s) return tostring(s or "friend") end,
            CleanName = function(s) return tostring(s or "") end,
            CleanLocation = function(s) return tostring(s or "") end,
            Format = function(text, toks)
                return (string.gsub(text, "{([^}]+)}", function(k) return tostring(toks and toks[k] or k) end))
            end,
        },
        Lexicon = {
            Expand = function(raw, _, toks)
                return (string.gsub(raw, "{([^}]+)}", function(k) return tostring(toks and toks[k] or k) end))
            end,
        },
    },
}

local Beats = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticDialogueBeats.lua")
local Aud = PNC.Semantics.AudienceContext

-- 1. AudienceContext: solo player, pair (NPC + player), 3+ group, never self-addresses.
local a1 = Aud.Resolve(alex, { alex }, { includeNearbyPlayer = true, targetCount = 1 })
T.equal(a1.count, 1, "Self must be excluded; only nearby player counted")
T.equal(a1.label, "Pat", "Solo player addressee uses forename")
T.equal(a1.isPlural, false, "Single listener is singular")
T.equal(a1.tokens["target.pronoun"], "it", "Single target pronoun is 'it'")

local a2 = Aud.Resolve(alex, { sam }, { includeNearbyPlayer = true, targetCount = 3 })
T.equal(a2.count, 2, "NPC + nearby player = 2 listeners")
T.equal(a2.isPlural, true, "2 listeners is plural")
T.equal(a2.includesPlayer, true, "Player included alongside squadmate")
T.equal(a2.tokens["target.pronoun"], "them", "Plural target pronoun is 'them'")
T.equal(a2.tokens["target.verb_be"], "are", "Plural target verb is 'are'")

local a3 = Aud.Resolve(alex, { sam, morgan }, { includeNearbyPlayer = true })
T.equal(a3.count, 3, "2 NPCs + nearby player = 3 listeners")
T.truthy(a3.label == "everyone" or a3.label == "everybody" or a3.label == "guys", "3+ listeners use group label")

-- 2. Speech floor pacer prevents simultaneous overlapping turns.
Beats.ResetRuntime()
delivered = {}
local p1 = Beats.BuildWorldThread(alex, nil, {
    refPrefix = "floor:1", family = "test_floor_1", poolID = "test.pool",
    eventType = "test_beat", openRole = "open", priority = 30,
})
local p2 = Beats.BuildWorldThread(sam, nil, {
    refPrefix = "floor:2", family = "test_floor_2", poolID = "test.pool",
    eventType = "test_beat", openRole = "open", priority = 30,
})
Beats.StartThread(p1, nowMs, {})
Beats.StartThread(p2, nowMs, {})
T.equal(#delivered, 1, "Second concurrent non-urgent beat must be deferred by speech floor")
nowMs = nowMs + 2000
Beats.Pump(nowMs)
T.equal(#delivered, 2, "Deferred second beat fires cleanly after floor gap")
T.truthy((delivered[2].at - delivered[1].at) >= Beats.FLOOR_GAP_MS, "Turns spaced by at least FLOOR_GAP_MS")

-- 3. Solo companion + injured player triggers smart wellbeing_check banter addressed to Pat.
Beats.ResetRuntime()
delivered = {}
playerHealth = 55
queriedNPCs = { alex }
nowMs = nowMs + 70000
local ok = Beats.CheckGroupBanter(nowMs)
T.truthy(ok, "Solo companion with nearby player should initiate contextual banter")
T.equal(#delivered, 1, "Solo banter delivers opening line to player")
T.contains(delivered[1].text, "wellbeing_check|Pat", "Injured player triggers wellbeing_check addressed to Pat")
