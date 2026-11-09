"""Hoomans compatibility boundary for the Semantic Lab worker integration.

The package keeps stable Hoomans import paths for configuration, scenario
defaults/validation, and the worker adapter. Core owns the provider-neutral
JSON-lines protocol, process lifecycle, document mechanics, and serialized
worker session. This package stays independent from Tk and CodeBuilder so
those layers can be reorganized without changing worker behavior.
"""
