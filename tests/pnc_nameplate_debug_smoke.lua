local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "client", "")

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

T.load(ROOT .. "PNC/UI/Nameplates/PNC_NameplateDebug.lua")
T.load(ROOT .. "PNC/UI/Nameplates/PNC_NameplatePresentation.lua")

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
T.equal(filtered, "Target: zombie", "component filtering")
T.falsy(string.find(tostring(filtered), tostring("AI:"), 1, true), "hidden AI component")
T.falsy(string.find(tostring(filtered), tostring("Weapon:"), 1, true), "hidden combat component")

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
T.contains(combatSummary, "Intent: auto/melee",
    "combat intent summary")
T.contains(combatSummary, "Tactic: lone_threat_counter",
    "combat tactic summary")
T.contains(combatSummary, "ViewZ: 1/2",
    "visible zombie summary")

snapshot.campResourceDebug = {
    mode = "activity",
    campId = "camp:trailhead",
    resourceRadius = 12,
    bedCount = 2,
    waterCount = 1,
    otherCount = 0,
    facilities = {
        {
            detectorId = "bed",
            resourceKind = "sleep_surface",
            resourceKey = "bed:10:20:0",
            x = 10.5, y = 20.5, z = 0,
        },
        {
            detectorId = "faucet",
            resourceKind = "water_source",
            resourceKey = "faucet:11:20:0:1",
            x = 11.5, y = 20.5, z = 0,
        },
    },
    activity = {
        capability = "sleep",
        phase = "WORKING",
        resourceKind = "sleep_surface",
        resourceKey = "bed:10:20:0",
        sleepSurface = "bed",
        abstract = true,
    },
}
local campText = PNC.NameplateDebug.CampResourceText(snapshot, {
    showCampDebug = true,
})
T.contains(campText, "Camp: activity", "camp activity overlay mode")
T.contains(campText, "Task: SLEEP", "camp task summary")
T.contains(campText, "Phase: WORKING", "camp phase summary")
T.falsy(string.find(campText, "found=", 1, true),
    "camp nameplate omits facility dump counts")
T.falsy(string.find(campText, "bed:10:20:0", 1, true),
    "camp nameplate omits resource coordinates and keys")
T.equal(PNC.NameplateDebug.CampResourceText(snapshot, {
    showCampDebug = false,
}), "", "camp overlay component disabled")
local campOnlyText = PNC.NameplateDebug.BuildText(snapshot, true, {
    showCampDebug = true,
    debugShowPresence = false,
    debugShowAI = false,
    debugShowJob = false,
    debugShowOrder = false,
    debugShowTarget = false,
    debugShowCombat = false,
    debugShowMagazine = false,
    debugShowStamina = false,
    debugShowBlock = false,
})
T.equal(campOnlyText, campText, "camp overlay is independently rendered")
T.equal(PNC.NameplateDebug.BuildText(snapshot, true, {
    showCampDebug = true,
}), campText, "camp overlay does not enable AI debug text")

local infected = PNC.NameplateDebug.InfectionText(snapshot, {
    debugShowInfection = true,
})
T.contains(infected, "INFECTED: YES", "infection marker")
T.contains(infected, "Stage: fever", "infection stage")
T.contains(infected, "Fever: 72%", "infection fever")
T.contains(infected, "Temp: 39.6 C", "infection temperature")
T.equal(PNC.NameplateDebug.InfectionText(snapshot, {
    debugShowInfection = false,
}), "", "infection component disabled")

snapshot.bodyHealth.infection.active = false
snapshot.bodyHealth.infection.fatal = false
snapshot.bodyHealth.infection.pendingFatal = false
T.equal(PNC.NameplateDebug.InfectionText(snapshot, {
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
T.contains(sceneLine, "SCENE idle.ambient", "scene overlay ID")
T.contains(sceneLine, "policy=loop", "scene overlay repeat policy")
T.contains(sceneLine, "step=2/4:smell_gag", "scene overlay queue")
T.contains(sceneLine, "rev=4:2", "scene overlay playback revision")
T.contains(sceneTrackLine, "req=SmellGag", "scene requested bump")
T.contains(sceneTrackLine, "actual=PNC_SmellGag", "scene actual bump")
T.contains(sceneTrackLine, "clip=Bob_EmoteSmellGag", "scene clip")
T.contains(sceneTrackLine, "frame@30=15", "scene frame")

snapshot.treatmentState = {
    phase = "bandaging",
    partId = "Hand_L",
    bandageType = "Base.RippedSheets",
    bandageName = "Ripped Sheets",
}
local treatmentText = PNC.NameplatePresentation.TreatmentStatus(snapshot)
T.contains(treatmentText, "Bandaging Left Hand", "active treatment body part")
T.contains(treatmentText, "Ripped Sheets", "active treatment material")
snapshot.treatmentState.phase = "idle"
snapshot.bodyHealth.wounds = {
    Hand_L = {
        bandaged = true,
        bandageDirty = true,
        bandageName = "Bandage",
    },
}
treatmentText = PNC.NameplatePresentation.TreatmentStatus(snapshot)
T.contains(treatmentText, "Dirty bandage", "dirty treatment marker")
T.contains(treatmentText, "Bandage", "dirty treatment material")

PNC.FacilityDefinitions = { Get = function(id)
    return id == "barracks" and {
        displayNameKey = "UI_PNC_Facility_Barracks",
    } or nil
end }
snapshot.actionInformation = { kind = "work_order",
    operation = "CONSTRUCT", status = "WORKING", percent = 10,
    facilityDefinitionId = "barracks" }
local actionText = PNC.NameplatePresentation.ActionStatus(snapshot)
T.contains(actionText, "Building", "work action verb")
T.contains(actionText, "barracks", "work action target")
T.contains(actionText, "10%", "work action progress")
snapshot.actionInformation = { kind = "work_order",
    operation = "BUILD_OBJECT", status = "WORKING", percent = 57,
    objectInfoName = "crafted_04_116", buildDisplayName = "Log Fence" }
actionText = PNC.NameplatePresentation.ActionStatus(snapshot)
T.contains(actionText, "Building", "object build action verb")
T.contains(actionText, "Log Fence", "object build action target")
T.contains(actionText, "57%", "object build action progress")
snapshot.actionInformation = { kind = "return_home", percent = 35 }
actionText = PNC.NameplatePresentation.ActionStatus(snapshot)
T.contains(actionText, "Returning Home", "home travel action")
T.contains(actionText, "35%", "home travel progress")
snapshot.actionInformation = { kind = "at_home" }
actionText = PNC.NameplatePresentation.ActionStatus(snapshot)
T.contains(actionText, "Idle", "idle-at-home action")
snapshot.actionInformation = {
    kind = "activity",
    activityId = "facility:sleep",
    labelKey = "UI_PNC_Activity_Sleeping",
    fallback = "Sleeping",
    phase = "SLEEPING",
    facilityDefinitionId = "barracks",
}
actionText = PNC.NameplatePresentation.ActionStatus(snapshot)
T.contains(actionText, "Sleeping", "facility activity label")
T.contains(actionText, "barracks", "facility activity target")
snapshot.actionInformation = {
    kind = "activity",
    activityId = "facility:survival.eat.inventory",
    labelKey = "UI_PNC_Activity_Eating",
    fallback = "Eating",
    phase = "STARTING",
    activityItemFullType = "Base.Apple",
    activityItemLabelKey = "UI_PNC_Action_FoodTarget",
}
getText = function(key)
    if key == "UI_PNC_Action_FoodTarget" then return "food" end
    if key == "UI_PNC_Activity_Eating" then return "Eating" end
    return key
end
getItemNameFromFullType = function(fullType)
    return fullType == "Base.Apple" and "Apple" or fullType
end
actionText = PNC.NameplatePresentation.ActionStatus(snapshot)
T.contains(actionText, "Eating", "eating activity label")
T.contains(actionText, "Apple", "eating activity item")
T.contains(actionText, "preparing", "eating activity phase")
snapshot.actionInformation = {
    kind = "work_order",
    operation = "PROVISION_PICKUP",
    status = "TRAVEL_TO_STOCKPILE",
    percent = 0,
    activityItemFullType = "Base.Apple",
}
actionText = PNC.NameplatePresentation.ActionStatus(snapshot)
T.contains(actionText, "Grabbing", "provision pickup action verb")
T.contains(actionText, "Apple", "provision pickup actual item")
snapshot.actionInformation = {
    kind = "activity",
    activityId = "job:GuardAnchor",
    fallback = "Guard Anchor",
}
actionText = PNC.NameplatePresentation.ActionStatus(snapshot)
T.contains(actionText, "Guard Anchor", "generic job activity fallback")
snapshot.actionInformation = nil

local entriesSource = T.read(
    "ProjectHoomans", "client", "PNC/UI/Nameplates/PNC_NameplateEntries.lua"
)
T.falsy(string.find(tostring(entriesSource), tostring("hpText"), 1, true), "numeric HP cache returned")

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
            tacticalClass = "hostile",
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
T.load(T.path("ProjectHoomans", "client", "PNC/Knowledge/PNC_NPCIdentityPresentation.lua"))
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
T.load("ProjectHoomans", "client", "PNC/UI/Nameplates/PNC_NameplateEntries.lua")
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
T.contains(factionLine1, "Mill Looters",
    "faction nameplate organization")
T.contains(factionLine2, "war=true",
    "faction nameplate war state")
T.contains(factionLine2, "attack=true",
    "faction nameplate resolved attack")
T.contains(factionLine3, "order=hostile_hunt",
    "faction nameplate tactical order")
T.equal(factionTone, "danger",
    "faction nameplate hostile tone")
T.contains(relationshipLine, "A=+12.0",
    "relationship nameplate approval")
T.contains(relationshipLine, "state=neutral",
    "relationship nameplate state")
T.contains(relationshipChangeLine,
    "CHANGE treated_wound [social_event]",
    "relationship nameplate change type")
T.contains(relationshipChangeLine, "dA=+4.0",
    "relationship nameplate approval delta")
T.contains(relationshipChangeLine,
    "unknown>neutral",
    "relationship nameplate state transition")
T.equal(relationshipTone, "neutral",
    "relationship nameplate current tone")
T.equal(relationshipChangeTone, "success",
    "relationship nameplate positive change tone")

local rendererSource = T.read(
    "ProjectHoomans", "client",
    "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer.lua"
)
T.falsy(string.find(tostring(rendererSource), tostring("entry.hpText"), 1, true), "numeric HP rendering returned")

T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer.lua"
)
T.truthy(
    type(PNC.NameplateRenderer.Render) == "function",
    "canonical renderer entry loads its public API"
)
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
T.contains(pathLines[1], "NAV local/engine_path", "path algorithm")
T.contains(pathLines[1], "native_path_moving", "native path state")
T.contains(pathLines[1], "engine_native", "native movement owner")
T.contains(pathLines[1], "window_climb", "path action edge")
T.contains(pathLines[2], "np=4", "path non-progress counter")
T.contains(pathLines[2], "rt=3", "path retarget counter")
T.contains(pathLines[2], "turn=90", "path turn angle")
T.contains(pathLines[3], "no_goal_progress", "path block reason")
T.contains(
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
T.contains(combatLines[1], "COMBAT ranged", "combat mode")
T.contains(combatLines[1], "clearing_fire_lane", "combat decision")
T.contains(combatLines[2], "pressure=3/4", "visible pressure")
T.contains(combatLines[2], "tol=2", "pressure tolerance")
T.contains(combatLines[2], "horde=5/7", "visible horde")
T.contains(combatLines[3], "d=3.5", "live target distance")
T.contains(combatLines[3], "ACTIVE", "active threat")
T.contains(combatLines[4], "aim=72%", "aim confidence")
T.contains(combatLines[4], "lane=BLOCKED:npc", "friendly fire blocker")
T.contains(combatLines[4], "ammo=5/15", "combat ammo")
T.contains(combatLines[5], "ACTION ranged/ranged", "attack timing")
T.contains(
    combatLines[5],
    "via=wasBumped+bumped_state",
    "attack animation trigger"
)
T.contains(combatLines[5], "state=bumped", "attack action state")
T.contains(combatLines[6], "MOVE strafe/walk", "tactical movement")

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
T.contains(viewLines[3], "VIEW zombies=2/3",
    "combat view counts")
T.contains(viewLines[3], "intent=auto",
    "combat attack intent")
T.contains(viewLines[4], "target=npc[Alex] via=aggro_lease",
    "zombie NPC target identity")
T.contains(viewLines[5], "target=none",
    "zombie without target identity")
T.contains(viewLines[3], "biteLane=bite_lane_wall",
    "blocked zombie attack lane")
T.contains(viewLines[4], "id=z1 d=1.2 mode=selected",
    "selected visible zombie detail")
T.contains(viewLines[5], "id=z2 d=2.0 mode=biting",
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
T.contains(
    animationLine,
    "req=PNC_Attack1H1",
    "live animation request"
)
T.contains(
    animationLine,
    "bump=Attack1H1",
    "live engine bump"
)
T.contains(
    animationLine,
    "state=bumped",
    "live action state"
)
T.contains(
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
T.contains(
    animationTrackLine,
    "clip=Bob_Attack1Hand01_Hit",
    "visible animation track"
)
T.contains(
    animationTrackLine,
    "slot=0:1",
    "visible animation slot"
)
T.contains(
    animationTrackLine,
    "frame@30=12",
    "live animation frame"
)
T.contains(
    animationTrackLine,
    "weight=1.000",
    "visible animation blend weight"
)
PNC.AnimationTrace = {
    GetOverlayLine = function()
        return "TRACE #7 fail=action_handoff_missing"
    end,
}
T.contains(
    PNC.NameplateRenderer.BuildAnimationTraceDebugLine({}),
    "fail=action_handoff_missing",
    "retained animation trace overlay"
)

local renderedLines = 0
local renderedGeometry = {
    cone = 0,
    target = 0,
    blocker = 0,
    movement = 0,
}
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
    drawLine2 = function(_, _, _, _, _, _, r, g, b)
        renderedLines = renderedLines + 1
        if math.abs(r - 0.25) < 0.001
            and math.abs(g - 0.90) < 0.001
            and math.abs(b - 1.00) < 0.001
        then
            renderedGeometry.cone = renderedGeometry.cone + 1
        elseif math.abs(r - 1.00) < 0.001
            and math.abs(g - 0.22) < 0.001
            and math.abs(b - 0.16) < 0.001
        then
            renderedGeometry.target = renderedGeometry.target + 1
        elseif math.abs(r - 1.00) < 0.001
            and math.abs(g - 0.15) < 0.001
            and math.abs(b - 0.80) < 0.001
        then
            renderedGeometry.blocker = renderedGeometry.blocker + 1
        elseif math.abs(r - 0.50) < 0.001
            and math.abs(g - 1.00) < 0.001
            and math.abs(b - 0.30) < 0.001
        then
            renderedGeometry.movement = renderedGeometry.movement + 1
        end
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
T.truthy(renderedLines > 0, "combat geometry was not rendered")
T.truthy(renderedGeometry.cone > 0, "combat cone was not rendered")
T.truthy(renderedGeometry.target > 0, "combat target marker was not rendered")
T.truthy(renderedGeometry.blocker > 0, "fire-lane blocker was not rendered")
T.truthy(renderedGeometry.movement > 0, "tactical movement was not rendered")
local renderedTextJoined = table.concat(renderedText, "\n")
T.contains(
    renderedTextJoined,
    "COMBAT ranged",
    "combat label rendered"
)
T.contains(
    renderedTextJoined,
    "ZED -> Alex Mercer | zed=attacker-zed",
    "zombie attacker target name rendered"
)
T.contains(
    renderedTextJoined,
    "state=bumped bump=Bite",
    "zombie attacker action graph rendered"
)

getCore = function()
    return { getZoom = function() return 1 end }
end
getTimeInMillis = function() return 1000 end
local speechDraws = {}
TextDrawObject = {
    new = function()
        local object = {}
        object.setDefaultColors = function(_, r, g, b, a)
            object.defaultColor = { r = r, g = g, b = b, a = a }
        end
        object.setOutlineColors = function(_, r, g, b, a)
            object.outlineColor = { r = r, g = g, b = b, a = a }
        end
        object.ReadString = function(_, font, text, maxChars)
            object.font = font
            object.text = text
            object.maxChars = maxChars
        end
        object.getHeight = function() return 36 end
        object.Draw = function(_, x, y, outlines, alpha)
            speechDraws[#speechDraws + 1] = {
                object = object,
                x = x,
                y = y,
                outlines = outlines,
                alpha = alpha,
            }
        end
        return object
    end,
}
local positionedText = {}
PNC.NameplatePresentation.DrawOutlinedText = function(_, text, x, y)
    positionedText[#positionedText + 1] = { text = text, x = x, y = y }
end
local liveRenderManager = {
    playerIndex = 0,
    x = 0,
    y = 0,
    player = {
        getX = function() return 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    },
    clearStencilRect = function() end,
    entries = {
        {
            debugOnly = false,
            zombie = {
                isDead = function() return false end,
                getX = function() return 0 end,
                getY = function() return 0 end,
                getZ = function() return 0 end,
            },
            snapshot = { healthState = "normal" },
            name = "Replying NPC",
            nameWidth = 60,
            nameColor = { r = 1, g = 1, b = 1, a = 1 },
            healthVisible = false,
            staminaVisible = false,
            speechText = "This reply wraps across several lines.",
            speechTextWidth = 120,
            speechVisible = true,
            speech = {
                message = {
                    presentationState = {
                        speechColor = { r = 255, g = 128, b = 32, a = 1 },
                    },
                },
            },
            actionVisible = true,
            actionText = "Working 50%",
            actionTextWidth = 66,
            actionColor = { r = 0.35, g = 0.88, b = 1, a = 1 },
        },
    },
}
PNC.NameplateRenderer.Render(liveRenderManager, { enabled = true })
T.equal(#speechDraws, 1, "speech text object was rendered")
T.equal(speechDraws[1].object.font, "Medium",
    "nameplate reply uses the larger player font")
T.equal(speechDraws[1].object.maxChars, 42,
    "nameplate reply uses bounded wrapping")
T.equal(speechDraws[1].object.defaultColor.g, 128 / 255,
    "nameplate reply keeps message color")
T.equal(speechDraws[1].object.outlineColor.r, 0,
    "nameplate reply has a dark text glow")
T.equal(speechDraws[1].y, -205,
    "wrapped reply is anchored above the activity line")
T.equal(positionedText[1].text, "Working 50%",
    "activity text remains rendered separately")
T.equal(positionedText[1].y, -166,
    "activity text keeps its reserved slot")

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
T.truthy(overlayManager.entries["unknown-npc"] ~= nil,
    "debug scope keeps an undisclosed NPC in the render set")
T.falsy(overlayManager.entries["unknown-npc"].scopes.identity,
    "debug scope does not disclose NPC identity")
T.truthy(overlayManager.entries["unknown-npc"].scopes.debug,
    "debug scope is independently enabled")
T.falsy(overlayManager.entries["unknown-npc"].actionVisible,
    "debug scope does not promote activity text")
T.equal(overlayManager.entries["unknown-npc"].name,
    "Unknown survivor",
    "undisclosed identity remains private in entry data")

PNC.NameplateSpeech.SetPending(
    "unknown-npc",
    "other-npc-request",
    "other-npc-conversation"
)
overlayManager.updateCounter = 5
PNC.NameplateEntries.Refresh(overlayManager, {
    enabled = true,
    showAIDebug = false,
    debugShowAnimation = false,
})
T.truthy(overlayManager.entries["unknown-npc"] ~= nil,
    "active speech keeps an undisclosed NPC in the render set")
T.truthy(overlayManager.entries["unknown-npc"].speech
    and overlayManager.entries["unknown-npc"].speech.pending,
    "other-NPC loading state reaches the nameplate pipeline")
T.falsy(overlayManager.entries["unknown-npc"].scopes.identity,
    "conversation scope does not disclose NPC identity")
T.falsy(overlayManager.entries["unknown-npc"].scopes.debug,
    "conversation scope does not enable debug text")
T.truthy(overlayManager.entries["unknown-npc"].scopes.conversation,
    "conversation scope is independently enabled")
T.falsy(overlayManager.entries["unknown-npc"].actionVisible,
    "conversation scope does not promote activity text")
T.equal(overlayManager.entries["unknown-npc"].speechText, ".",
    "other-NPC loading state uses the shared typing indicator")

local conversationOnlyManager = {
    playerIndex = 0,
    x = 0,
    y = 0,
    player = liveRenderManager.player,
    clearStencilRect = function() end,
    entries = {
        {
            debugOnly = false,
            scopes = {
                identity = false,
                debug = false,
                conversation = true,
            },
            zombie = zombie,
            snapshot = { healthState = "normal" },
            name = "Unknown survivor",
            nameWidth = 90,
            nameColor = { r = 1, g = 1, b = 1, a = 1 },
            healthVisible = true,
            staminaVisible = true,
            speechText = "Only the conversation scope is visible.",
            speechTextWidth = 120,
            speechVisible = true,
            speech = {
                message = {
                    presentationState = {
                        speechColor = { r = 80, g = 220, b = 255, a = 1 },
                    },
                },
            },
            actionVisible = true,
            actionText = "Working 50%",
            actionTextWidth = 66,
            actionColor = { r = 0.35, g = 0.88, b = 1, a = 1 },
        },
    },
}
local speechCountBefore = #speechDraws
local textCountBefore = #positionedText
PNC.NameplateRenderer.Render(conversationOnlyManager, { enabled = true })
T.equal(#speechDraws, speechCountBefore + 1,
    "conversation-only entry still renders speech")
T.equal(#positionedText, textCountBefore,
    "conversation-only entry does not render identity or activity")

local debugOnlyManager = {
    playerIndex = 0,
    x = 0,
    y = 0,
    player = liveRenderManager.player,
    clearStencilRect = function() end,
    entries = {
        {
            debugOnly = true,
            scopes = {
                identity = false,
                debug = true,
                conversation = false,
            },
            worldX = 2,
            worldY = 2,
            worldZ = 0,
            name = "Unknown survivor",
            nameWidth = 90,
            nameColor = { r = 1, g = 1, b = 1, a = 1 },
            debugText = "AI: combat",
            debugTextWidth = 60,
        },
    },
}
local debugTextCountBefore = #positionedText
PNC.NameplateRenderer.Render(debugOnlyManager, {
    enabled = true,
    showAIDebug = true,
})
T.equal(#positionedText, debugTextCountBefore + 1,
    "debug-only entry renders its independent overlay")
T.equal(positionedText[#positionedText].text, "AI: combat",
    "debug-only entry does not render the undisclosed identity")
PNC.NameplateSpeech.ClearPending("unknown-npc", "other-npc-request")
T.finish("pnc_nameplate_debug_smoke")

T.finish("pnc_nameplate_debug_smoke")
