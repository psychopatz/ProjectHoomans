if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Delivery"

local Service = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = Service

Service.PendingReplies = Service.PendingReplies or {}
Service.PendingReplyCount = tonumber(Service.PendingReplyCount) or #Service.PendingReplies

local MAX_PENDING_REPLIES = 32
local MAX_REPLIES_PER_WARNING = 2

local function idHash(id)
    local s, h = tostring(id or ""), 0
    for i = 1, #s do
        h = (h * 31 + string.byte(s, i)) % 100000
    end
    return h
end

function Service.EnqueueAllyReplies(caller, warningResult, now, eventRef)
    local notified = type(warningResult) == "table" and warningResult.notified or nil
    if type(notified) ~= "table" or #notified == 0 then return 0 end
    local queued = 0
    local count = math.min(MAX_REPLIES_PER_WARNING, #notified)
    for idx = 1, count do
        local item = notified[idx]
        local ally = type(item) == "table" and item.record or nil
        if type(ally) == "table" and ally.id ~= nil and ally.alive ~= false then
            while #Service.PendingReplies >= MAX_PENDING_REPLIES do
                table.remove(Service.PendingReplies, 1)
            end
            local ev, act, bark = "combat_ally_warn_reply_alerted", "ACK", "bark.alert_hey"
            if not item.canEngage then
                ev, act, bark = "combat_ally_warn_reply_defensive", "REACT", "bark.whisper_check"
            elseif item.hasLOS == true then
                ev, act, bark = "combat_ally_warn_reply_engaging", "ACK", "bark.alert_hey"
            end
            local h = idHash(ally.id)
            local delay = (idx == 1) and (500 + (h % 251)) or (950 + (h % 351))
            Service.PendingReplies[#Service.PendingReplies + 1] = {
                allyId = tostring(ally.id),
                allyRecord = ally,
                callerRecord = caller,
                callerId = tostring(caller and caller.id or ""),
                callerName = tostring(caller and (caller.name or caller.fullName) or ""),
                teamKey = tostring(warningResult.teamKey or caller and caller.id or "team"),
                desc = warningResult.descriptor,
                canEngage = item.canEngage == true,
                eventType = ev,
                act = act,
                barkId = bark,
                eventRef = tostring(eventRef or "") .. ":reply:" .. tostring(ally.id),
                dueAt = now + delay,
                expiresAt = now + 6000,
            }
            queued = queued + 1
        end
    end
    Service.PendingReplyCount = #Service.PendingReplies
    return queued
end

function Service.PumpPendingReplies(now)
    if (tonumber(Service.PendingReplyCount) or 0) <= 0 then return 0 end
    now = Service.Finite(now) or (PNC.Core and PNC.Core.Now and Service.Finite(PNC.Core.Now())) or 0
    local reg, perc = PNC.Registry, PNC.Perception
    local sec = PNC.SecondaryChannel
    local profileMod = PNC.Semantics.CombatReactionProfile
        or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"
    local remaining, fired = {}, 0
    for i = 1, #Service.PendingReplies do
        local entry = Service.PendingReplies[i]
        if now < entry.dueAt then
            remaining[#remaining + 1] = entry
        elseif now < (entry.expiresAt or math.huge) then
            local rec = (reg and type(reg.Get) == "function" and reg.Get(entry.allyId)) or entry.allyRecord
            if type(rec) == "table" and rec.alive ~= false then
                local ev, act, bark = entry.eventType, entry.act, entry.barkId
                if entry.canEngage and entry.desc and perc and perc.CanAllyEngageThreat then
                    local _, obj = perc.CanAllyEngageThreat(rec, entry.desc)
                    local losObj = (entry.desc.kind == "foreign_npc" and type(obj) == "table")
                        and obj.worldObject or obj
                    local vis = losObj ~= nil and perc.CanSeeWorldObject ~= nil
                        and perc.CanSeeWorldObject(rec, losObj) == true
                    if vis then
                        ev, act, bark = "combat_ally_warn_reply_engaging", "ACK", "bark.alert_hey"
                    else
                        ev, act, bark = "combat_ally_warn_reply_alerted", "ACK", "bark.alert_hey"
                    end
                end
                if sec and type(sec.RequestBark) == "function" then
                    sec.RequestBark(rec, bark, now)
                end
                local profile = profileMod and profileMod.Build and profileMod.Build(rec, "", {
                    role = "ally", actorKind = "npc", inCombat = true,
                }) or {}
                local tone = Service.ResolveAllyWarnTone(rec, profile)
                local callerRec = entry.callerRecord
                    or (reg and type(reg.Get) == "function" and reg.Get(entry.callerId))
                    or { id = entry.callerId, name = entry.callerName }
                local tokens = type(Service.BuildRichSpeechTokens) == "function"
                    and Service.BuildRichSpeechTokens(rec, callerRec, entry.desc, now, tone) or nil
                local tClass = entry.desc and entry.desc.semanticClass or "human_hostile"
                local text, resolved = Service.ResolveSemanticLine(
                    rec, ev, act, tClass, entry.eventRef, profile, tokens
                )
                if text then
                    local presClass = resolved and resolved.presentationClass or "BARK"
                    Service.DeliverBark(rec, now, {
                        eventType = ev,
                        speechEventID = resolved and resolved.realizationID or ("semantic." .. ev),
                        act = act,
                        family = "combat_ally_warn_reply",
                        eventRef = entry.eventRef,
                        text = text,
                        priority = 75,
                        cooldownMs = 3500,
                        familyCooldownMs = 3500,
                        maxSpeakers = 1,
                        streamKey = "ally-warn-reply:" .. tostring(rec.id),
                        presentationClass = presClass,
                        context = {
                            eventType = ev,
                            eventRef = entry.eventRef,
                            presentationClass = presClass,
                            transient = true,
                            targetLabel = tokens and tokens["target.name"] or nil,
                            targetCount = tokens and tonumber(tokens["target.count"]) or nil,
                            locationLabel = tokens and tokens["scene.location"] or nil,
                            callerName = tokens and tokens["addressee.name"] or nil,
                        },
                    })
                end
                fired = fired + 1
            end
        end
    end
    Service.PendingReplies = remaining
    Service.PendingReplyCount = #remaining
    return fired
end

function Service.ResetRuntime()
    Service.PendingReplies = {}
    Service.PendingReplyCount = 0
end

return Service
