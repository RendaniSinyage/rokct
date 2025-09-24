import json
import os

def get_version():
    # Path to the directory of this __init__.py file
    app_path = os.path.abspath(os.path.dirname(__file__))
    # Path to versions.json, which is in the same directory
    versions_file_path = os.path.join(app_path, 'versions.json')

    try:
        with open(versions_file_path, 'r') as f:
            versions = json.load(f)
        return versions.get('rokct', '1.3.4')  # Default fallback
    except Exception:
        return '1.3.4'  # Default fallback in case of any error

__version__ = get_version()
