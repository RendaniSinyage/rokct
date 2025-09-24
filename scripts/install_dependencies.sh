#!/bin/bash
set -e

# --- Configurable Variables ---
# The user that should own the SDKs. Change this to your Frappe user if different.
SDK_OWNER="frappe"

# --- Helper Functions ---
print_info() {
    echo "INFO: $1"
}
print_success() {
    echo "SUCCESS: $1"
}
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Environment Variables ---
FLUTTER_SDK_PATH="/opt/flutter"
ANDROID_SDK_PATH="/opt/android-sdk"
PUB_CACHE_PATH="/opt/pub-cache"
FLUTTER_VERSION="3.13.9"

# --- 1. Create Shared Cache Directory ---
print_info "Setting up shared pub cache directory at $PUB_CACHE_PATH..."
sudo mkdir -p "$PUB_CACHE_PATH"
sudo chown -R "$SDK_OWNER":"$SDK_OWNER" "$PUB_CACHE_PATH"
sudo sh -c "echo 'export PUB_CACHE=\"$PUB_CACHE_PATH\"' > /etc/profile.d/pub_cache.sh"
print_success "Shared pub cache directory created."

# --- 2. Update and Install Prerequisite Packages ---
print_info "Updating package lists and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y git curl unzip openjdk-11-jdk

# --- 2. Install Flutter SDK ---
if command_exists flutter; then
    print_success "Flutter is already installed."
else
    print_info "Installing Flutter SDK..."
    sudo mkdir -p "$FLUTTER_SDK_PATH"
    sudo chown -R "$SDK_OWNER":"$SDK_OWNER" "$FLUTTER_SDK_PATH"

    # Run git clone as the SDK_OWNER user
    sudo -u "$SDK_OWNER" git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION --depth 1 "$FLUTTER_SDK_PATH"

    sudo sh -c "echo 'export PATH=\"\$PATH:$FLUTTER_SDK_PATH/bin\"' > /etc/profile.d/flutter.sh"
    print_success "Flutter SDK installed. Run 'source /etc/profile.d/flutter.sh' to update your PATH."
fi

# --- 3. Install Android SDK Command-line Tools ---
if [ -d "$ANDROID_SDK_PATH" ]; then
    print_success "Android SDK directory already exists."
else
    print_info "Installing Android SDK command-line tools..."
    SDK_TOOLS_VERSION="8512546"
    SDK_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${SDK_TOOLS_VERSION}_latest.zip"

    sudo mkdir -p "$ANDROID_SDK_PATH"
    sudo chown -R "$SDK_OWNER":"$SDK_OWNER" "$ANDROID_SDK_PATH"

    cd /tmp
    curl -o android_tools.zip "$SDK_TOOLS_URL"
    # Unzip as the SDK_OWNER user
    sudo -u "$SDK_OWNER" unzip -q android_tools.zip -d "$ANDROID_SDK_PATH"
    rm android_tools.zip
    cd -

    sudo sh -c "echo 'export ANDROID_SDK_ROOT=\"$ANDROID_SDK_PATH\"' > /etc/profile.d/android.sh"
    sudo sh -c "echo 'export PATH=\"\$PATH:\$ANDROID_SDK_ROOT/cmdline-tools/bin:\$ANDROID_SDK_ROOT/platform-tools\"' >> /etc/profile.d/android.sh"
    print_success "Android SDK installed. Run 'source /etc/profile.d/android.sh' to update your PATH."
fi

# --- 4. Accept Licenses and Install SDK Packages ---
print_info "Accepting Android SDK licenses and installing packages..."
# Run sdkmanager as the SDK_OWNER
sudo -u "$SDK_OWNER" sh -c "yes | $ANDROID_SDK_PATH/cmdline-tools/bin/sdkmanager --licenses > /dev/null" || true
sudo -u "$SDK_OWNER" "$ANDROID_SDK_PATH/cmdline-tools/bin/sdkmanager" "platform-tools" "platforms;android-33" "build-tools;33.0.2"

print_success "Build environment setup is complete."
