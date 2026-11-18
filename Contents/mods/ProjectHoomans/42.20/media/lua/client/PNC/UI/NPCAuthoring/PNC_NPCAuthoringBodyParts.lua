-- Presentation metadata only; native/mod body-location IDs remain canonical.
local Parts = {}
local definitions = {
    { id = 'head', key = 'Head', label = 'Head and face', tokens = 'fullsuithead|scba|head|helmet|mask|hood|hat|makeup|lipstick|eyeshadow|lefteye|righteye|eyes|eye|ears|ear|nose' },
    { id = 'neck', key = 'Neck', label = 'Neck', tokens = 'necklace|neck|scarf|gorget' },
    { id = 'torso', key = 'Torso', label = 'Torso and layers', tokens = 'underwearbra|underweartop|underweartorso|hoodedponcho|sweaterhood|tshirt|shortsleeveshirt|jersey|fulltop|tanktop|shoulderholster|shoulderpad|vesttexture|leftarm|rightarm|elbow|wound|bandage|bodycostume|boilersuit|cuirass|shirt|vest|jacket|torso|suit|sweater|dress|robe|poncho' },
    { id = 'hands', key = 'Hands', label = 'Hands and jewelry', tokens = 'forearm|hand|glove|ringfinger|middlefinger|finger|leftwrist|rightwrist|wrist|bracelet' },
    { id = 'waist', key = 'Waist', label = 'Waist and holsters', tokens = 'belt|holster|ammo|strap|bellybutton|codpiece|tail' },
    { id = 'legs', key = 'Legs', label = 'Legs', tokens = 'pants|trousers|skirt|leg|thigh|knee|gaiter|calf|shorts|underwear' },
    { id = 'feet', key = 'Feet', label = 'Feet', tokens = 'ankleholster|shoe|sock|foot|boot' },
    { id = 'back', key = 'Back', label = 'Back and bags', tokens = 'back|bag|fanny|webbing|satchel' },
    { id = 'other', key = 'Other', label = 'Other equipment', tokens = '' },
    { id = 'held', key = 'Held', label = 'Held items and attachments', tokens = '' },
    { id = 'carry', key = 'Carried', label = 'Carried items', tokens = '' },
}
function Parts.All() return definitions end
function Parts.Group(location)
    local suffix = string.match(tostring(location or ''), '([^:]+)$') or ''
    local words = ' ' .. string.lower(string.gsub(string.gsub(suffix, '([a-z])([A-Z])', '%1 %2'), '[^%w]+', ' ')) .. ' '
    local raw = string.gsub(words, '[^%w]', '')
    local best, score = definitions[9], 0
    for _, group in ipairs(definitions) do
        for token in string.gmatch(group.tokens, '[^|]+') do
            if #token > score and (string.sub(raw, 1, #token) == token or string.find(words, ' ' .. token .. ' ', 1, true)) then best, score = group, #token end
        end
    end
    return best
end
return Parts
