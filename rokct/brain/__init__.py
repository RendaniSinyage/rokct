# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import json
import os

def get_version():
    # Path to the directory of this __init__.py file
    brain_path = os.path.abspath(os.path.dirname(__file__))
    # Path to the app's root directory (one level up)
    app_path = os.path.abspath(os.path.join(brain_path, '..'))
    # Path to versions.json
    versions_file_path = os.path.join(app_path, 'versions.json')

    try:
        with open(versions_file_path, 'r') as f:
            versions = json.load(f)
        return versions.get('brain', '0.1.0')  # Default fallback
    except Exception:
        return '0.1.0'  # Default fallback in case of any error

__version__ = get_version()