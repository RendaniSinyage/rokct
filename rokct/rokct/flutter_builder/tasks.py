import frappe
import os
import shutil
import json
import subprocess
import tempfile
import re
import yaml

def log_message(message, app_config_name):
    """Helper function to append messages to the build log."""
    app_config = frappe.get_doc("Flutter App Configuration", app_config_name)
    current_log = app_config.build_log or ""
    new_log = current_log + str(message) + "\n"
    app_config.db_set("build_log", new_log)
    frappe.db.commit()
    frappe.logger().info(f"Build Log ({app_config_name}): {message}")

def get_original_package_name(temp_dir):
    """Reads the original package name from the android/app/build.gradle file."""
    build_gradle_path = os.path.join(temp_dir, 'android/app/build.gradle')
    if os.path.exists(build_gradle_path):
        with open(build_gradle_path, 'r') as f:
            content = f.read()
        match = re.search(r'applicationId "(.*)"', content)
        if match:
            return match.group(1)
    raise Exception("Could not find original package name in build.gradle")

def rename_android_package_structure(temp_dir, old_package_name, new_package_name, app_config_name):
    """Renames the android package directory structure."""
    if not new_package_name or old_package_name == new_package_name:
        log_message("Package name is unchanged, skipping directory rename.", app_config_name)
        return

    log_message(f"Renaming Android package from {old_package_name} to {new_package_name}", app_config_name)

    main_src_dir = os.path.join(temp_dir, 'android/app/src/main')
    lang_dir = ""
    if os.path.isdir(os.path.join(main_src_dir, 'kotlin')):
        lang_dir = 'kotlin'
    elif os.path.isdir(os.path.join(main_src_dir, 'java')):
        lang_dir = 'java'
    else:
        raise Exception("Could not find 'kotlin' or 'java' source directory.")

    base_path = os.path.join(main_src_dir, lang_dir)

    old_path = os.path.join(base_path, *old_package_name.split('.'))
    new_path = os.path.join(base_path, *new_package_name.split('.'))

    if not os.path.isdir(old_path):
        raise Exception(f"Old package directory not found: {old_path}")

    os.makedirs(new_path, exist_ok=True)
    for item in os.listdir(old_path):
        shutil.move(os.path.join(old_path, item), os.path.join(new_path, item))

    try:
        os.removedirs(old_path)
    except OSError:
        pass

    log_message("Successfully renamed Android package structure.", app_config_name)

def get_windows_exe_name(temp_dir):
    """Reads the BINARY_NAME from the windows/runner/CMakeLists.txt file."""
    cmake_path = os.path.join(temp_dir, 'windows/runner/CMakeLists.txt')
    if os.path.exists(cmake_path):
        with open(cmake_path, 'r') as f:
            content = f.read()
        match = re.search(r'set\(BINARY_NAME "(.*)"\)', content)
        if match:
            return match.group(1)
    # Fallback to a reasonable default if not found
    return "app"

import xml.etree.ElementTree as ET

def modify_project_files(temp_dir, app_config):
    """
    Modifies the files in the temporary Flutter project directory
    based on the app configuration.
    """
    log_message("Starting file modifications...", app_config.name)

    # 1. Modify pubspec.yaml for version and description
    pubspec_path = os.path.join(temp_dir, 'pubspec.yaml')
    if os.path.exists(pubspec_path):
        with open(pubspec_path, 'r') as f:
            pubspec_content = f.read()

        # Update version
        match = re.search(r'version: (\d+\.\d+\.\d+)\+(\d+)', pubspec_content)
        if match:
            version_code = int(match.group(2)) + 1
            new_version = f'version: {match.group(1)}+{version_code}'
            pubspec_content = re.sub(r'version: .+', new_version, pubspec_content)
            log_message(f"Updated version in pubspec.yaml to +{version_code}", app_config.name)

        # Update description
        if app_config.app_description:
            pubspec_content = re.sub(r'description:.*', f'description: {app_config.app_description}', pubspec_content)
            log_message("Updated description in pubspec.yaml", app_config.name)

        with open(pubspec_path, 'w') as f:
            f.write(pubspec_content)

    # 2. Modify app display name
    if app_config.app_display_name:
        # Android: android/app/src/main/res/values/strings.xml
        strings_xml_path = os.path.join(temp_dir, 'android/app/src/main/res/values/strings.xml')
        if os.path.exists(strings_xml_path):
            tree = ET.parse(strings_xml_path)
            root = tree.getroot()
            for string_tag in root.iter('string'):
                if string_tag.get('name') == 'app_name':
                    string_tag.text = app_config.app_display_name
                    break
            tree.write(strings_xml_path)
            log_message("Updated app_name in strings.xml", app_config.name)

        # iOS: ios/Runner/Info.plist
        info_plist_path = os.path.join(temp_dir, 'ios/Runner/Info.plist')
        if os.path.exists(info_plist_path):
            tree = ET.parse(info_plist_path)
            root = tree.getroot()
            # Info.plist is a dict inside a plist. We need to find the key CFBundleDisplayName
            # and update the next <string> tag.
            dict_element = root.find('dict')
            for i, elem in enumerate(dict_element):
                if elem.tag == 'key' and elem.text == 'CFBundleDisplayName':
                    dict_element[i+1].text = app_config.app_display_name
                    break
            tree.write(info_plist_path)
            log_message("Updated CFBundleDisplayName in Info.plist", app_config.name)

    # 3. Modify app_constants.dart
    constants_path = os.path.join(temp_dir, 'lib/infrastructure/services/app_constants.dart')
    if os.path.exists(constants_path):
        with open(constants_path, 'r') as f:
            content = f.read()

        # Automated baseUrl
        base_url = frappe.utils.get_site_url(frappe.local.site)
        content = re.sub(f"static String baseUrl = '.*';", f"static String baseUrl = '{base_url}';", content)
        log_message(f"Set baseUrl to: {base_url}", app_config.name)

        # String replacements
        string_replacements = {
            "googleApiKey": app_config.google_api_key,
            "uriPrefix": app_config.uri_prefix,
            "androidPackageName": app_config.package_name,
            "iosPackageName": app_config.ios_package_name,
            "adminPageUrl": app_config.admin_page_url,
            "webUrl": app_config.web_url,
            "firebaseWebKey": app_config.firebase_web_key,
            "passphrase": app_config.payfast_passphrase,
            "merchantId": app_config.payfast_merchant_id,
            "merchantKey": app_config.payfast_merchant_key,
            "openWeatherApiKey": app_config.openweather_api_key,
        }
        for key, value in string_replacements.items():
            if value:
                # Use a non-greedy match to avoid issues with multiple similar lines
                content = re.sub(f"static String {key} = '.*?';", f"static String {key} = '{value}';", content)

        # Boolean replacements
        if app_config.is_demo is not None:
            bool_val = "true" if app_config.is_demo else "false"
            content = re.sub(r"static bool isDemo = (true|false);", f"static bool isDemo = {bool_val};", content)

        # Numeric replacements (Float/Int)
        numeric_replacements = {
            "demoLatitude": app_config.default_latitude,
            "demoLongitude": app_config.default_longitude,
        }
        for key, value in numeric_replacements.items():
            if value is not None:
                 content = re.sub(f"static double {key} = .*;", f"static double {key} = {value};", content)

        with open(constants_path, 'w') as f:
            f.write(content)
        log_message("Updated app_constants.dart", app_config.name)

    # 3. Modify app_style.dart
    style_path = os.path.join(temp_dir, 'lib/presentation/theme/app_style.dart')
    if os.path.exists(style_path):
        with open(style_path, 'r') as f:
            style_content = f.read()

        color_fields = {
            'primary': app_config.primary_color,
            'bottomNavigationBarColor': app_config.bottom_nav_color,
            'textGrey': app_config.text_grey_color,
        }

        modified = False
        for var_name, color_value in color_fields.items():
            if color_value:
                color_hex = color_value.replace("#", "").upper()
                new_line = f"static const Color {var_name} = Color(0xFF{color_hex});"
                # Regex to find and replace a color definition line
                pattern = re.compile(f"static const Color {var_name} = Color\(0x[0-9a-fA-F]+\);.*", re.IGNORECASE)
                if pattern.search(style_content):
                    style_content = pattern.sub(new_line, style_content)
                    log_message(f"Updated {var_name} color in app_style.dart", app_config.name)
                    modified = True

        if modified:
            with open(style_path, 'w') as f:
                f.write(style_content)

    # 4. Modify Android files
    build_gradle_path = os.path.join(temp_dir, 'android/app/build.gradle')
    if os.path.exists(build_gradle_path):
        with open(build_gradle_path, 'r') as f:
            content = f.read()
        content = re.sub(r'applicationId ".*"', f'applicationId "{app_config.package_name}"', content)
        with open(build_gradle_path, 'w') as f:
            f.write(content)
        log_message("Updated applicationId in build.gradle", app_config.name)

    manifest_path = os.path.join(temp_dir, 'android/app/src/main/AndroidManifest.xml')
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r') as f:
            content = f.read()
        content = re.sub(r'package=".*"', f'package="{app_config.package_name}"', content)
        with open(manifest_path, 'w') as f:
            f.write(content)
        log_message("Updated package in AndroidManifest.xml", app_config.name)

    log_message("File modifications complete.", app_config.name)

def handle_custom_font(temp_dir, app_config):
    """Handles the uploaded custom font file."""
    if not app_config.custom_font_file:
        return

    log_message("Handling custom font...", app_config.name)

    # Save the font file to assets/fonts
    font_file_doc = frappe.get_doc("File", {"file_url": app_config.custom_font_file})
    font_content = font_file_doc.get_content()
    font_filename = font_file_doc.file_name

    fonts_dir = os.path.join(temp_dir, 'assets/fonts')
    os.makedirs(fonts_dir, exist_ok=True)
    font_path = os.path.join(fonts_dir, font_filename)
    with open(font_path, 'wb') as f:
        f.write(font_content)

    # Update pubspec.yaml to include the font
    pubspec_path = os.path.join(temp_dir, 'pubspec.yaml')
    with open(pubspec_path, 'r') as f:
        pubspec_data = yaml.safe_load(f)

    # This assumes a simple structure and replaces any existing font family.
    # A more complex app might need a more nuanced approach.
    font_family_name = os.path.splitext(font_filename)[0].replace('-', ' ').title()
    pubspec_data['flutter']['fonts'] = [
        {
            'family': font_family_name,
            'fonts': [
                {'asset': f'assets/fonts/{font_filename}'}
            ]
        }
    ]

    with open(pubspec_path, 'w') as f:
        yaml.dump(pubspec_data, f, default_flow_style=False)

    log_message(f"Added custom font '{font_family_name}' to pubspec.yaml", app_config.name)

    # Also update the default font in app_style.dart
    style_path = os.path.join(temp_dir, 'lib/presentation/theme/app_style.dart')
    if os.path.exists(style_path):
        with open(style_path, 'r') as f:
            style_content = f.read()

        # This is a bit of a guess, assuming GoogleFonts.inter is the one to change.
        style_content = re.sub(r"GoogleFonts\.(.*?)\(", f"GoogleFonts.getFont('{font_family_name}', ", style_content)

        with open(style_path, 'w') as f:
            f.write(style_content)
        log_message("Updated default font in app_style.dart", app_config.name)


def replace_image_asset(temp_dir, app_config, field_name, target_path_relative):
    """Replaces a specified image asset in the project with an uploaded file."""
    image_url = getattr(app_config, field_name, None)
    if not image_url:
        log_message(f"No image provided for {field_name}, skipping.", app_config.name)
        return

    try:
        file_doc = frappe.get_doc("File", {"file_url": image_url})
        file_content = file_doc.get_content()

        target_path_full = os.path.join(temp_dir, target_path_relative)
        os.makedirs(os.path.dirname(target_path_full), exist_ok=True)

        with open(target_path_full, 'wb') as f:
            f.write(file_content)
        log_message(f"Replaced asset at {target_path_relative}", app_config.name)
    except Exception as e:
        log_message(f"Error replacing image asset for {field_name}: {e}", app_config.name)

def place_google_services_json(temp_dir, app_config):
    if not app_config.google_services_json:
        log_message("No google-services.json uploaded, skipping.", app_config.name)
        return

    try:
        file_doc = frappe.get_doc("File", {"file_url": app_config.google_services_json})
        file_content = file_doc.get_content()

        target_path = os.path.join(temp_dir, 'android/app/google-services.json')
        with open(target_path, 'wb') as f:
            f.write(file_content)
        log_message("Placed google-services.json.", app_config.name)
    except Exception as e:
        log_message(f"Error placing google-services.json: {e}", app_config.name)

def generate_app_icons(temp_dir, app_config, settings):
    if not app_config.app_icon:
        log_message("No app icon uploaded, skipping icon generation.", app_config.name)
        return

    log_message("Starting icon generation...", app_config.name)

    try:
        # 1. Save the uploaded icon to the project
        icon_file_doc = frappe.get_doc("File", {"file_url": app_config.app_icon})
        icon_content = icon_file_doc.get_content()

        icon_dir = os.path.join(temp_dir, 'assets/icon')
        os.makedirs(icon_dir, exist_ok=True)
        icon_path = os.path.join(icon_dir, 'icon.png')
        with open(icon_path, 'wb') as f:
            f.write(icon_content)
        log_message(f"Saved uploaded icon to {icon_path}", app_config.name)

        # 2. Configure flutter_launcher_icons in pubspec.yaml
        pubspec_path = os.path.join(temp_dir, 'pubspec.yaml')
        with open(pubspec_path, 'r') as f:
            pubspec_data = yaml.safe_load(f)

        pubspec_data['flutter_icons'] = {
            'android': True,
            'ios': True,
            'image_path': 'assets/icon/icon.png',
            'remove_alpha_ios': True
        }

        if 'dev_dependencies' not in pubspec_data:
            pubspec_data['dev_dependencies'] = {}
        pubspec_data['dev_dependencies']['flutter_launcher_icons'] = '^0.13.1'

        with open(pubspec_path, 'w') as f:
            yaml.dump(pubspec_data, f, default_flow_style=False)
        log_message("Configured flutter_launcher_icons in pubspec.yaml", app_config.name)

        # 3. Run flutter pub get and the icon generator
        env = os.environ.copy()
        flutter_path = settings.flutter_sdk_path
        env['PATH'] = f"{flutter_path}/bin:{env['PATH']}"
        env['PUB_CACHE'] = "/opt/pub-cache"

        log_message("Running 'flutter pub get'...", app_config.name)
        result = subprocess.run(["flutter", "pub", "get"], cwd=temp_dir, check=True, capture_output=True, text=True, env=env)
        log_message(result.stdout, app_config.name)

        log_message("Running icon generator...", app_config.name)
        result = subprocess.run(["flutter", "pub", "run", "flutter_launcher_icons:main"], cwd=temp_dir, check=True, capture_output=True, text=True, env=env)
        log_message(result.stdout, app_config.name)

        log_message("Icon generation complete.", app_config.name)
    except Exception as e:
        log_message(f"Error generating icons: {e}", app_config.name)
        if hasattr(e, 'stderr'):
            log_message(e.stderr, app_config.name)

def update_splash_screen(temp_dir, app_config, settings):
    """Updates the native splash screen configuration."""
    splash_config_path = os.path.join(temp_dir, 'flutter_native_splash.yaml')
    if not os.path.exists(splash_config_path):
        log_message("flutter_native_splash.yaml not found, skipping splash screen update.", app_config.name)
        return

    log_message("Updating splash screen...", app_config.name)

    with open(splash_config_path, 'r') as f:
        splash_data = yaml.safe_load(f)

    if app_config.splash_bg_color:
        splash_data['flutter_native_splash']['color'] = app_config.splash_bg_color

    if app_config.splash_logo:
        # Save the uploaded splash logo to a known path
        splash_logo_path = os.path.join('assets/icon', 'splash_logo.png')
        replace_image_asset(temp_dir, app_config, 'splash_logo', splash_logo_path)
        splash_data['flutter_native_splash']['image'] = splash_logo_path

    with open(splash_config_path, 'w') as f:
        yaml.dump(splash_data, f, default_flow_style=False)

    # Run the splash screen generator
    env = os.environ.copy()
    flutter_path = settings.flutter_sdk_path
    env['PATH'] = f"{flutter_path}/bin:{env['PATH']}"
    env['PUB_CACHE'] = "/opt/pub-cache"

    log_message("Running splash screen generator...", app_config.name)
    result = subprocess.run(["flutter", "pub", "run", "flutter_native_splash:create"], cwd=temp_dir, check=True, capture_output=True, text=True, env=env)
    log_message(result.stdout, app_config.name)
    log_message("Splash screen update complete.", app_config.name)


@frappe.whitelist()
def get_project_version(source_project):
    """Reads and returns the version from the pubspec.yaml of a source project."""
    if not source_project:
        return None

    try:
        this_dir = os.path.dirname(__file__)
        source_dir = os.path.abspath(os.path.join(this_dir, 'source_code', source_project))
        pubspec_path = os.path.join(source_dir, 'pubspec.yaml')

        if not os.path.exists(pubspec_path):
            return "pubspec.yaml not found"

        with open(pubspec_path, 'r') as f:
            pubspec_data = yaml.safe_load(f)

        return pubspec_data.get('version', 'Version not specified')
    except Exception as e:
        frappe.log_error(f"Could not get project version for {source_project}: {e}")
        return "Error reading version"


@frappe.whitelist()
def generate_flutter_app(app_config_name):
    """
    This whitelisted function is called from the client-side script.
    Its only job is to enqueue the actual build task to run in the background
    on a dedicated queue.
    """
    frappe.enqueue(
        'rokct.rokct.flutter_builder.tasks._generate_flutter_app',
        queue='long',
        timeout=7200, # 2 hours timeout for the build
        app_config_name=app_config_name
    )
    return {"status": "enqueued"}

def _generate_flutter_app(app_config_name):
    """
    This is the actual worker function that performs the build.
    It is not whitelisted and is intended to be called only by the queue.
    """
    app_config = frappe.get_doc("Flutter App Configuration", app_config_name)
    settings = frappe.get_doc("Flutter Build Settings")
    temp_dir = tempfile.mkdtemp(prefix="flutter_build_")

    try:
        app_config.db_set("build_status", "In Progress")
        app_config.db_set("build_log", "") # Clear previous logs
        frappe.db.commit()

        log_message("Starting build for " + app_config.name, app_config.name)

        # Determine source directory from app_config
        source_project = app_config.source_project
        if not source_project:
            raise Exception("Source Project not selected in configuration.")

        # Assumes this script is in `rokct/rokct/flutter_builder/tasks.py`
        # and the source is in `rokct/rokct/flutter_builder/source_code/`
        this_dir = os.path.dirname(__file__)
        source_dir = os.path.abspath(os.path.join(this_dir, 'source_code', source_project))

        if not os.path.isdir(source_dir):
            raise Exception(f"Source directory not found or is not a directory: {source_dir}")

        log_message(f"Source directory: {source_dir}", app_config.name)

        for item in os.listdir(source_dir):
            s = os.path.join(source_dir, item)
            d = os.path.join(temp_dir, item)
            if os.path.isdir(s):
                shutil.copytree(s, d, symlinks=True)
            else:
                shutil.copy2(s, d)
        log_message(f"Copied project to temporary directory: {temp_dir}", app_config.name)

        # Get original package name before modifying files
        original_package_name = get_original_package_name(temp_dir)
        rename_android_package_structure(temp_dir, original_package_name, app_config.package_name, app_config.name)

        modify_project_files(temp_dir, app_config)
        handle_custom_font(temp_dir, app_config)

        # Handle asset replacements
        replace_image_asset(temp_dir, app_config, 'brand_logo', 'assets/images/logo.png')
        replace_image_asset(temp_dir, app_config, 'login_bg_image', 'assets/images/loginBg.png')

        place_google_services_json(temp_dir, app_config)
        generate_app_icons(temp_dir, app_config, settings)
        update_splash_screen(temp_dir, app_config, settings)

        # Determine build command
        build_target = app_config.build_target
        build_command = []
        if build_target == 'Android APK':
            build_command = ["flutter", "build", "apk", "--release"]
        elif build_target == 'Android AAB':
            build_command = ["flutter", "build", "appbundle", "--release"]
        elif build_target == 'Windows EXE':
            build_command = ["flutter", "build", "windows", "--release"]
        else:
            raise Exception(f"Invalid build target: {build_target}")

        log_message(f"Running build command: {' '.join(build_command)}...", app_config.name)
        env = os.environ.copy()
        flutter_path = settings.flutter_sdk_path
        env['PATH'] = f"{flutter_path}/bin:{env['PATH']}"
        env['PUB_CACHE'] = "/opt/pub-cache"

        build_result = subprocess.run(build_command, cwd=temp_dir, check=True, capture_output=True, text=True, env=env)
        log_message(build_result.stdout, app_config.name)
        log_message("Flutter build command finished.", app_config.name)

        # Find and save the artifact
        artifact_path = ""
        artifact_extension = ""
        if build_target == 'Android APK':
            artifact_path = os.path.join(temp_dir, 'build/app/outputs/flutter-apk/app-release.apk')
            artifact_extension = "apk"
        elif build_target == 'Android AAB':
            artifact_path = os.path.join(temp_dir, 'build/app/outputs/bundle/release/app-release.aab')
            artifact_extension = "aab"
        elif build_target == 'Windows EXE':
            exe_name = get_windows_exe_name(temp_dir)
            artifact_path = os.path.join(temp_dir, f"build/windows/runner/Release/{exe_name}.exe")
            artifact_extension = "exe"

        if not os.path.exists(artifact_path):
             raise Exception(f"Build succeeded but artifact file not found at expected location: {artifact_path}")

        log_message(f"Artifact found at: {artifact_path}", app_config.name)

        with open(artifact_path, 'rb') as f:
            artifact_content = f.read()

        file_doc = frappe.new_doc("File", {
            "file_name": f"{app_config.name.replace(' ', '_')}-{frappe.utils.now_datetime().strftime('%Y-%m-%d')}.{artifact_extension}",
            "attached_to_doctype": "Flutter App Configuration",
            "attached_to_name": app_config.name,
            "content": artifact_content,
            "is_private": 0
        })
        file_doc.save(ignore_permissions=True)

        log_message(f"Saved artifact to Frappe file: {file_doc.name}", app_config.name)

        app_config.db_set("apk_download_link", file_doc.file_url)
        app_config.db_set("build_status", "Success")
        log_message("Build finished successfully!", app_config.name)
        frappe.db.commit()
        frappe.publish_realtime(
            "flutter_build_complete",
            message={"status": "Success", "app_config_name": app_config.name},
            user=app_config.owner
        )

    except Exception as e:
        frappe.db.rollback()
        log_message(f"Build failed: {str(e)}", app_config.name)
        log_message(frappe.get_traceback(), app_config.name)
        app_config.db_set("build_status", "Failed")
        frappe.db.commit()
        frappe.log_error(frappe.get_traceback(), "Flutter App Build Failed")
        frappe.publish_realtime(
            "flutter_build_complete",
            message={"status": "Failed", "app_config_name": app_config.name},
            user=app_config.owner
        )
    finally:
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)
            print(f"Cleaned up temporary directory: {temp_dir}")

