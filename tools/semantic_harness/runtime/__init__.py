"""Hoomans provider boundary for the Semantic Lab worker integration.

The package keeps Hoomans import paths for configuration, scenario defaults,
save-backed PNC projections, and the physical semantic-worker adapter. Core
owns provider-neutral protocol, process/session lifecycle, document/state
mechanics, native-engine projections, and reusable worker contracts. This
package stays independent from Tk and CodeBuilder so those layers can be
reorganized without changing provider behavior.
"""
