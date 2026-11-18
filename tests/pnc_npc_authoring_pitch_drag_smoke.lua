local T = require 'tests/support/test'
T.addPackagePaths()
PNC = { Identity = {} }
T.load('ProjectHoomans', 'shared', 'PNC/Core/Identity/PNC_Identity_Appearance.lua')
ISPNCUniqueNPCAppearanceWindow = { Internal = { Appearance = PNC.Identity.Appearance, setLabelText = function() end, tr = function(_, fallback) return fallback end } }
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Editing.lua')
local commits = 0
local e = setmetatable({ draft = { identity = { survivor = {} },
    appearance = { voice = { mode = 'item', prefix = 'VoiceMale', pitch = 0 } } },
    voicePitchValue = { setName = function(self, value) self.name = value end },
}, { __index = ISPNCUniqueNPCAppearanceWindow })
function e:markChanged() commits = commits + 1 end
for value = -100, 100 do e:onVoicePitchChanged(value) end
T.equal(commits, 0, 'drag callbacks do not rebuild the editor while the mouse moves')
T.equal(e.draft.identity.survivor.voicePitch, 100, 'pending endpoint is preserved')
e:commitPendingVoice()
T.equal(commits, 1, 'mouse-release boundary commits the final pitch once')
e:commitPendingVoice()
T.equal(commits, 1, 'outside/inside release callbacks do not duplicate the commit')
e.draft.appearance.voice = { mode = 'random' }
function e:voiceProfile() return { prefix = 'VoiceMale', voiceType = 1, pitch = 0 } end
e:onVoicePitchChanged(-50)
T.equal(e.draft.appearance.voice.prefix, 'VoiceMale', 'editing a generated voice starts from its effective profile')
T.equal(e.draft.appearance.voice.pitch, -50, 'a current generated voice can accept an explicit pitch edit')
e:commitPendingVoice()
T.equal(commits, 2, 'generated voice edit follows the same release commit boundary')
T.finish('pnc_npc_authoring_pitch_drag_smoke')
