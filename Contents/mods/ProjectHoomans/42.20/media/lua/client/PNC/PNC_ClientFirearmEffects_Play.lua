local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then return end

local Internal = Effects.Internal or {}
local Deps = Internal.PlayDeps or {}
local NativeEffects = Deps.NativeEffects
local nowMs = Deps.nowMs
local readMethod = Deps.readMethod
local logFirearmAudit = Deps.logFirearmAudit
local recordNativeFailure = Deps.recordNativeFailure
local resolveBody = Deps.resolveBody
local resolveWeapon = Deps.resolveWeapon
local hasLiveAnchor = Deps.hasLiveAnchor
local getMuzzlePosition = Deps.getMuzzlePosition
local addMuzzleFlash = Deps.addMuzzleFlash
local spawnLight = Deps.spawnLight
local playShotAudio = Deps.playShotAudio
local addTracer = Deps.addTracer
local playImpact = Deps.playImpact

function Effects.Play(payload)
    local shotId
    local body
    local weapon
    local x
    local y
    local z
    local nativeResult
    local nativeReason
    local lightResult
    local lightReason
    local lightX
    local lightY
    local lightZ
    local audioResult
    local tracerCount
    local muzzleCount
    local muzzleEffect
    local tracerEffect
    local impactResult
    local startedAt = nowMs()
    local anchoredFallback
    if type(payload) ~= "table" then
        logFirearmAudit("play_rejected", nil,
            "reason=payload_not_table",
            "elapsedMs=" .. tostring(nowMs() - startedAt))
        return false
    end
    shotId = tostring(payload.shotId or "")
    logFirearmAudit("play_start", payload,
        "weapon=" .. tostring(payload.weaponFullType or ""),
        "position=" .. tostring(payload.sx or "") .. ","
            .. tostring(payload.sy or "") .. "," .. tostring(payload.sz or ""))
    if shotId ~= "" and Effects.SeenShots[shotId] then
        logFirearmAudit("play_duplicate", payload, "reason=shot_already_seen")
        return false
    end
    if shotId ~= "" then
        Effects.SeenShots[shotId] = (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    end
    body = resolveBody(payload)
    weapon = resolveWeapon(body, payload)
    -- A shooter whose nameplate is being tracked uses Hoomans' own firearm
    -- effect path, because the native B42 tracer API accepts a body/endpoint
    -- but cannot be handed our bore line. Untracked/off-screen shooters keep
    -- the native engine path. Whichever path runs, the origin comes from the
    -- world-space barrel tip, so the line leaves the gun rather than the
    -- nameplate anchor.
    anchoredFallback = hasLiveAnchor(body, payload)
    logFirearmAudit("anchor_route", payload,
        "live=" .. tostring(anchoredFallback),
        "route=" .. (anchoredFallback and "nameplate_relative" or "native"))
    logFirearmAudit("body_weapon_resolved", payload,
        "body=" .. tostring(body ~= nil),
        "weapon=" .. tostring(weapon ~= nil),
        "weaponType=" .. tostring(weapon and readMethod(weapon, "getFullType") or ""))
    if anchoredFallback then
        nativeResult, nativeReason = false, "nameplate_anchor_preferred"
    else
        nativeResult, nativeReason = NativeEffects.PlayMuzzleFlash(body, weapon)
    end
    logFirearmAudit("muzzle_native_complete", payload,
        "result=" .. tostring(nativeResult),
        "reason=" .. tostring(nativeReason or ""))
    if not nativeResult then
        if not anchoredFallback then recordNativeFailure(nativeReason) end
        x, y, z = getMuzzlePosition(body, weapon, payload)
        muzzleCount = addMuzzleFlash(body, payload, x, y, z)
        muzzleEffect = muzzleCount > 0
            and Effects.ActiveMuzzleFlashes[#Effects.ActiveMuzzleFlashes]
            or nil
        logFirearmAudit("muzzle_visual_queue_complete", payload,
            "result=" .. tostring(muzzleCount > 0),
            "queued=" .. tostring(muzzleCount),
            "active=" .. tostring(#Effects.ActiveMuzzleFlashes),
            "muzzle=" .. tostring(x or "") .. "," .. tostring(y or "")
                .. "," .. tostring(z or ""),
            "anchorSource=" .. tostring(
                muzzleEffect and muzzleEffect.anchorSource or "none"
            ))
        lightResult, lightReason, lightX, lightY, lightZ = spawnLight(
            body,
            payload,
            x,
            y,
            z
        )
        logFirearmAudit("muzzle_light_complete", payload,
            "result=" .. tostring(lightResult),
            "reason=" .. tostring(lightReason or ""),
            "square=" .. tostring(lightX or "") .. ","
                .. tostring(lightY or "") .. "," .. tostring(lightZ or ""))
    end
    audioResult = playShotAudio(body, weapon, payload)
    logFirearmAudit("audio_complete", payload,
        "result=" .. tostring(audioResult),
        "sound=" .. tostring(payload.shotSound or ""),
        "shellSound=" .. tostring(payload.shellFallSound or ""))
    if anchoredFallback then
        nativeResult, nativeReason = false, "nameplate_anchor_preferred"
    else
        nativeResult, nativeReason = NativeEffects.PlayTracer(body, weapon, payload)
    end
    logFirearmAudit("tracer_native_complete", payload,
        "result=" .. tostring(nativeResult),
        "reason=" .. tostring(nativeReason or ""))
    if not nativeResult then
        if not anchoredFallback then recordNativeFailure(nativeReason) end
        if not x then
            x, y, z = getMuzzlePosition(body, weapon, payload)
        end
        tracerCount = addTracer(body, payload, x, y, z)
        tracerEffect = tracerCount > 0
            and Effects.ActiveTracers[#Effects.ActiveTracers]
            or nil
        logFirearmAudit("tracer_screen_queue_complete", payload,
            "result=" .. tostring(tracerCount > 0),
            "queued=" .. tostring(tracerCount),
            "active=" .. tostring(#Effects.ActiveTracers),
            "muzzle=" .. tostring(x or "") .. "," .. tostring(y or "")
                .. "," .. tostring(z or ""),
            "anchorSource=" .. tostring(
                tracerEffect and tracerEffect.anchorSource or "none"
            ))
    end
    impactResult = playImpact(payload)
    logFirearmAudit("impact_audio_complete", payload,
        "result=" .. tostring(impactResult),
        "impactSound=" .. tostring(payload.impactSound or ""))
    logFirearmAudit("play_complete", payload,
        "elapsedMs=" .. tostring(nowMs() - startedAt),
        "activeTracers=" .. tostring(#Effects.ActiveTracers))
    return true
end
