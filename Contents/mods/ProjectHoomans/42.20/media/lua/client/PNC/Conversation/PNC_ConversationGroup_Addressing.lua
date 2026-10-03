local Group = PNC.Conversation.Group
local Internal = Group.Internal
local memberFor = Internal.MemberFor
local normalizedName = Internal.NormalizedName

local function collectIDs(self, value, output, depth)
    if type(value) ~= "table" then return end
    depth = tonumber(depth) or 0
    if depth >= 5 then return end
    local id = value.id or value.entityID or value.npcID
    id = tostring(id or "")
    if id ~= "" and memberFor(self, id) then output[id] = true end
    for key, child in pairs(value) do
        if type(child) == "table"
            and (key == "target" or key == "recipient"
                or key == "actor" or key == "destination")
        then
            collectIDs(self, child, output, depth + 1)
        end
    end
end

function Group:AddressedIDs(result, rawText)
    local addressed = {}
    local ir = result and result.ir or nil
    if type(ir) == "table" then
        collectIDs(self, ir.target, addressed, 0)
        collectIDs(self, ir.recipient, addressed, 0)
        collectIDs(self, ir.destination, addressed, 0)
    end
    local count = 0
    for _ in pairs(addressed) do count = count + 1 end
    if count > 0 then return addressed end

    local normalized = normalizedName(rawText, self.entityResolver)
    if normalized == "" then return addressed end
    local padded = " " .. normalized .. " "
    for index = 1, #self.members do
        local member = self.members[index]
        local aliases = { member.firstName, member.name }
        for aliasIndex = 1, #aliases do
            local alias = normalizedName(aliases[aliasIndex], self.entityResolver)
            if alias ~= ""
                and string.find(padded, " " .. alias .. " ", 1, true)
            then
                addressed[member.id] = true
                break
            end
        end
    end
    return addressed
end

function Group:ShouldRespond(member, result, rawText)
    local addressed = self:AddressedIDs(result, rawText)
    local hasAddress = false
    for _ in pairs(addressed) do
        hasAddress = true
        break
    end
    if not hasAddress then return true end
    return addressed[member.id] == true
end

