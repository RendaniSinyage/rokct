import frappe
import json

def _require_admin():
    """Helper function to ensure the user has the System Manager role."""
    if "System Manager" not in frappe.get_roles():
        frappe.throw("You are not authorized to perform this action.", frappe.PermissionError)

@frappe.whitelist()
def get_admin_blogs(limit_start: int = 0, limit_page_length: int = 20):
    """
    Retrieves a list of all blog posts (for admins).
    """
    _require_admin()
    return frappe.get_list(
        "Blog Post",
        fields=["name", "title", "blogger", "published"],
        limit_start=limit_start,
        limit_page_length=limit_page_length
    )


@frappe.whitelist()
def create_admin_blog(blog_data):
    """
    Creates a new blog post (for admins).
    """
    _require_admin()
    if isinstance(blog_data, str):
        blog_data = json.loads(blog_data)

    new_blog = frappe.get_doc({
        "doctype": "Blog Post",
        **blog_data
    })
    new_blog.insert(ignore_permissions=True)
    return new_blog.as_dict()


@frappe.whitelist()
def update_admin_blog(blog_name, blog_data):
    """
    Updates a blog post (for admins).
    """
    _require_admin()
    if isinstance(blog_data, str):
        blog_data = json.loads(blog_data)

    blog = frappe.get_doc("Blog Post", blog_name)
    blog.update(blog_data)
    blog.save(ignore_permissions=True)
    return blog.as_dict()


@frappe.whitelist()
def delete_admin_blog(blog_name):
    """
    Deletes a blog post (for admins).
    """
    _require_admin()
    frappe.delete_doc("Blog Post", blog_name, ignore_permissions=True)
    return {"status": "success", "message": "Blog post deleted successfully."}

@frappe.whitelist(allow_guest=True)
def get_blogs(limit_start: int = 0, limit_page_length: int = 20):
    blog_posts = frappe.get_list(
        "Blog Post",
        filters={"published": 1},
        fields=["name", "title", "blogger", "blog_category", "published_on", "cover_image", "content"],
        limit_start=limit_start,
        limit_page_length=limit_page_length,
        order_by="published_on desc"
    )

    # In a real scenario, you might want to fetch full user docs for the author
    # For now, we just get the name.

    formatted_blogs = []
    for post in blog_posts:
        formatted_blogs.append({
            "id": post.name,
            "uuid": post.name,
            "type": post.blog_category,
            "published_at": post.published_on,
            "active": True,
            "img": post.cover_image,
            "translation": {
                "title": post.title,
                "description": post.content,
            },
            "author": {
                "firstname": post.blogger,
            }
        })

    return formatted_blogs

@frappe.whitelist(allow_guest=True)
def get_blog(uuid: str):
    post = frappe.get_doc("Blog Post", uuid)
    if not post.published:
        frappe.throw("Blog post not published.", frappe.PermissionError)

    return {
        "id": post.name,
        "uuid": post.name,
        "type": post.blog_category,
        "published_at": post.published_on,
        "active": True,
        "img": post.cover_image,
        "translation": {
            "title": post.title,
            "description": post.content,
        },
        "author": {
            "firstname": post.blogger,
        }
    }