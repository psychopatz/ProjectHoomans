local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/client/"

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
    NPCWounds = {
        Parts = {
            Hand_L = { label = "Left Hand" },
        },
    },
}
UIFont = { Small = "Small", Medium = "Medium" }

dofile(ROOT .. "PNC/UI/Nameplates/PNC_NameplateDebug.lua")
dofile(ROOT .. "PNC/UI/Nameplates/PNC_NameplatePresentation.lua")

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

snapshot.combatDebugState = {
    attackType = "auto",
    mode = "melee",
    decision = "lone_threat_counter",
    visibleZombieCount = 1,
    nearbyZombieCount = 2,
}
local combatSummary = PNC.NameplateDebug.BuildText(snapshot, true, {
    debugShowPresence = false,
    debugShowAI = false,
    debugShowJob = false,
    debugShowOrder = false,
    debugShowTarget = false,
    debugShowCombat = true,
    debugShowMagazine = false,
    debugShowStamina = false,
    debugShowBlock = false,
})
assertContains(combatSummary, "Intent: auto/melee",
    "combat intent summary")
assertContains(combatSummary, "Tactic: lone_threat_counter",
    "combat tactic summary")
assertContains(combatSummary, "ViewZ: 1/2",
    "visible zombie summary")

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

snapshot.visualState = {
    sceneActive = true,
    sceneId = "idle.ambient",
    sceneBump = "SmellGag",
    sceneRevision = 4,
    scenePlaybackRevision = 2,
    sceneStepId = "smell_gag",
    sceneStepPosition = 2,
    sceneStepCount = 4,
    sceneSequenceIteration = 3,
    sceneRepeatMode = "loop",
}
local sceneBody = {
    getCurrentActionContextStateName = function()
        return "bumped"
    end,
    getAnimationStateName = function()
        return "bumped"
    end,
    getBumpType = function()
        return "PNC_SmellGag"
    end,
    isAnimationUpdatingThisFrame = function()
        return true
    end,
    dbgGetAnimTrackName = function(_, layer, track)
        if layer == 0 and track == 0 then
            return "Bob_EmoteSmellGag"
        end
        return ""
    end,
    dbgGetAnimTrackTime = function()
        return 0.5
    end,
    dbgGetAnimTrackWeight = function()
        return 1
    end,
}
local sceneLine
local sceneTrackLine
sceneLine, sceneTrackLine =
    PNC.NameplateDebug.AnimationSceneText(
        sceneBody,
        snapshot
    )
assertContains(sceneLine, "SCENE idle.ambient", "scene overlay ID")
assertContains(sceneLine, "policy=loop", "scene overlay repeat policy")
assertContains(sceneLine, "step=2/4:smell_gag", "scene overlay queue")
assertContains(sceneLine, "rev=4:2", "scene overlay playback revision")
assertContains(sceneTrackLine, "req=SmellGag", "scene requested bump")
assertContains(sceneTrackLine, "actual=PNC_SmellGag", "scene actual bump")
assertContains(sceneTrackLine, "clip=Bob_EmoteSmellGag", "scene clip")
assertContains(sceneTrackLine, "frame@30=15", "scene frame")

snapshot.treatmentState = {
    phase = "bandaging",
    partId = "Hand_L",
    bandageType = "Base.RippedSheets",
    bandageName = "Ripped Sheets",
}
local treatmentText = PNC.NameplatePresentation.TreatmentStatus(snapshot)
assertContains(treatmentText, "Bandaging Left Hand", "active treatment body part")
assertContains(treatmentText, "Ripped Sheets", "active treatment material")
snapshot.treatmentState.phase = "idle"
snapshot.bodyHealth.wounds = {
    Hand_L = {
        bandaged = true,
        bandageDirty = true,
        bandageName = "Bandage",
    },
}
treatmentText = PNC.NameplatePresentation.TreatmentStatus(snapshot)
assertContains(treatmentText, "Dirty bandage", "dirty treatment marker")
assertContains(treatmentText, "Bandage", "dirty treatment material")

local entriesPath = ROOT .. "PNC/UI/Nameplates/PNC_NameplateEntries.lua"
local entriesFile = assert(io.open(entriesPath, "r"))
local entriesSource = entriesFile:read("*a")
entriesFile:close()
assertNotContains(entriesSource, "hpText", "numeric HP cache returned")

PNC.NameplateBodies = {}
PNC.Network = { ClientState = { snapshots = {} } }
PNC.FactionDebugOverlay = {
    GetNPCDiagnostic = function()
        return {
            factionName = "Mill Looters",
            archetypeID = "looter",
            role = "raider",
            rank = "member",
            relationState = "war",
            atWarWithPlayer = true,
            intent = "attack",
            intentReason = "factions_at_war",
            attackAllowed = true,
            legacyFaction = "hostile",
            attackPlayers = true,
            attackNPCs = true,
            attackZombies = true,
            orderKind = "hostile_hunt",
            activeJob = "HuntNearestPlayer",
            relationship = {
                approval = 12,
                respect = 8,
                familiarity = 6,
                state = "neutral",
                revision = 2,
            },
            morale = 3,
        }
    end,
    GetRelationshipChange = function()
        return {
            kind = "social_event",
            memoryType = "treated_wound",
            knowledgeSource = "experienced",
            approvalDelta = 4,
            respectDelta = 2,
            familiarityDelta = 1,
            moraleDelta = 1,
            stateBefore = "unknown",
            stateAfter = "neutral",
        }, 1
    end,
}
dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Knowledge/PNC_NPCIdentityPresentation.lua")
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
dofile(entriesPath)
local factionLine1
local factionLine2
local factionLine3
local relationshipLine
local relationshipChangeLine
local factionTone
local relationshipTone
local relationshipChangeTone
factionLine1,
factionLine2,
factionLine3,
relationshipLine,
relationshipChangeLine,
factionTone,
relationshipTone,
relationshipChangeTone =
    PNC.NameplateEntries.BuildFactionDebugLines(
        { id = "npc_debug" },
        { showFactionDebug = true }
    )
assertContains(factionLine1, "Mill Looters",
    "faction nameplate organization")
assertContains(factionLine2, "war=true",
    "faction nameplate war state")
assertContains(factionLine2, "attack=true",
    "faction nameplate resolved attack")
assertContains(factionLine3, "order=hostile_hunt",
    "faction nameplate tactical order")
assertEqual(factionTone, "danger",
    "faction nameplate hostile tone")
assertContains(relationshipLine, "A=+12.0",
    "relationship nameplate approval")
assertContains(relationshipLine, "state=neutral",
    "relationship nameplate state")
assertContains(relationshipChangeLine,
    "CHANGE treated_wound [social_event]",
    "relationship nameplate change type")
assertContains(relationshipChangeLine, "dA=+4.0",
    "relationship nameplate approval delta")
assertContains(relationshipChangeLine,
    "unknown>neutral",
    "relationship nameplate state transition")
assertEqual(relationshipTone, "neutral",
    "relationship nameplate current tone")
assertEqual(relationshipChangeTone, "success",
    "relationship nameplate positive change tone")

local rendererPath = ROOT .. "PNC/UI/Nameplates/PNC_NameplateRenderer.lua"
local rendererFile = assert(io.open(rendererPath, "r"))
local rendererSource = rendererFile:read("*a")
rendererFile:close()
assertNotContains(rendererSource, "entry.hpText", "numeric HP rendering returned")

dofile(rendererPath)
local pathLines = PNC.NameplateRenderer.BuildPathDebugLines({
    navigationPolicy = "local",
    navigationProvider = "engine_path",
    navigationPlanReason = "native_path_moving",
    navigationSteeringKind = "engine_native",
    navigationTraversalKind = "window_climb",
    movePhase = "active",
    moveMode = "walk",
    moveLastStep = "slide_preferred",
    moveGoalDistance = 0.82,
    moveNonProgressSteps = 4,
    moveRetargetCount = 3,
    moveSteeringTurnDot = 0,
    moveBlockReason = "no_goal_progress",
    navigationInvalidationReason = "fake_locomotion_stalled",
})
assertContains(pathLines[1], "NAV local/engine_path", "path algorithm")
assertContains(pathLines[1], "native_path_moving", "native path state")
assertContains(pathLines[1], "engine_native", "native movement owner")
assertContains(pathLines[1], "window_climb", "path action edge")
assertContains(pathLines[2], "np=4", "path non-progress counter")
assertContains(pathLines[2], "rt=3", "path retarget counter")
assertContains(pathLines[2], "turn=90", "path turn angle")
assertContains(pathLines[3], "no_goal_progress", "path block reason")
assertContains(
    pathLines[3],
    "fake_locomotion_stalled",
    "path replan reason"
)

local combatLines = PNC.NameplateRenderer.BuildCombatDebugLines({
    mode = "ranged",
    decision = "clearing_fire_lane",
    surroundedCount = 1,
    pressureCount = 4,
    visiblePressureCount = 3,
    pressureTolerance = 2,
    hordeCount = 7,
    visibleHordeCount = 5,
    targetCrowdCount = 3,
    target = {
        kind = "zombie",
        distSq = 16,
        visible = true,
        visibilityKind = "clear",
        threatening = true,
    },
    aimConfidence = 0.72,
    aimReadyInMs = 180,
    fireLaneSafe = false,
    fireLaneBlocker = { kind = "npc" },
    magazineCount = 5,
    magazineCapacity = 15,
    action = {
        attackType = "ranged",
        attackKind = "ranged",
        anim = "PNC_AttackRifle",
        animationRetries = 1,
        animationTriggerMode = "wasBumped+bumped_state",
        animationActionState = "bumped",
        hitRemainingMs = 120,
        finishRemainingMs = 420,
    },
    tacticalMove = {
        phase = "strafe",
        mode = "walk",
        reason = "clearing_fire_lane",
        lockRemainingMs = 300,
    },
}, 3.5)
assertContains(combatLines[1], "COMBAT ranged", "combat mode")
assertContains(combatLines[1], "clearing_fire_lane", "combat decision")
assertContains(combatLines[2], "pressure=3/4", "visible pressure")
assertContains(combatLines[2], "tol=2", "pressure tolerance")
assertContains(combatLines[2], "horde=5/7", "visible horde")
assertContains(combatLines[3], "d=3.5", "live target distance")
assertContains(combatLines[3], "ACTIVE", "active threat")
assertContains(combatLines[4], "aim=72%", "aim confidence")
assertContains(combatLines[4], "lane=BLOCKED:npc", "friendly fire blocker")
assertContains(combatLines[4], "ammo=5/15", "combat ammo")
assertContains(combatLines[5], "ACTION ranged/ranged", "attack timing")
assertContains(
    combatLines[5],
    "via=wasBumped+bumped_state",
    "attack animation trigger"
)
assertContains(combatLines[5], "state=bumped", "attack action state")
assertContains(combatLines[6], "MOVE strafe/walk", "tactical movement")

local viewLines = PNC.NameplateRenderer.BuildCombatDebugLines({
    mode = "melee",
    attackType = "auto",
    decision = "melee_commit_window",
    visibleZombieCount = 2,
    nearbyZombieCount = 3,
    tacticalState = "retreat",
    retreatPhase = "retreat",
    retreatReason = "near_miss_kite",
    biteLaneClear = false,
    biteLaneReason = "bite_lane_wall",
    viewZombies = {
        {
            id = "z1",
            distSq = 1.44,
            intent = "selected",
            actionState = "walktoward",
            visibilityKind = "clear",
            targetKind = "npc",
            targetId = "npc-a",
            targetName = "Alex",
            targetSource = "aggro_lease",
        },
        {
            id = "z2",
            distSq = 4,
            intent = "biting",
            actionState = "bumped",
            visibilityKind = "clear",
            bumpType = "Bite",
        },
    },
})
assertContains(viewLines[3], "VIEW zombies=2/3",
    "combat view counts")
assertContains(viewLines[3], "intent=auto",
    "combat attack intent")
assertContains(viewLines[4], "target=npc[Alex] via=aggro_lease",
    "zombie NPC target identity")
assertContains(viewLines[5], "target=none",
    "zombie without target identity")
assertContains(viewLines[3], "biteLane=bite_lane_wall",
    "blocked zombie attack lane")
assertContains(viewLines[4], "id=z1 d=1.2 mode=selected",
    "selected visible zombie detail")
assertContains(viewLines[5], "id=z2 d=2.0 mode=biting",
    "biting visible zombie detail")

local animationLine =
    PNC.NameplateRenderer.BuildBodyAnimationDebugLine({
        getModData = function()
            return {
                PNC_ClientAttackRequestedAnim =
                    "PNC_Attack1H1",
                PNC_BumpActionLease = true,
            }
        end,
        getActionStateName = function() return "bumped" end,
        getBumpType = function() return "Attack1H1" end,
        isUseless = function() return true end,
        isMoving = function() return false end,
        isSneaking = function() return false end,
        getVariableBoolean = function() return false end,
    }, {
        anim = "PNC_Attack1H1",
    })
assertContains(
    animationLine,
    "req=PNC_Attack1H1",
    "live animation request"
)
assertContains(
    animationLine,
    "bump=Attack1H1",
    "live engine bump"
)
assertContains(
    animationLine,
    "state=bumped",
    "live action state"
)
assertContains(
    animationLine,
    "useless=true",
    "live body mode"
)
local animationTrackLine =
    PNC.NameplateRenderer.BuildAnimationTrackDebugLine({
        getCurrentActionContextStateName = function()
            return "bumped"
        end,
        getAnimationStateName = function()
            return "bumped"
        end,
        isAnimationUpdatingThisFrame = function()
            return true
        end,
        dbgGetAnimTrackName = function(_, layer, track)
            if layer == 0 and track == 0 then
                return "Bob_IdleBat"
            end
            if layer == 0 and track == 1 then
                return "Bob_Attack1Hand01_Hit"
            end
            return ""
        end,
        dbgGetAnimTrackTime = function(_, layer, track)
            return track == 1 and 0.42 or 0.75
        end,
        dbgGetAnimTrackWeight = function(_, layer, track)
            return track == 1 and 1.0 or 0.0
        end,
    })
assertContains(
    animationTrackLine,
    "clip=Bob_Attack1Hand01_Hit",
    "visible animation track"
)
assertContains(
    animationTrackLine,
    "slot=0:1",
    "visible animation slot"
)
assertContains(
    animationTrackLine,
    "frame@30=12",
    "live animation frame"
)
assertContains(
    animationTrackLine,
    "weight=1.000",
    "visible animation blend weight"
)
PNC.AnimationTrace = {
    GetOverlayLine = function()
        return "TRACE #7 fail=action_handoff_missing"
    end,
}
assertContains(
    PNC.NameplateRenderer.BuildAnimationTraceDebugLine({}),
    "fail=action_handoff_missing",
    "retained animation trace overlay"
)

local renderedLines = 0
local renderedText = {}
isoToScreenX = function(_, x, y) return (x - y) * 32 end
isoToScreenY = function(_, x, y, z)
    return (x + y) * 16 - z * 96
end
getTextManager = function()
    return {
        getFontHeight = function() return 12 end,
        MeasureStringX = function(_, _, text) return #text * 6 end,
    }
end
PNC.NameplatePresentation.DrawOutlinedText =
    function(_, text)
        renderedText[#renderedText + 1] = text
    end
local manager = {
    playerIndex = 0,
    x = 0,
    y = 0,
    drawLine2 = function()
        renderedLines = renderedLines + 1
    end,
}
local forward = {
    getX = function() return 1 end,
    getY = function() return 0 end,
}
local zombie = {
    isDead = function() return false end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getForwardDirection = function() return forward end,
}
local attackerZombie = {
    isDead = function() return false end,
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getActionStateName = function() return "bumped" end,
    getBumpType = function() return "Bite" end,
    getPath2 = function() return nil end,
}
PNC.Perception = {
    FindZombieByID = function(id)
        if id == "attacker-zed" then
            return attackerZombie
        end
        return nil
    end,
}
PNC.NameplateRenderer.RenderCombatDebug(manager, {
    zombie = zombie,
    snapshot = {
        attackMode = true,
        combatDebugState = {
            mode = "ranged",
            decision = "clearing_fire_lane",
            zombieAttacker = {
                zombieId = "attacker-zed",
                targetKind = "npc",
                targetId = "npc-debug",
                targetName = "Alex Mercer",
                phase = "windup",
                ageMs = 40,
                x = 1,
                y = 0,
                z = 0,
                actionState = "bumped",
                bumpType = "Bite",
                path2Active = false,
            },
            target = {
                kind = "zombie",
                id = "z1",
                x = 4,
                y = 0,
                z = 0,
                visible = true,
            },
            fireLaneSafe = false,
            fireLaneBlocker = {
                kind = "npc",
                id = "ally",
                x = 2,
                y = 0,
                z = 0,
            },
            tacticalMove = {
                phase = "strafe",
                reason = "clearing_fire_lane",
                x = 0,
                y = 2,
                z = 0,
                mode = "walk",
            },
            meleeRange = 1.3,
            rangedPreferredDistance = 5,
            rangedRange = 8.5,
            pressureRadius = 3,
            hordeRadius = 5.5,
            coneRadius = 8.5,
            coneHalfAngleDegrees = 55,
        },
    },
})
assert(renderedLines > 80, "combat geometry was not rendered")
local renderedTextJoined = table.concat(renderedText, "\n")
assertContains(
    renderedTextJoined,
    "COMBAT ranged",
    "combat label rendered"
)
assertContains(
    renderedTextJoined,
    "ZED -> Alex Mercer | zed=attacker-zed",
    "zombie attacker target name rendered"
)
assertContains(
    renderedTextJoined,
    "state=bumped bump=Bite",
    "zombie attacker action graph rendered"
)

local unknownBody = {
    getX = function() return 2 end,
    getY = function() return 2 end,
    getZ = function() return 0 end,
}
PNC.NameplateBodies.Index = function() return {} end
PNC.NameplateBodies.Resolve = function(_, uuid)
    return uuid == "unknown-npc" and unknownBody or nil
end
PNC.NameplateBodies.Tag = function() end
PNC.Network.ClientState.snapshots = {
    ["unknown-npc"] = {
        id = "unknown-npc",
        name = "Secret Name",
        alive = true,
        presenceState = "LIVE",
        x = 2,
        y = 2,
        z = 0,
        hpCurrent = 100,
        hpMax = 100,
        staminaCurrent = 100,
        staminaMax = 100,
        healthState = "normal",
        debugState = { aiState = "Combat" },
    },
}
getPlayerScreenLeft = function() return 0 end
getPlayerScreenTop = function() return 0 end
getPlayerScreenWidth = function() return 1280 end
getPlayerScreenHeight = function() return 720 end
getTimeInMillis = function() return 1000 end
getCell = function()
    return { getZombieList = function() return {} end }
end
getSpecificPlayer = function()
    return {
        getX = function() return 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
end
local overlayManager = {
    playerIndex = 0,
    entries = {},
    updateCounter = 5,
    setX = function() end,
    setY = function() end,
    setWidth = function() end,
    setHeight = function() end,
}
PNC.NameplateEntries.Refresh(overlayManager, {
    enabled = true,
    showAIDebug = true,
    debugShowAnimation = false,
})
assert(overlayManager.entries["unknown-npc"] ~= nil,
    "debug overlay stayed hidden until the name introduction")
assertEqual(overlayManager.entries["unknown-npc"].name,
    "Unknown survivor",
    "debug overlay leaked an undisclosed NPC name")

print("pnc_nameplate_debug_smoke: ok")
