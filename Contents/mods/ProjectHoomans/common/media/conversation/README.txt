Project Hoomans modular conversation translations

Layout:
  <type>/<audience>/<language>/<bundle>.json

Each bundle is a flat JSON object whose values are translated strings. Runtime
definitions register an exact pathPattern containing {language}; Project
Zomboid does not recursively discover this directory. English (EN) is required
and is the fallback for every other language.

Conversation definitions belong under common/media/lua/shared so clients and
servers register identical serialization-safe data. Executable loaders,
registries, networking, persistence, UI, and debugger code belong only under
42.20.
