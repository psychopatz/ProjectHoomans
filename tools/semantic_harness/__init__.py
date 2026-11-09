"""Interactive, real-Lua semantic dialogue harness.

Core owns the provider-neutral harness package.  Importing the Hoomans
adopter package makes that sibling package available for direct imports while
leaving Hoomans-specific policy in this repository.
"""

from __future__ import annotations

import sys
from pathlib import Path


_CORE_TOOLS = Path(__file__).resolve().parents[2].parent / "psychopatzCore" / "tools"
if str(_CORE_TOOLS) not in sys.path:
    sys.path.insert(0, str(_CORE_TOOLS))

