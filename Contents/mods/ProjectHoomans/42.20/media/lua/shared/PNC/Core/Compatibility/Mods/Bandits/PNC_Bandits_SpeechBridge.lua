-- Bandits native speech transport bridge.
--
-- Hoomans only asks the adapter to present an external phrase. Bandits
-- remains the owner of speech cooldowns, captions, audio, and audience/range
-- rules. This is a transport boundary, not a Project Hoomans wording owner.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}
PNC.Compatibility.Bandits.SpeechBridge =
    PNC.Compatibility.Bandits.SpeechBridge or {}

local Bridge = PNC.Compatibility.Bandits.SpeechBridge

function Bridge.Say(actor, phrase, force)
    if not actor or not Bandit or type(Bandit.Say) ~= "function"
        or not Bandit.SoundTab
        or not Bandit.SoundTab[phrase]
    then
        return false
    end
    Bandit.Say(actor, phrase, force)
    return true
end

return Bridge
