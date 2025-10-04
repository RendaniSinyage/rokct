import json
import os

def get_version():
    # Path to the directory of this __init__.py file
    paas_path = os.path.abspath(os.path.dirname(__file__))
    # Path to the app's root directory (one level up)
    app_path = os.path.abspath(os.path.join(paas_path, '..'))
    # Path to versions.json
    versions_file_path = os.path.join(app_path, 'versions.json')

    try:
        with open(versions_file_path, 'r') as f:
            versions = json.load(f)
        return versions.get('paas', '0.1.0')  # Default fallback
    except Exception:
        return '0.1.0'  # Default fallback in case of any error

__version__ = get_version()
