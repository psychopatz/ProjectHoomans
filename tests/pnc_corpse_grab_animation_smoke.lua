local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local registered = {}
local sequenceDefinitions = {}
local variables = {}

PNC = {
    AnimationScenes = {
        Register = function(id, definition)
            registered[id] = definition
            return true
        end,
    },
    WorkSequence = {
        Register = function(operation, definition)
            sequenceDefinitions[operation] = definition
            return true
        end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Production/PNC_WorkAnimationScenes.lua")

local grab = registered["production.corpse_grab"]
local drop = registered["production.corpse_drop"]
local xml = T.read("ProjectHoomans", "common",
    "AnimSets/zombie/bumped/PNC_Anim_ZombieBiteLow.xml")
local body = {
    setVariable = function(_, name, value) variables[name] = value end,
}

T.truthy(grab, "corpse grab scene is registered")
T.equal(grab.bump, "BiteLow",
    "corpse grab uses the low bite bump requested by the animation graph")
T.equal(grab.durationMs, 900, "corpse grab keeps a one-shot duration")
T.truthy(type(grab.onStart) == "function",
    "corpse grab enables its animation selector condition")
T.truthy(type(grab.onStop) == "function",
    "corpse grab clears its animation selector condition")
T.truthy(grab.onStart(nil, body, nil, 0),
    "corpse grab start callback succeeds")
T.equal(variables.PNCZombieBitingNPC, true,
    "corpse grab enables the ZombieBiteLow selector condition")
grab.onStop(nil, body, nil, "completed")
T.equal(variables.PNCZombieBitingNPC, false,
    "corpse grab clears the ZombieBiteLow selector condition")

T.truthy(drop, "corpse drop scene remains registered")
T.equal(drop.bump, "Loot", "corpse drop keeps the looting placement animation")
T.contains(xml, "<m_Name>PNC_Anim_ZombieBiteLow</m_Name>",
    "corpse grab XML node exists")
T.contains(xml, "<m_AnimName>Zombie_BiteLow_Success</m_AnimName>",
    "corpse grab uses the successful low bite animation")
T.contains(xml, "<m_StringValue>PNC_BiteLow</m_StringValue>",
    "corpse grab resolves to the PNC low bite bump type")
T.contains(xml, "<m_Name>PNCZombieBitingNPC</m_Name>",
    "corpse grab XML requires its selector condition")

local corpseActions = sequenceDefinitions.CORPSE_HAUL.actions
T.equal(corpseActions.GRAB_PENDING.sceneId, "production.corpse_grab",
    "corpse work sequence points to the low bite grab scene")
T.equal(corpseActions.DROP_PENDING.sceneId, "production.corpse_drop",
    "corpse work sequence keeps a separate drop scene")

T.finish("pnc_corpse_grab_animation_smoke")
