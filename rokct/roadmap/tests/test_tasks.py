import unittest
from unittest.mock import patch, MagicMock
import sys

# Pre-import mock of frappe to handle its complex structure
mock_frappe = MagicMock()
sys.modules['frappe'] = mock_frappe

# Now we can safely import the functions we want to test
from rokct.roadmap.tasks import (
    populate_roadmap_with_ai_ideas,
    _get_api_key,
    _generate_ideas_for_repo,
    _save_ideas_to_roadmap,
    _parse_ideas_from_response
)

TASKS_MODULE_PATH = 'rokct.roadmap.tasks'

class TestRefactoredRoadmapTasks(unittest.TestCase):

    def setUp(self):
        # Reset all mocks before each test to ensure a clean state
        mock_frappe.reset_mock()

    @patch(f'{TASKS_MODULE_PATH}._get_api_key')
    @patch(f'{TASKS_MODULE_PATH}._generate_ideas_for_repo')
    @patch(f'{TASKS_MODULE_PATH}._save_ideas_to_roadmap')
    def test_orchestrator_happy_path(self, mock_save, mock_generate, mock_get_key):
        """Test the main orchestrator function's successful execution path."""
        # --- Test-specific mock setup ---
        mock_get_key.return_value = "test_api_key"
        mock_frappe.get_all.return_value = [{"name": "R1", "source_repository": "r1"}]
        mock_frappe.db.exists.return_value = False
        mock_generate.return_value = [{"title": "Generated Idea"}]

        populate_roadmap_with_ai_ideas()

        mock_get_key.assert_called_once()
        mock_frappe.get_all.assert_called_once()
        mock_generate.assert_called_once_with("r1", "test_api_key")
        mock_save.assert_called_once_with("R1", [{"title": "Generated Idea"}])

    @patch(f'{TASKS_MODULE_PATH}._get_api_key', return_value=None)
    def test_orchestrator_no_api_key(self, mock_get_key):
        """Test that the orchestrator exits early if no API key is found."""
        populate_roadmap_with_ai_ideas()
        mock_frappe.get_all.assert_not_called()

    def test_get_api_key_for_control_panel(self):
        """Test API key retrieval for a control panel role."""
        mock_frappe.conf.get.side_effect = lambda key: "control_panel" if key == "app_role" else "cp_key"
        self.assertEqual(_get_api_key(), "cp_key")

    def test_get_api_key_for_tenant(self):
        """Test API key retrieval for a tenant role with Jules Settings."""
        # This test now has its own, isolated mock setup
        with patch.object(mock_frappe.conf, 'get', return_value="tenant"), \
             patch.object(mock_frappe.db, 'exists', return_value=True):

            mock_settings = MagicMock()
            mock_settings.get_password.return_value = "tenant_key"
            mock_frappe.get_doc.return_value = mock_settings

            self.assertEqual(_get_api_key(), "tenant_key")
            mock_settings.get_password.assert_called_with("jules_api_key")

    @patch(f'{TASKS_MODULE_PATH}._create_jules_session', return_value="sid")
    @patch(f'{TASKS_MODULE_PATH}._get_jules_activities', return_value=[{}, {"agentActivity": {"message": '{"ideas": [{"title": "A"}]}'}}])
    def test_generate_ideas_for_repo(self, mock_get_activities, mock_create_session):
        """Test the core idea generation logic."""
        ideas = _generate_ideas_for_repo("test/repo", "test_key")

        self.assertEqual(len(ideas), 3) # 3 prompts are run
        self.assertEqual(ideas[0]['title'], 'A')
        self.assertIn(ideas[0]['type'], ["Feature", "Bug"])
        self.assertEqual(mock_create_session.call_count, 3)

    def test_save_ideas_to_roadmap(self):
        """Test the logic for saving generated ideas to a roadmap document."""
        ideas = [{"title": "Idea 1", "explanation": "Expl 1", "type": "Feature"}]
        mock_roadmap_doc = MagicMock()
        mock_frappe.get_doc.return_value = mock_roadmap_doc
        mock_feature_doc = MagicMock()
        mock_frappe.new_doc.return_value = mock_feature_doc

        _save_ideas_to_roadmap("Test-Roadmap", ideas)

        mock_frappe.get_doc.assert_called_with("Roadmap", "Test-Roadmap")
        mock_frappe.new_doc.assert_called_with("Roadmap Feature")
        self.assertEqual(mock_feature_doc.feature, "Idea 1")
        mock_roadmap_doc.append.assert_called_once_with("features", mock_feature_doc)
        mock_roadmap_doc.save.assert_called_once()
        mock_frappe.db.commit.assert_called_once()

    def test_parse_ideas_from_response(self):
        """Test the JSON parsing logic."""
        with patch.object(mock_frappe, 'log_error') as mock_log_error:
            self.assertEqual(len(_parse_ideas_from_response('{"ideas": [1, 2]}')), 2)
            self.assertEqual(_parse_ideas_from_response('{"other_key": []}'), [])
            self.assertEqual(_parse_ideas_from_response('invalid json'), [])
            mock_log_error.assert_called_once()

if __name__ == '__main__':
    unittest.main()