-- Television vicinity reminisce, power-out reaction, and show commentary beats.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local LIFE_AND_LIVING_PATTERNS = {
    "life and living",
    "woodcraft",
    "cook show",
    "exposure survival",
}

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, val = pcall(obj[method], obj, ...)
    if ok then return val end
    return nil
end

local function getDeviceData(obj)
    if not obj then return nil end
    return safeCall(obj, "getDeviceData")
end

local function isTelevision(obj, dd)
    if not obj then return false end
    if dd and safeCall(dd, "getIsTelevision") == true then
        return true
    end
    if type(instanceof) == "function" and instanceof(obj, "IsoTelevision") == true then
        return true
    end
    if type(obj) == "table" and obj.isTelevision == true then
        return true
    end
    return false
end

local function containsLifeAndLivingPattern(text)
    if type(text) ~= "string" or text == "" then return false end
    local lower = string.lower(text)
    for i = 1, #LIFE_AND_LIVING_PATTERNS do
        if string.find(lower, LIFE_AND_LIVING_PATTERNS[i], 1, true) then
            return true
        end
    end
    return false
end

local function resolveShowInfo(dd, codes, line)
    local ch = dd and tonumber(safeCall(dd, "getChannel")) or nil
    local chName = nil
    if ch ~= nil and ZomboidRadio and type(ZomboidRadio.getInstance) == "function" then
        local radio = ZomboidRadio.getInstance()
        chName = radio and safeCall(radio, "getChannelName", ch)
    end
    local media = dd and safeCall(dd, "getMediaData") or nil
    local mediaTitle = media and (safeCall(media, "getTitleEN") or safeCall(media, "getTitle"))

    local isLifeAndLiving = containsLifeAndLivingPattern(chName)
        or containsLifeAndLivingPattern(mediaTitle)
        or containsLifeAndLivingPattern(codes)
        or containsLifeAndLivingPattern(line)

    local showName = (type(mediaTitle) == "string" and mediaTitle ~= "" and mediaTitle)
        or (type(chName) == "string" and chName ~= "" and chName)
        or (isLifeAndLiving and "Life and Living")
        or "the broadcast"

    return isLifeAndLiving and "life_and_living" or "show", showName
end

local function buildTelevisionPlan(anchor, partner, openRole, replyRole, fam, refPrefix, showName, poolID)
    if type(Beats.BuildWorldThread) ~= "function" then return nil end
    return Beats.BuildWorldThread(anchor, partner, {
        refPrefix = refPrefix,
        family = fam,
        poolID = poolID or (string.sub(tostring(openRole or ""), 1, 11) == "tv_watching"
            and "semantic.world.media.broadcast"
            or "semantic.world.object.notice"),
        eventType = "world_television_beat",
        topic = "television",
        openAct = "CHAT",
        replyAct = "CHAT",
        openRole = openRole,
        replyRole = replyRole,
        priority = 28,
        delayMs = 1000,
        tokens = showName and {
            ["slot.show.name"] = showName,
            ["show.name"] = showName,
        } or nil,
    })
end

if type(Beats.RegisterObjectBeatHook) == "function" then
    Beats.RegisterObjectBeatHook("world_object.television_vicinity", {
        priority = 25,
        cooldownMs = 90000,
        maxDistance = 3,
        matches = function(obj)
            local dd = getDeviceData(obj)
            if not isTelevision(obj, dd) then return false end
            if dd and safeCall(dd, "getIsTurnedOn") == true then
                return false
            end
            return true
        end,
        evaluate = function(obj, _, anchor, partner, ctx)
            local dd = getDeviceData(obj)
            local powerOff = (type(ctx and ctx.env) == "table" and ctx.env.powerOn == false)
                or (dd and safeCall(dd, "canBePoweredHere") == false)
            if powerOff then
                return buildTelevisionPlan(
                    anchor,
                    partner,
                    "tv_power_out_open",
                    "tv_power_out_reply",
                    "world_tv_power_out",
                    "world:tv_power_out",
                    nil
                )
            end
            return buildTelevisionPlan(
                anchor,
                partner,
                "tv_reminisce_open",
                "tv_reminisce_reply",
                "world_tv_reminisce",
                "world:tv_reminisce",
                nil
            )
        end,
    })
end

if type(Beats.RegisterDeviceTextHook) == "function" then
    Beats.RegisterDeviceTextHook("device_text.television_show", {
        priority = 35,
        cooldownMs = 35000,
        maxDistance = 12,
        matches = function(device)
            local dd = getDeviceData(device)
            if not isTelevision(device, dd) then return false end
            if dd and safeCall(dd, "getIsTurnedOn") == false then return false end
            return true
        end,
        evaluate = function(device, line, _, _, _, anchor, partner, _, codes)
            local dd = getDeviceData(device)
            local showKind, showName = resolveShowInfo(dd, codes, line)
            if showKind == "life_and_living" then
                return buildTelevisionPlan(
                    anchor,
                    partner,
                    "tv_watching_life_and_living_open",
                    "tv_watching_life_and_living_reply",
                    "world_tv_watching_life_and_living",
                    "world:tv_watching",
                    showName
                )
            end
            return buildTelevisionPlan(
                anchor,
                partner,
                "tv_watching_show_open",
                "tv_watching_show_reply",
                "world_tv_watching_show",
                "world:tv_watching",
                showName
            )
        end,
    })
end

function Beats.ResetTelevisionRuntime()
end

return Beats
