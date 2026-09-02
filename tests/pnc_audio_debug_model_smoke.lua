local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Core = {},
    NPCVoice = {},
}

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

Registries = {
    SOUND_KEY = {
        values = function()
            return javaList({ "AcousticGuitarBreak" })
        end,
    },
}

GameSounds = {
    getCategories = function()
        return javaList({ "Debug" })
    end,
    getSoundsInCategory = function(category)
        T.equal(category, "Debug", "SFX category was not forwarded")
        return javaList({
            {
                getName = function() return "UI_Click" end,
                getCategory = function() return "Debug" end,
            },
        })
    end,
    isKnownSound = function(name) return name == "UI_Click" end,
    previewSound = function(name) T.equal(name, "UI_Click", "SFX name") end,
    stopPreview = function() end,
}

local Model = T.load("ProjectHoomans", "client",
    "PNC/UI/PNC_AudioDebugModel.lua")

local voiceEvents = Model.GetVoiceEvents()
T.truthy(#voiceEvents >= 40, "base voice event catalog is unexpectedly small")
T.truthy(voiceEvents[1].suffix, "voice event suffix missing")

local sfx = Model.GetSFXCatalog()
T.equal(#sfx, 1, "SFX catalog did not enumerate sounds")
T.equal(sfx[1].name, "UI_Click", "SFX name was not read")
T.truthy(Model.PlaySFX("UI_Click"), "known SFX did not play")

T.finish("pnc_audio_debug_model_smoke")
