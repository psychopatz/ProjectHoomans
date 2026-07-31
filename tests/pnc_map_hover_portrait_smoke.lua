local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Map/"
        .. "PNC_MapHoverPortrait.lua"

package.preload["PNC/UI/Map/PNC_MapHoverPortraitCard"] =
    function() return true end

local portraitCreateCount = 0
local portraitTargetCount = 0
local portraitOptions
local portraitTarget
local portraitContext
local clock = 1000

PNC = {
    Core = {
        Now = function() return clock end,
    },
    MapHoverPortraitCard = {
        FaceZoom = 18,
        FaceYOffset = -0.85,
        DebugBackground = false,
        new = function(card, x, y, size, options)
            portraitCreateCount = portraitCreateCount + 1
            portraitOptions = options
            local panel = {
                x = x,
                y = y,
                width = size,
                height = size + options.nameHeight,
                portraitZoom = card.FaceZoom,
                portraitYOffset = card.FaceYOffset,
                debugBackground = card.DebugBackground,
            }
            function panel:initialise() end
            function panel:instantiate() end
            function panel:setVisible(value) self.visible = value end
            function panel:setContext(entry)
                portraitContext = entry
            end
            function panel:setTarget(spec)
                portraitTargetCount = portraitTargetCount + 1
                portraitTarget = spec
                return true
            end
            function panel:setCardPosition(px, py)
                self.x = px
                self.y = py
            end
            return panel
        end,
    },
}

dofile(FILE)

local map = {
    width = 500,
    height = 500,
    children = {},
    addChild = function(self, child)
        self.children[#self.children + 1] = child
    end,
}
local portraitEntry = {
    id = "npc_portrait",
    portrait = {
        identitySeed = 7,
        revision = 1,
        isFemale = true,
        appearance = { hairModel = "Long" },
        equipment = { worn = { Hat = "Base.Hat_HardHat" } },
    },
}

assert(PNC.MapHoverPortrait.Update(map, portraitEntry, 100, 100)
    == false, "portrait ignored hover stabilization delay")
clock = 1090
assert(PNC.MapHoverPortrait.Update(map, portraitEntry, 100, 100),
    "portrait was not shown after hover delay")
assert(portraitCreateCount == 1,
    "hover portrait did not lazily create exactly one renderer")
assert(map.pncHoverPortrait.width == 128
    and map.pncHoverPortrait.height == 152
    and portraitOptions.portraitZoom == nil
    and portraitOptions.portraitYOffset == nil
    and portraitOptions.debugBackground == nil
    and map.pncHoverPortrait.pncLayoutVersion == 8,
    "hover portrait card did not use the enlarged full-box layout")
assert(portraitTarget.id == portraitEntry.id
    and portraitTarget.preferDescriptor == true
    and portraitTarget.faceOnly == true
    and portraitTarget.equipment == nil,
    "hover portrait did not use descriptor rendering")
assert(portraitContext == portraitEntry,
    "hover portrait card did not receive NPC badge/name context")
clock = 1200
assert(PNC.MapHoverPortrait.Update(map, portraitEntry, 120, 120),
    "same portrait did not remain reusable")
assert(portraitCreateCount == 1,
    "same hover allocated another portrait renderer")
assert(portraitTargetCount == 1,
    "stable hover rebound the same portrait descriptor")
portraitEntry.portrait.revision = 2
clock = 1210
assert(PNC.MapHoverPortrait.Update(map, portraitEntry, 120, 120),
    "updated portrait metadata was not displayed")
assert(portraitTargetCount == 2,
    "updated portrait metadata did not rebind the descriptor")

local secondEntry = {
    id = "npc_portrait_2",
    portrait = {
        identitySeed = 8,
        revision = 1,
        appearance = { hairModel = "Messy" },
        equipment = { worn = {} },
    },
}
clock = 1300
assert(PNC.MapHoverPortrait.Update(map, secondEntry, 130, 130)
    == false, "new portrait bypassed hover stabilization")
clock = 1390
assert(PNC.MapHoverPortrait.Update(map, secondEntry, 130, 130),
    "second portrait did not appear after stabilization")
assert(portraitCreateCount == 1,
    "switching NPCs allocated another portrait renderer")
assert(portraitTarget.id == secondEntry.id,
    "reused portrait renderer did not switch descriptor")
assert(portraitTargetCount == 3,
    "portrait descriptor was rebound more than once per NPC")
assert(map.pncHoverPortrait.x == 66,
    "portrait card was not horizontally centered over the map marker")
assert(map.pncHoverPortrait.y == -30,
    "portrait card was not kept directly above the map marker")

PNC.MapHoverPortraitCard.FaceZoom = 17
clock = 1400
assert(PNC.MapHoverPortrait.Update(map, secondEntry, 130, 130),
    "camera tuning did not rebuild the visible portrait card")
assert(portraitCreateCount == 2
    and map.pncHoverPortrait.portraitZoom == 17,
    "camera tuning remained stuck on the previous portrait card")
assert(portraitTargetCount == 4
    and portraitTarget.id == secondEntry.id,
    "rebuilt portrait card did not restore its NPC descriptor")

PNC.MapHoverPortrait.Hide(map)
assert(map.pncHoverPortrait.visible == false,
    "hover portrait remained visible after hover ended")

print("pnc_map_hover_portrait_smoke: ok")
