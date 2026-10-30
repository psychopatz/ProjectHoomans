"""Regression guards for architecture evidence, independent of gameplay tests."""
import unittest

from tools.domain_context_audit import components
from tools.domain_contracts import inspect, compare_debt


class CycleEvidenceTests(unittest.TestCase):
    def test_shared_dependency_does_not_create_cycle(self):
        graph = {'UI': ['Inventory', 'Supply'], 'Supply': ['Inventory'], 'Inventory': []}
        self.assertEqual(components(graph), [])

    def test_overlapping_cycle_paths_are_one_problem_group(self):
        graph = {'Conversation': ['UI', 'Persistence'],
                 'UI': ['Knowledge', 'Conversation'], 'Knowledge': ['Persistence'],
                 'Persistence': ['Conversation'], 'Composition': ['UI']}
        self.assertEqual(components(graph), [
            ['Conversation', 'Knowledge', 'Persistence', 'UI']])

    def test_separate_cycles_remain_separate(self):
        graph = {'Networking': ['PresenceSync', 'Registry'],
                 'PresenceSync': ['Networking'], 'UI': ['Debug'],
                 'Debug': ['UI'], 'Independent': ['Independent']}
        self.assertEqual(components(graph), [
            ['Debug', 'UI'], ['Networking', 'PresenceSync']])


class ContractBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.policy = {
            'path_owners': [{'pattern': 'server/Legacy/*', 'owner': 'Inventory'}],
            'folder_owners': {name: name for name in
                              ('Inventory', 'Supply', 'UI', 'Persistence', 'Composition')},
            'domains': {'Inventory': {'entries': ['Inventory/Public.lua'],
                                      'namespace': 'PNC.Inventory'}},
            'enforced_public_domains': ['Inventory'],
            'permitted_presentation_consumers': ['UI', 'Composition'],
        }

    def rules(self, source, target, a, b):
        result = inspect({'Inventory/Public.lua': 'Inventory', source: a, target: b},
                         [{'source': source, 'target': target, 'line': 8}], self.policy)
        return {v['rule'] for v in result['issues']}

    def test_foreign_internal_import_and_same_domain_access(self):
        for target in ('Inventory/Internal/State.lua', 'Inventory/PNC_Inventory_Internal.lua',
                       'Inventory/PNC_Inventory_Internal_State.lua'):
            self.assertIn('FOREIGN_INTERNAL', self.rules('Supply/A.lua', target, 'Supply', 'Inventory'))
            self.assertNotIn('FOREIGN_INTERNAL', self.rules('Inventory/A.lua', target, 'Inventory', 'Inventory'))

    def test_legacy_runtime_location_does_not_override_domain_owner(self):
        self.assertNotIn('FOREIGN_IMPLEMENTATION', self.rules(
            'server/Legacy/A.lua', 'Inventory/Mutation.lua', 'Composition', 'Inventory'))

    def test_public_seam_is_allowed_and_deep_provider_is_rejected(self):
        self.assertNotIn('FOREIGN_IMPLEMENTATION', self.rules(
            'Supply/A.lua', 'Inventory/Public.lua', 'Supply', 'Inventory'))
        self.assertIn('FOREIGN_IMPLEMENTATION', self.rules(
            'Supply/A.lua', 'Inventory/Mutation.lua', 'Supply', 'Inventory'))

    def test_ui_and_persistence_directions(self):
        self.assertIn('DOMAIN_TO_UI', self.rules('Supply/A.lua', 'UI/A.lua', 'Supply', 'UI'))
        self.assertIn('UI_TO_PERSISTENCE_INTERNAL', self.rules(
            'UI/A.lua', 'Persistence/Codec.lua', 'UI', 'Persistence'))

    def test_composition_requires_declared_entry(self):
        self.assertIn('COMPOSITION_TO_PROVIDER', self.rules(
            'Composition/A.lua', 'Inventory/Mutation.lua', 'Composition', 'Inventory'))

    def test_server_entry_cannot_replace_shared_provider(self):
        self.policy['domains']['Inventory']['entries'] = ['server/Inventory/Public.lua']
        paths = {'server/Inventory/Public.lua': 'Inventory',
                 'shared/Composition/A.lua': 'Composition', 'shared/Inventory/A.lua': 'Inventory'}
        result = inspect(paths, [{'source': 'shared/Composition/A.lua',
                                 'target': 'shared/Inventory/A.lua', 'line': 2}], self.policy)
        self.assertNotIn('COMPOSITION_TO_PROVIDER', {v['rule'] for v in result['issues']})

    def test_existing_debt_does_not_allow_new_endpoints(self):
        old = {'rule': 'FOREIGN_INTERNAL', 'source': 'Supply/A.lua',
               'target': 'Inventory/Internal/A.lua', 'line': 1, 'detail': ''}
        moved = {**old, 'line': 9}
        added = {**old, 'source': 'Supply/B.lua'}
        result = compare_debt([moved, added], [old])
        self.assertEqual(result['new'], [added])
        self.assertEqual(result['resolved'], [])

    def test_two_declared_authorities_for_same_namespace_fail(self):
        self.policy['domains']['Supply'] = {'entries': [], 'namespace': 'PNC.Inventory'}
        result = inspect({'Inventory/Public.lua': 'Inventory'}, [], self.policy)
        self.assertIn('COMPETING_AUTHORITY', {v['rule'] for v in result['issues']})


if __name__ == '__main__':
    unittest.main()
