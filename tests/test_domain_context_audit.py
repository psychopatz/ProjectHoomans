"""Regression guards for architecture evidence, independent of gameplay tests."""
import unittest

from tools.domain_context_audit import components


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


if __name__ == '__main__':
    unittest.main()
