"""Runtime boundary for the Semantic Lab's Python/Lua worker integration.

The runtime package owns discovery, scenarios, the bounded JSON-lines
protocol, child-process lifecycle, and serialized worker sessions.  It stays
independent from Tk and CodeBuilder so those layers can be reorganized
without changing worker behavior.
"""
