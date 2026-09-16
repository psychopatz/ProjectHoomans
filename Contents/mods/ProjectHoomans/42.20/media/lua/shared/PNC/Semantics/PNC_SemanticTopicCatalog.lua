-- Project Hoomans topic enrichment.
--
-- Topics are conversational continuity hints, not gameplay intents.  They
-- are deliberately data-driven so a new topic can be added without changing
-- the Core parser or dialogue state implementation.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.TopicCatalog or {}
PNC.Semantics.TopicCatalog = Catalog

Catalog.VERSION = 1
Catalog.AUTHORED_CATEGORY_TOPICS = Catalog.AUTHORED_CATEGORY_TOPICS or {
    ["projecthoomans:greetings"] = "greeting",
    ["projecthoomans:whats_up"] = "whats_up",
    ["projecthoomans:wellbeing"] = "wellbeing",
    ["projecthoomans:small_talk"] = "small_talk",
    ["projecthoomans:ask_about"] = "ask_about",
    ["projecthoomans:needs"] = "needs",
    ["projecthoomans:work_orders"] = "work_orders",
    ["projecthoomans:trade"] = "trade",
    ["projecthoomans:personal"] = "personal",
    ["projecthoomans:relationship"] = "relationship",
    ["projecthoomans:set_territory"] = "set_territory",
    ["projecthoomans:goodbye"] = "goodbye",
}
Catalog.RULES = Catalog.RULES or {
    {
        id = "weather",
        priority = 120,
        keywords = {
            "weather", "rain", "raining", "storm", "fog", "foggy",
            "mist", "cold", "hot", "temperature",
        },
    },
    {
        id = "time",
        priority = 115,
        keywords = {
            "time", "day", "date", "today", "tomorrow", "yesterday",
            "morning", "afternoon", "evening", "night", "hour",
        },
    },
    {
        id = "identity",
        priority = 110,
        keywords = { "name", "who are you", "who am i" },
    },
    {
        id = "activity",
        priority = 105,
        subjects = { ACTIVITY = true },
        keywords = { "doing", "up to", "busy", "working" },
    },
    {
        id = "wellbeing",
        priority = 104,
        subjects = { WELLBEING = true },
        keywords = { "okay", "alright", "how are you", "well" },
    },
    {
        id = "greeting",
        priority = 130,
        intents = { GREET = true },
        keywords = {
            "hello", "hi", "hey", "good morning", "good afternoon",
            "good evening",
        },
    },
    {
        id = "location",
        priority = 95,
        subjects = { LOCATION = true, SEEN = true },
        keywords = { "where", "location", "went", "headed" },
    },
    {
        id = "gossip",
        priority = 94,
        intents = { GOSSIP = true },
        keywords = { "hear", "heard", "rumor", "bitten" },
    },
    {
        id = "resources",
        priority = 90,
        actions = { FETCH = true, TAKE = true },
        objectCategories = {
            WATER = true, FOOD = true, MEDICINE = true,
        },
        keywords = {
            "water", "food", "meal", "rations", "medicine", "meds",
            "medical supplies",
        },
    },
    {
        id = "movement",
        priority = 85,
        actions = { FOLLOW = true, GO = true, STOP = true, STAY = true },
        keywords = {
            "follow", "come with me", "come along", "go", "stop", "wait",
            "stay",
        },
    },
    {
        id = "help",
        priority = 80,
        actions = { HELP = true },
        keywords = { "help" },
    },
    {
        id = "social",
        priority = 75,
        intents = {
            THANK = true, APOLOGIZE = true, ACCEPT = true, REFUSE = true,
            AGREE = true, DISAGREE = true,
        },
        keywords = {
            "thanks", "thank you", "sorry", "yes", "sure", "okay", "ok",
            "no", "nope",
        },
    },
}

function Catalog.RegisterRule(rule)
    if type(rule) ~= "table"
        or type(rule.id) ~= "string"
        or rule.id == ""
    then
        return false, "invalid_topic_rule"
    end
    local index
    for index = 1, #Catalog.RULES do
        if Catalog.RULES[index].id == rule.id then
            Catalog.RULES[index] = rule
            return true, rule
        end
    end
    Catalog.RULES[#Catalog.RULES + 1] = rule
    return true, rule
end

Catalog.RegisterTopic = Catalog.RegisterRule

local function validTopicID(value)
    value = tostring(value or "")
    return value ~= ""
        and #value <= 64
        and string.find(value, "[^%w_%.%-]") == nil
end

function Catalog.RegisterAuthoredTopic(categoryID, topicID)
    categoryID = tostring(categoryID or "")
    topicID = tostring(topicID or "")
    if categoryID == "" or not validTopicID(topicID) then
        return false, "invalid_authored_topic"
    end
    Catalog.AUTHORED_CATEGORY_TOPICS[categoryID] = topicID
    return true, topicID
end

function Catalog.AuthoredTopic(blockOrCategory)
    local categoryID
    local explicit
    if type(blockOrCategory) == "table" then
        categoryID = blockOrCategory.category
        explicit = blockOrCategory.topic
    else
        categoryID = blockOrCategory
    end
    if validTopicID(explicit) then return tostring(explicit) end
    return Catalog.AUTHORED_CATEGORY_TOPICS[tostring(categoryID or "")]
end

local function normalize(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w%s']", " ")
    value = string.gsub(value, "%s+", " ")
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function containsKeyword(text, keyword)
    keyword = normalize(keyword)
    if keyword == "" then return false end
    local padded = " " .. text .. " "
    return string.find(padded, " " .. keyword .. " ", 1, true) ~= nil
end

local function anyKeyword(text, keywords)
    if type(keywords) ~= "table" then return false, nil end
    local index
    for index = 1, #keywords do
        local keyword = keywords[index]
        if containsKeyword(text, keyword) then return true, keyword end
    end
    return false, nil
end

local function semanticMatch(rule, ir)
    if type(ir) ~= "table" then return false end
    if type(rule.intents) == "table"
        and not rule.intents[ir.intent]
        and not rule.intents[ir.speechAct]
    then
        return false
    end
    if type(rule.actions) == "table"
        and not rule.actions[ir.action]
    then
        return false
    end
    if type(rule.subjects) == "table"
        and not rule.subjects[ir.subject]
    then
        return false
    end
    if type(rule.objectCategories) == "table" then
        local object = ir.object
        local category = type(object) == "table" and object.category or nil
        if not rule.objectCategories[category] then return false end
    end
    return type(rule.intents) == "table"
        or type(rule.actions) == "table"
        or type(rule.subjects) == "table"
        or type(rule.objectCategories) == "table"
end

function Catalog.Normalize(value)
    return normalize(value)
end

function Catalog.Resolve(ir, text)
    local source = text
    if source == nil and type(ir) == "table" then
        source = ir.normalizedText
    end
    local normalized = normalize(source)
    local best
    local bestScore = -1
    local index
    for index = 1, #Catalog.RULES do
        local rule = Catalog.RULES[index]
        local semantic = semanticMatch(rule, ir)
        local keyword, matched = anyKeyword(normalized, rule.keywords)
        if semantic or keyword then
            local score = tonumber(rule.priority) or 0
            if semantic then score = score + 20 end
            if keyword then score = score + 10 end
            if score > bestScore then
                bestScore = score
                best = {
                    id = rule.id,
                    confidence = semantic and 0.96 or 0.82,
                    matched = matched,
                    source = semantic and "semantic" or "keyword",
                }
            end
        end
    end
    return best
end

function Catalog.Annotate(ir, text)
    if type(ir) ~= "table" then return ir, nil end
    local topic = Catalog.Resolve(ir, text)
    if not topic then return ir, nil end
    ir.extensions = type(ir.extensions) == "table" and ir.extensions or {}
    ir.extensions.topic = {
        id = topic.id,
        confidence = topic.confidence,
        matched = topic.matched,
        source = topic.source,
    }
    ir.diagnostics = type(ir.diagnostics) == "table" and ir.diagnostics or {}
    ir.diagnostics.topic = topic.id
    ir.diagnostics.topicSource = topic.source
    return ir, topic
end

return Catalog
