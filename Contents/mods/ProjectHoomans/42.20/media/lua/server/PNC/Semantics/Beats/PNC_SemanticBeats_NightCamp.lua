-- Dedicated Night Camp dialogue beats:
-- 1. Campfire build ritual (propose fire -> wood/tinder -> lighter/matches)
-- 2. Evening camping stories around the fire circle
-- 3. Fireside invite/interaction with the player
-- 4. 11 PM sleep/lookout watch handoff & night-watch player check-in
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local VARIANT_COUNTS = {
    build_propose = 3,
    build_solo = 3,
    build_wood = 3,
    build_lighter = 3,
    story_open = 4,
    story_reply = 4,
    story_chime = 3,
    player_invite = 3,
    watch_handoff_open = 3,
    watch_handoff_reply = 3,
    lookout_player = 3,
}

local FALLBACKS = {
    build_propose = "It's getting dark—let's build a campfire right here before it gets any colder.",
    build_solo = "Sun's down. Better get a small campfire going before it gets too dark.",
    build_wood = "I've got some dry branches and tinder we can use. Stack 'em right there.",
    build_lighter = "Here, borrow my lighter—let's get this fire going.",
    story_open = "You know, nights like this by a fire almost make me forget how quiet the towns got.",
    story_reply = "Hah, I hear you, {addressee.name}. Hard to believe what used to count as a rough day.",
    story_chime = "At least the fire's warm tonight. Beats shivering in a dark alley.",
    player_invite = "Pull up a spot by the fire, {addressee.name}. Plenty of warmth to go around tonight.",
    watch_handoff_open = "Past eleven already. Everyone get some sleep—I'll take first watch by the fire.",
    watch_handoff_reply = "Thanks, {addressee.name}. Wake me if anything moves out in the dark.",
    lookout_player = "Quiet watch so far, {addressee.name}. Grab some rest if you need—I've got eyes on the perimeter.",
}

local function pickVariantKey(role, seed, now)
    local count = VARIANT_COUNTS[role] or 1
    local n = math.abs(math.floor(tonumber(seed) or 0) + math.floor((tonumber(now) or 0) / 1000))
    local idx = (n % count) + 1
    return "convo.world.night_camp." .. tostring(role) .. "." .. tostring(idx)
end

local function makeTurn(speaker, addressee, role, opts)
    opts = opts or {}
    local templateID = pickVariantKey(role, speaker and speaker.identitySeed or opts.seed, opts.now)
    local turn = {
        speaker = speaker,
        addressee = addressee,
        addresseeIsPlayer = opts.addresseeIsPlayer == true,
        addresseeName = opts.addresseeName,
        eventType = opts.eventType or "night_camp_beat",
        domain = "social",
        channel = "social",
        topic = "night_camp",
        act = opts.act or "CHAT",
        role = role,
        templateID = templateID,
        fallback = FALLBACKS[role] or "",
        family = opts.family or ("night_camp_" .. tostring(role)),
        delayMs = tonumber(opts.delayMs) or 0,
        priority = tonumber(opts.priority) or 34,
        priorityHoldMs = 600,
        holdMs = 900,
        ttlMs = tonumber(opts.ttlMs) or 12000,
        cooldownMs = tonumber(opts.cooldownMs) or 2000,
        familyCooldownMs = tonumber(opts.familyCooldownMs) or 2000,
        eventRef = tostring(opts.refPrefix or "night_camp") .. ":" .. tostring(role) .. ":" .. tostring(speaker and speaker.id or "npc"),
        tokens = opts.tokens,
        onDelivered = opts.onDelivered,
    }
    return turn
end

-- 1. Campfire build ritual beat (builder proposes -> helper brings wood/tinder -> helper lends lighter).
Beats.RegisterHook("night_camp.build_start", {
    eventTypes = { "night_camp.build_start" },
    priority = 44,
    cooldownMs = 12000,
    evaluate = function(_, payload)
        local builder = payload.builder or payload.anchor
        if type(builder) ~= "table" or builder.alive == false then return nil end
        local helpers = type(payload.helpers) == "table" and payload.helpers or {}
        local helper1 = helpers[1]
        local helper2 = helpers[2] or helper1
        local now = tonumber(payload.now) or 0
        local ref = "night_camp:build:" .. tostring(payload.campKey or builder.id)

        if not helper1 then
            return {
                threadID = ref,
                family = "night_camp_build",
                ttlMs = 10000,
                opening = makeTurn(builder, nil, "build_solo", {
                    refPrefix = ref,
                    family = "night_camp_build",
                    priority = 44,
                    now = now,
                    onDelivered = payload.onComplete,
                }),
                replies = {},
            }
        end

        return {
            threadID = ref,
            family = "night_camp_build",
            ttlMs = 14000,
            opening = makeTurn(builder, helper1, "build_propose", {
                refPrefix = ref,
                family = "night_camp_build",
                priority = 44,
                now = now,
            }),
            replies = {
                makeTurn(helper1, builder, "build_wood", {
                    refPrefix = ref,
                    family = "night_camp_build",
                    priority = 44,
                    delayMs = 1400,
                    now = now + 1,
                }),
                makeTurn(helper2, builder, "build_lighter", {
                    refPrefix = ref,
                    family = "night_camp_build",
                    priority = 44,
                    delayMs = 2800,
                    now = now + 2,
                    onDelivered = payload.onComplete,
                }),
            },
        }
    end,
})

-- 2. Evening camping stories around the campfire circle.
Beats.RegisterHook("night_camp.story", {
    eventTypes = { "night_camp.story" },
    priority = 32,
    cooldownMs = 30000,
    evaluate = function(_, payload)
        local teller = payload.speaker or payload.anchor
        local listener = payload.partner or payload.addressee
        if type(teller) ~= "table" or teller.alive == false then return nil end
        if type(listener) ~= "table" or listener.alive == false then return nil end
        local third = payload.third
        local now = tonumber(payload.now) or 0
        local ref = "night_camp:story:" .. tostring(payload.campKey or teller.id) .. ":" .. tostring(math.floor(now / 1000))
        local replies = {
            makeTurn(listener, teller, "story_reply", {
                refPrefix = ref,
                family = "night_camp_story",
                priority = 32,
                delayMs = 1800,
                now = now + 1,
            }),
        }
        if type(third) == "table" and third.alive ~= false and third.id ~= teller.id and third.id ~= listener.id then
            replies[2] = makeTurn(third, teller, "story_chime", {
                refPrefix = ref,
                family = "night_camp_story",
                priority = 32,
                delayMs = 3600,
                now = now + 2,
            })
        end
        return {
            threadID = ref,
            family = "night_camp_story",
            ttlMs = 15000,
            opening = makeTurn(teller, listener, "story_open", {
                refPrefix = ref,
                family = "night_camp_story",
                priority = 32,
                now = now,
            }),
            replies = replies,
        }
    end,
})

-- 3. Fireside invite/interaction directed at a nearby player.
Beats.RegisterHook("night_camp.player_invite", {
    eventTypes = { "night_camp.player_invite" },
    priority = 36,
    cooldownMs = 45000,
    evaluate = function(_, payload)
        local speaker = payload.speaker or payload.anchor
        if type(speaker) ~= "table" or speaker.alive == false then return nil end
        local now = tonumber(payload.now) or 0
        local playerName = tostring(payload.playerName or "friend")
        local ref = "night_camp:invite:" .. tostring(payload.campKey or speaker.id)
        return {
            threadID = ref,
            family = "night_camp_player_invite",
            ttlMs = 10000,
            opening = makeTurn(speaker, nil, "player_invite", {
                refPrefix = ref,
                family = "night_camp_player_invite",
                priority = 36,
                addresseeIsPlayer = true,
                addresseeName = playerName,
                tokens = { ["addressee.name"] = playerName },
                now = now,
            }),
            replies = {},
        }
    end,
})

-- 4. 11 PM sleep/lookout handoff beat.
Beats.RegisterHook("night_camp.watch_handoff", {
    eventTypes = { "night_camp.watch_handoff" },
    priority = 40,
    cooldownMs = 45000,
    evaluate = function(_, payload)
        local sentry = payload.sentry or payload.anchor
        local sleeper = payload.sleeper or payload.partner
        if type(sentry) ~= "table" or sentry.alive == false then return nil end
        local now = tonumber(payload.now) or 0
        local ref = "night_camp:watch:" .. tostring(payload.campKey or sentry.id)
        local replies = {}
        if type(sleeper) == "table" and sleeper.alive ~= false and sleeper.id ~= sentry.id then
            replies[1] = makeTurn(sleeper, sentry, "watch_handoff_reply", {
                refPrefix = ref,
                family = "night_camp_watch",
                priority = 40,
                delayMs = 1500,
                now = now + 1,
            })
        end
        return {
            threadID = ref,
            family = "night_camp_watch",
            ttlMs = 12000,
            opening = makeTurn(sentry, sleeper, "watch_handoff_open", {
                refPrefix = ref,
                family = "night_camp_watch",
                priority = 40,
                now = now,
            }),
            replies = replies,
        }
    end,
})

-- 5. Night-watch lookout interacting with a nearby player.
Beats.RegisterHook("night_camp.lookout_player", {
    eventTypes = { "night_camp.lookout_player" },
    priority = 36,
    cooldownMs = 60000,
    evaluate = function(_, payload)
        local sentry = payload.sentry or payload.speaker or payload.anchor
        if type(sentry) ~= "table" or sentry.alive == false then return nil end
        local now = tonumber(payload.now) or 0
        local playerName = tostring(payload.playerName or "friend")
        local ref = "night_camp:lookout_player:" .. tostring(payload.campKey or sentry.id)
        return {
            threadID = ref,
            family = "night_camp_lookout_player",
            ttlMs = 10000,
            opening = makeTurn(sentry, nil, "lookout_player", {
                refPrefix = ref,
                family = "night_camp_lookout_player",
                priority = 36,
                addresseeIsPlayer = true,
                addresseeName = playerName,
                tokens = { ["addressee.name"] = playerName },
                now = now,
            }),
            replies = {},
        }
    end,
})

return Beats
