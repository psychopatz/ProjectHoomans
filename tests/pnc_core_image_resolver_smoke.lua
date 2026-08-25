local T = require "tests/support/test"
T.addPackagePaths({ { "PsychopatzCore", "client" } })

PsychopatzCore = { UI = {} }
local nativeTexture = { id = "native" }
local nativeInfo = {
    getIconTexture = function() return nativeTexture end,
}
tryGetTexture = function(path)
    return path == "media/ui/test.png" and { id = "png" } or nil
end
getTexture = function(path) return { id = "fallback:" .. tostring(path) } end

local Resolver = T.load("PsychopatzCore", "client",
    "PsychopatzCore/UI/Components/PsychopatzImageResolver.lua")
T.equal(Resolver.Resolve({ nativeObjectInfo = nativeInfo }), nativeTexture,
    "native object texture resolves")
T.equal(Resolver.Resolve({ iconPath = "media/ui/test.png" }).id, "png",
    "png texture resolves through tryGetTexture")
T.equal(Resolver.Resolve("media/ui/fallback.png").id,
    "fallback:media/ui/fallback.png", "path fallback resolves")

local drawn
local element = {
    drawTextureScaledAspect = function(_, texture, x, y, width, height, alpha)
        drawn = { texture, x, y, width, height, alpha }
    end,
}
Resolver.Draw(element, { iconTexture = nativeInfo }, 1, 2, 3, 4, 0.5)
T.equal(drawn[1], nativeTexture, "draw uses resolved texture")
T.equal(drawn[4], 3, "draw preserves caller dimensions")
T.equal(drawn[6], 0.5, "draw preserves caller alpha")
T.finish("pnc_core_image_resolver_smoke")
