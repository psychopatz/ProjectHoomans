-- Public facade for runtime .convo DSL parsing, streaming, and language packs.
-- Reads .convo files directly from media/translation/<LANG>/ConvoBlocks/<category>/
-- across ProjectHoomans, DynamicTrading, and any activated community pack mod.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Schema = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL_Schema"
local Parser = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL_Parser"
local StoryCompiler = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL_StoryCompiler"
local Loader = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL_Loader"

local ConvoDSL = PNC.ConvoEngine.ConvoDSL or {}
PNC.ConvoEngine.ConvoDSL = ConvoDSL

ConvoDSL.VERSION = 3
ConvoDSL.Schema = Schema
ConvoDSL.Parser = Parser
ConvoDSL.StoryCompiler = StoryCompiler
ConvoDSL.StoryMetadata = StoryCompiler.Metadata
ConvoDSL.Loader = Loader
ConvoDSL.BASE_ROOT = Loader.BASE_ROOT
ConvoDSL.PACK_SUBDIR = Loader.PACK_SUBDIR

function ConvoDSL.NewStream(sourcePath, defaultLang)
    return Parser.NewStream(sourcePath, defaultLang)
end

function ConvoDSL.ParseText(text, sourcePath, defaultLang)
    return Parser.ParseText(text, sourcePath, defaultLang)
end

function ConvoDSL.ApplyScripts(scripts, langOverride)
    return Loader.ApplyScripts(scripts, langOverride)
end

function ConvoDSL.RegisterModSource(modID, packSubdir)
    return Loader.RegisterModSource(modID, packSubdir)
end

function ConvoDSL.ActiveLanguage()
    return Loader.ActiveLanguage()
end

function ConvoDSL.LoadLanguage(language, opts)
    return Loader.LoadLanguage(language, opts)
end

function ConvoDSL.EnsureActiveLanguage()
    return Loader.EnsureActiveLanguage()
end

function ConvoDSL.EnsurePoolLoaded(poolID)
    return Loader.EnsurePoolLoaded(poolID)
end

function ConvoDSL.StepStream(maxFiles, budgetMs)
    return Loader.StepStream(maxFiles, budgetMs)
end

function ConvoDSL.FlushStream()
    return Loader.FlushStream()
end

function ConvoDSL.PendingCount()
    return Loader.PendingCount()
end

function ConvoDSL.Reload(language, opts)
    return Loader.Reload(language, opts)
end

function ConvoDSL.GetDiagnostics()
    return Loader.Diagnostics
end

return ConvoDSL
