-- Presentation metadata only; native/mod body-location IDs remain canonical.
local Parts = {}
local definitions = {
    { id = 'head', key = 'Head', label = 'Head and face', tokens = 'fullsuithead|head|helmet|mask|hood|hat|eyes|eye|ears|ear|nose' },
    { id = 'neck', key = 'Neck', label = 'Neck', tokens = 'necklace|neck|scarf|gorget' },
    { id = 'torso', key = 'Torso', label = 'Torso and layers', tokens = 'underwearbra|underweartop|underweartorso|hoodedponcho|sweaterhood|shirt|vest|jacket|torso|suit|sweater|dress|robe|poncho' },
    { id = 'hands', key = 'Hands', label = 'Hands and jewelry', tokens = 'forearm|hand|glove|finger|wrist' },
    { id = 'waist', key = 'Waist', label = 'Waist and holsters', tokens = 'belt|holster|ammo|strap' },
    { id = 'legs', key = 'Legs', label = 'Legs', tokens = 'pants|trousers|skirt|leg|thigh|knee|calf|shorts|underwear' },
    { id = 'feet', key = 'Feet', label = 'Feet', tokens = 'shoe|sock|foot|boot' },
    { id = 'back', key = 'Back', label = 'Back and bags', tokens = 'back|bag|fanny|webbing' },
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
