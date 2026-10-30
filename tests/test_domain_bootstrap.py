"""Bootstrap equivalence catches ordering changes and policy in registrations."""
import tempfile
from pathlib import Path
import unittest

from tools.domain_bootstrap import SERVER_GUARD, trace, verify


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        (self.base / 'server').mkdir()
        self.root = self.base / 'server/Root.lua'
        self.registration = self.base / 'server/Domain.lua'
        self.root.write_text(SERVER_GUARD + '\nrequire "Domain"\nInstall()\nrequire "Last"\n')
        self.registration.write_text(SERVER_GUARD + '\nrequire "A"\nrequire "B"\n')
        self.manifest = {'registrations': [{'path': 'server/Domain.lua', 'module': 'Domain',
                                           'providers': ['A', 'B']}]}
        self.baseline = {'roots': {'server/Root.lua': {
            'trace': [SERVER_GUARD, 'require "A"', 'require "B"', 'Install()', 'require "Last"'],
            'bytes': 100, 'lines': 5, 'requires': 3}}}

    def test_ordered_registration_preserves_executable_barrier(self):
        self.assertTrue(verify(self.base, self.manifest, self.baseline)[0]['expanded_order_equal'])

    def test_same_import_set_with_different_order_is_rejected(self):
        self.registration.write_text(SERVER_GUARD + '\nrequire "B"\nrequire "A"\n')
        with self.assertRaisesRegex(ValueError, 'changed providers'):
            verify(self.base, self.manifest, self.baseline)

    def test_moving_hook_across_registration_is_rejected(self):
        self.root.write_text(SERVER_GUARD + '\nInstall()\nrequire "Domain"\nrequire "Last"\n')
        with self.assertRaisesRegex(ValueError, 'Expanded bootstrap changed'):
            verify(self.base, self.manifest, self.baseline)

    def test_registration_must_not_own_policy(self):
        self.registration.write_text(self.registration.read_text() + 'PNC.State = {}\n')
        with self.assertRaisesRegex(ValueError, 'contains policy'):
            verify(self.base, self.manifest, self.baseline)

    def test_recursive_registration_is_rejected(self):
        self.registration.write_text('require "Domain"\n')
        with self.assertRaisesRegex(ValueError, 'Registration cycle'):
            trace(self.base, 'server/Domain.lua', {
                ('server', 'Domain'): {'path': 'server/Domain.lua'}})

    def test_legacy_import_may_only_forward_to_the_same_public_entry(self):
        (self.base / 'server/Legacy.lua').write_text('return require "Domain"\n')
        self.manifest['compatibility_imports'] = [
            {'legacy_path': 'server/Legacy.lua', 'module': 'Domain'}]
        self.baseline['roots']['server/Root.lua']['trace'][1:3] = ['require "Legacy"']
        # The baseline stops at Domain's assembly boundary in this case.
        empty = {'registrations': [],
                 'compatibility_imports': self.manifest['compatibility_imports']}
        self.assertTrue(verify(self.base, empty, self.baseline)[0]['expanded_order_equal'])
        (self.base / 'server/Legacy.lua').write_text('Policy()\nreturn require "Domain"\n')
        with self.assertRaisesRegex(ValueError, 'not a pure forwarder'):
            verify(self.base, empty, self.baseline)


if __name__ == '__main__':
    unittest.main()
