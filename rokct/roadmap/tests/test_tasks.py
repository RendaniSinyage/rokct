import unittest
from unittest.mock import patch, MagicMock
import frappe
from rokct.roadmap.tasks import populate_roadmap_with_ai_ideas

TASKS_MODULE_PATH = 'rokct.roadmap.tasks'

class TestRoadmapTasks(unittest.TestCase):

    def setUp(self):
        # Mock the entire frappe module within the tasks module's namespace
        self.patcher_frappe = patch(f'{TASKS_MODULE_PATH}.frappe', MagicMock())
        self.mock_frappe = self.patcher_frappe.start()

        # Mock the requests library
        self.patcher_requests_post = patch(f'{TASKS_MODULE_PATH}.requests.post')
        self.mock_requests_post = self.patcher_requests_post.start()
        self.patcher_requests_get = patch(f'{TASKS_MODULE_PATH}.requests.get')
        self.mock_requests_get = self.patcher_requests_get.start()

        # This side effect allows us to simulate the frappe.conf.get calls
        def conf_get_side_effect(key, default=None):
            if key == "app_role":
                return "control_panel"
            if key == "jules_api_key":
                return "test_api_key"
            if key == "jules_source_repo":
                return "test_repo"
            return default

        self.mock_frappe.conf.get.side_effect = conf_get_side_effect
        self.mock_frappe.db.exists.return_value = False

        self.mock_requests_post.return_value.json.return_value = {'name': 'test_session_id'}
        self.mock_requests_get.return_value.json.return_value = {
            'activities': [
                {},  # User prompt
                {
                    'agentActivity': {
                        'message': '{"ideas": [{"title": "Test Idea", "explanation": "Test Explanation"}]}'
                    }
                }
            ]
        }

    def tearDown(self):
        self.patcher_frappe.stop()
        self.patcher_requests_post.stop()
        self.patcher_requests_get.stop()

    def test_gating_logic_when_ai_ideas_exist(self):
        """Test that the function returns early if AI-generated ideas already exist."""
        self.mock_frappe.db.exists.return_value = True
        populate_roadmap_with_ai_ideas()
        self.mock_frappe.log_info.assert_called_with("Skipping AI idea generation as pending AI ideas already exist.", "Jules Idea Generation")
        self.mock_requests_post.assert_not_called()

    def test_roadmap_creation_if_not_exists(self):
        """Test that the function creates the 'Backend Roadmap' if it does not exist."""
        self.mock_frappe.db.exists.side_effect = [False, False] # No pending ideas, no roadmap

        mock_roadmap_doc = MagicMock()
        self.mock_frappe.new_doc.return_value = mock_roadmap_doc
        self.mock_frappe.get_doc.return_value = mock_roadmap_doc

        populate_roadmap_with_ai_ideas()

        self.mock_frappe.new_doc.assert_any_call("Roadmap")
        self.assertEqual(mock_roadmap_doc.title, "Backend Roadmap")
        mock_roadmap_doc.save.assert_called_with(ignore_permissions=True)
        self.mock_frappe.log_info.assert_any_call("Created missing Roadmap document: Backend Roadmap", "Jules Idea Generation")

    def test_feature_creation_from_api_response(self):
        """Test that roadmap features are created correctly from the API response."""
        self.mock_frappe.db.exists.side_effect = [False, True] # No pending ideas, roadmap exists

        mock_feature_doc = MagicMock()
        self.mock_frappe.new_doc.side_effect = lambda doctype: mock_feature_doc if doctype == "Roadmap Feature" else MagicMock()

        mock_roadmap_doc = MagicMock()
        self.mock_frappe.get_doc.return_value = mock_roadmap_doc

        populate_roadmap_with_ai_ideas()

        self.assertEqual(self.mock_requests_post.call_count, 3)
        self.mock_frappe.new_doc.assert_any_call("Roadmap Feature")
        self.assertEqual(mock_feature_doc.feature, "Test Idea")
        self.assertEqual(mock_feature_doc.explanation, "Test Explanation")
        self.assertEqual(mock_feature_doc.is_ai_generated, 1)
        mock_roadmap_doc.append.assert_called_with("features", mock_feature_doc)
        mock_roadmap_doc.save.assert_called_with(ignore_permissions=True)

    def test_api_error_handling(self):
        """Test that API errors are caught and logged."""
        self.mock_requests_post.side_effect = Exception("API is down")

        populate_roadmap_with_ai_ideas()

        self.mock_frappe.log_error.assert_called()
        self.assertIn("Failed to get AI ideas", self.mock_frappe.log_error.call_args[0][0])

if __name__ == '__main__':
    unittest.main()