import frappe
import unittest
from unittest.mock import patch

# Import the functions to be tested
from rokct.rokct.api.paas.shop import create_shop, get_shops, get_shop_details

class TestShopAPI(unittest.TestCase):
    def setUp(self):
        # This method will be run before each test
        frappe.db.delete("Shop")
        frappe.db.delete("User", {"email": "test-seller@example.com"})
        frappe.db.delete("User", {"email": "test-seller-2@example.com"})
        frappe.db.delete("User", {"email": "non-seller@example.com"})

        # Create users
        self.seller_user = frappe.get_doc({
            "doctype": "User",
            "email": "test-seller@example.com",
            "first_name": "Test",
            "last_name": "Seller",
            "roles": [{"role": "Seller"}]
        }).insert(ignore_permissions=True)

        self.seller_user_2 = frappe.get_doc({
            "doctype": "User",
            "email": "test-seller-2@example.com",
            "first_name": "Test",
            "last_name": "Seller 2",
            "roles": [{"role": "Seller"}]
        }).insert(ignore_permissions=True)

        self.non_seller_user = frappe.get_doc({
            "doctype": "User",
            "email": "non-seller@example.com",
            "first_name": "Non",
            "last_name": "Seller",
        }).insert(ignore_permissions=True)

        # Log in as a seller to create shops
        frappe.set_user(self.seller_user.name)

        # Create some mock shops
        self.shop1 = create_shop({
            "shop_name": "Test Shop 1",
            "status": "approved",
            "open": 1,
            "visibility": 1,
            "delivery": 1,
            "user": self.seller_user.name,
        })

        self.shop2 = create_shop({
            "shop_name": "Test Shop 2",
            "status": "approved",
            "open": 1,
            "visibility": 1,
            "pickup": 1,
            "user": self.seller_user_2.name,
        })

        self.shop3_not_approved = create_shop({
            "shop_name": "Test Shop 3 Not Approved",
            "status": "new",
            "open": 1,
            "visibility": 1,
            "user": self.seller_user.name,
        })

        self.shop4_not_visible = create_shop({
            "shop_name": "Test Shop 4 Not Visible",
            "status": "approved",
            "open": 1,
            "visibility": 0,
            "user": self.seller_user.name,
        })

        # Switch back to administrator
        frappe.set_user("Administrator")

    def tearDown(self):
        # This method will be run after each test
        frappe.set_user("Administrator")
        frappe.db.rollback()

    def test_create_shop_unauthorized(self):
        """Test that a user without the Seller role cannot create a shop."""
        frappe.set_user(self.non_seller_user.name)
        with self.assertRaises(frappe.PermissionError):
            create_shop({"shop_name": "Unauthorized Shop"})

    def test_create_shop_success(self):
        """Test successful shop creation."""
        self.assertIn('uuid', self.shop1)
        self.assertIn('slug', self.shop1)
        self.assertEqual(self.shop1['slug'], 'test-shop-1')

    def test_get_shops_no_filters(self):
        """Test fetching shops without any filters."""
        shops = get_shops(limit_page_length=20)

        # Should only return approved, open, and visible shops
        self.assertEqual(len(shops), 2)
        shop_names = [s['id'] for s in shops]
        self.assertIn("Test Shop 1", shop_names)
        self.assertIn("Test Shop 2", shop_names)
        self.assertNotIn("Test Shop 3 Not Approved", shop_names)
        self.assertNotIn("Test Shop 4 Not Visible", shop_names)

    def test_get_shops_pagination(self):
        """Test pagination for get_shops."""
        # Get the first page with one item
        shops_page1 = get_shops(limit_start=0, limit_page_length=1, order_by="shop_name", order="asc")
        self.assertEqual(len(shops_page1), 1)
        self.assertEqual(shops_page1[0]['id'], 'Test Shop 1')

        # Get the second page with one item
        shops_page2 = get_shops(limit_start=1, limit_page_length=1, order_by="shop_name", order="asc")
        self.assertEqual(len(shops_page2), 1)
        self.assertEqual(shops_page2[0]['id'], 'Test Shop 2')

    def test_get_shop_details_success(self):
        """Test fetching details for a single, valid shop."""
        shop_details = get_shop_details(uuid=self.shop1['uuid'])
        self.assertIsNotNone(shop_details)
        self.assertEqual(shop_details['id'], self.shop1['shop_name'])
        self.assertEqual(shop_details['uuid'], self.shop1['uuid'])
        self.assertEqual(shop_details['translation']['title'], self.shop1['shop_name'])

    def test_get_shop_details_not_found(self):
        """Test fetching details for a non-existent shop."""
        with self.assertRaises(frappe.DoesNotExistError):
            get_shop_details(uuid="non-existent-uuid")

    def test_get_shops_with_delivery_filter(self):
        """Test fetching shops with delivery=True filter."""
        shops = get_shops(delivery=True)
        self.assertEqual(len(shops), 1)
        self.assertEqual(shops[0]['id'], "Test Shop 1")

    def test_get_shops_with_takeaway_filter(self):
        """Test fetching shops with takeaway=True filter."""
        shops = get_shops(takeaway=True)
        self.assertEqual(len(shops), 1)
        self.assertEqual(shops[0]['id'], "Test Shop 2")

    def test_get_shops_ordering(self):
        """Test ordering of shops."""
        # Test ordering by name descending
        shops_desc = get_shops(order_by="shop_name", order="desc")
        self.assertEqual(shops_desc[0]['id'], "Test Shop 2")
        self.assertEqual(shops_desc[1]['id'], "Test Shop 1")

        # Test ordering by name ascending
        shops_asc = get_shops(order_by="shop_name", order="asc")
        self.assertEqual(shops_asc[0]['id'], "Test Shop 1")
        self.assertEqual(shops_asc[1]['id'], "Test Shop 2")

if __name__ == '__main__':
    # This allows running the tests directly
    # Note: This requires a running Frappe instance and site context.
    # The recommended way to run tests is via `bench --site {site_name} execute ...`
    pass