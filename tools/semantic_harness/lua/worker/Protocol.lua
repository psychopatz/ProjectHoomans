-- Bounded JSON-lines protocol for the semantic harness worker.
--
-- This module intentionally has no dependency on Project Zomboid or the
-- mutable harness runtime. It can therefore be loaded before production Lua
-- modules and tested independently through the worker boundary.

local Protocol = {
    VERSION = 1,
    MAX_MESSAGE_BYTES = 256 * 1024,
}

local function jsonEscape(value)
    value = tostring(value or "")
    value = string.gsub(value, "\\", "\\\\")
    value = string.gsub(value, '"', '\\"')
    value = string.gsub(value, "\n", "\\n")
    value = string.gsub(value, "\r", "\\r")
    value = string.gsub(value, "\t", "\\t")
    value = string.gsub(value, "[%z\1-\31]", function(character)
        return string.format("\\u%04x", string.byte(character))
    end)
    return value
end

local function isArray(value)
    local count = 0
    local maximum = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false, 0
        end
        count = count + 1
        if key > maximum then maximum = key end
    end
    return count == maximum, maximum
end

local function jsonEncode(value)
    local valueType = type(value)
    if value == nil then return "null" end
    if valueType == "boolean" then return value and "true" or "false" end
    if valueType == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "null"
        end
        return tostring(value)
    end
    if valueType == "string" then
        return '"' .. jsonEscape(value) .. '"'
    end
    if valueType ~= "table" then return "null" end
    local array, maximum = isArray(value)
    local output = {}
    if array then
        for index = 1, maximum do
            output[#output + 1] = jsonEncode(value[index])
        end
        return "[" .. table.concat(output, ",") .. "]"
    end
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[#output + 1] = '"' .. jsonEscape(key) .. '":'
                .. jsonEncode(item)
        end
    end
    return "{" .. table.concat(output, ",") .. "}"
end

local function jsonDecode(source)
    local index = 1

    local function skipWhitespace()
        while true do
            local character = string.sub(source, index, index)
            if character == " " or character == "\t"
                or character == "\r" or character == "\n"
            then
                index = index + 1
            else
                return
            end
        end
    end

    local function utf8Character(codepoint)
        if codepoint <= 127 then
            return string.char(codepoint)
        elseif codepoint <= 2047 then
            return string.char(
                192 + math.floor(codepoint / 64),
                128 + (codepoint % 64)
            )
        elseif codepoint <= 65535 then
            return string.char(
                224 + math.floor(codepoint / 4096),
                128 + (math.floor(codepoint / 64) % 64),
                128 + (codepoint % 64)
            )
        elseif codepoint <= 1114111 then
            return string.char(
                240 + math.floor(codepoint / 262144),
                128 + (math.floor(codepoint / 4096) % 64),
                128 + (math.floor(codepoint / 64) % 64),
                128 + (codepoint % 64)
            )
        end
        error("invalid_unicode_codepoint")
    end

    local function parseString()
        if string.sub(source, index, index) ~= '"' then
            error("expected_string")
        end
        index = index + 1
        local output = {}
        while true do
            local character = string.sub(source, index, index)
            if character == "" then error("unterminated_string") end
            if character == '"' then
                index = index + 1
                return table.concat(output)
            end
            if character == "\\" then
                index = index + 1
                local escaped = string.sub(source, index, index)
                local replacements = {
                    ['"'] = '"',
                    ["\\"] = "\\",
                    ["/"] = "/",
                    ["b"] = string.char(8),
                    ["f"] = string.char(12),
                    ["n"] = "\n",
                    ["r"] = "\r",
                    ["t"] = "\t",
                }
                if replacements[escaped] then
                    output[#output + 1] = replacements[escaped]
                    index = index + 1
                elseif escaped == "u" then
                    local digits = string.sub(source, index + 1, index + 4)
                    if not string.match(digits, "^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
                        error("invalid_unicode_escape")
                    end
                    output[#output + 1] = utf8Character(tonumber(digits, 16))
                    index = index + 5
                else
                    error("invalid_escape")
                end
            else
                if string.byte(character) < 32 then
                    error("control_character_in_string")
                end
                output[#output + 1] = character
                index = index + 1
            end
        end
    end

    local parseValue

    local function parseArray()
        index = index + 1
        local output = {}
        skipWhitespace()
        if string.sub(source, index, index) == "]" then
            index = index + 1
            return output
        end
        while true do
            output[#output + 1] = parseValue()
            skipWhitespace()
            local character = string.sub(source, index, index)
            if character == "]" then
                index = index + 1
                return output
            end
            if character ~= "," then error("expected_array_separator") end
            index = index + 1
            skipWhitespace()
        end
    end

    local function parseObject()
        index = index + 1
        local output = {}
        skipWhitespace()
        if string.sub(source, index, index) == "}" then
            index = index + 1
            return output
        end
        while true do
            local key = parseString()
            skipWhitespace()
            if string.sub(source, index, index) ~= ":" then
                error("expected_object_separator")
            end
            index = index + 1
            output[key] = parseValue()
            skipWhitespace()
            local character = string.sub(source, index, index)
            if character == "}" then
                index = index + 1
                return output
            end
            if character ~= "," then error("expected_object_separator") end
            index = index + 1
            skipWhitespace()
        end
    end

    local function parseNumber()
        local tail = string.sub(source, index)
        local token = string.match(tail, "^-?%d+%.?%d*[eE]?[+-]?%d*")
        if not token or token == "" then error("invalid_number") end
        local value = tonumber(token)
        if value == nil then error("invalid_number") end
        index = index + #token
        return value
    end

    parseValue = function()
        skipWhitespace()
        local character = string.sub(source, index, index)
        if character == '"' then return parseString() end
        if character == "{" then return parseObject() end
        if character == "[" then return parseArray() end
        if character == "-" or string.match(character, "%d") then
            return parseNumber()
        end
        if string.sub(source, index, index + 3) == "true" then
            index = index + 4
            return true
        end
        if string.sub(source, index, index + 4) == "false" then
            index = index + 5
            return false
        end
        if string.sub(source, index, index + 3) == "null" then
            index = index + 4
            return nil
        end
        error("invalid_json_value")
    end

    local value = parseValue()
    skipWhitespace()
    if index <= #source then error("trailing_json_data") end
    return value
end

function Protocol.encode(value)
    return jsonEncode(value)
end

function Protocol.decode(source)
    return jsonDecode(source)
end

function Protocol.emit(value, requestID)
    if type(value) ~= "table" then value = { value = value } end
    value.protocolVersion = Protocol.VERSION
    if requestID then value.id = requestID end
    io.write(jsonEncode(value) .. "\n")
    io.flush()
end

function Protocol.fail(requestID, message)
    Protocol.emit({ ok = false, error = tostring(message or "worker_error") }, requestID)
end

function Protocol.readRequest(source)
    if #source > Protocol.MAX_MESSAGE_BYTES then
        return nil, "request_too_large"
    end
    local ok, value = pcall(jsonDecode, source)
    if not ok or type(value) ~= "table" then
        return nil, tostring(value or "invalid_request")
    end
    if value.protocolVersion ~= Protocol.VERSION then
        return nil, "unsupported_protocol_version"
    end
    if type(value.id) ~= "string" or value.id == "" then
        return nil, "request_id_required"
    end
    if type(value.command) ~= "string" or value.command == "" then
        return nil, "request_command_required"
    end
    return value
end

return Protocol
