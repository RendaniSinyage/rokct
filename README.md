### The ROKCT app

All custom work lives here

### Installation

You can install this app using the [bench](https://github.com/frappe/bench) CLI:

```bash
cd $PATH_TO_YOUR_BENCH
bench get-app $URL_OF_THIS_REPO --branch develop
bench install-app rokct
```

### Frontend Development

This app uses a modern frontend stack built on [Frappe UI](https://github.com/frappe/frappe-ui), which is a component library based on Vue 3 and Tailwind CSS. This replaces the standard Frappe Desk interface with a custom, modern UI.

*   **Source Code:** All frontend source code is located in the `/ui` directory.
*   **Build Process:** The frontend assets are built automatically when the app is installed or updated on a `control_panel` site. This process is handled by a script in `rokct/build.py`.

#### `frappe-ui` Resources

The official `frappe-ui` repository is an excellent resource for documentation and understanding the available components.

*   **Official Repository:** [https://github.com/frappe/frappe-ui](https://github.com/frappe/frappe-ui)

#### Projects Using Frappe UI

Many modern Frappe projects use `frappe-ui`. These repositories serve as great real-world examples:

*   [Frappe Builder](https://github.com/frappe/builder)
*   [Frappe Insights](https://github.com/frappe/insights)
*   [Gameplan](https://github.com/frappe/gameplan)
*   [Helpdesk](https://github.com/frappe/helpdesk)
*   [Frappe Drive](https://github.com/frappe/drive)
*   Frappe Cloud (not open source)

### Debugging with the AI Agent

The owner of this repository is not a developer and relies on an AI software engineer for maintenance and development.

When a complex issue cannot be solved quickly, the most effective debugging strategy is to have the AI agent create a **temporary, single-use debug script**. This script is not part of the main application code. Its purpose is to run a specific failing process (like site cancellation) from the command line and print detailed, step-by-step logs.

The owner can then execute this script with a `bench execute` command and provide the logs back to the agent. This gives the agent the precise information needed to diagnose the problem without guesswork.

#### Example Debug Scripts

The following scripts are available for debugging common complex processes:

1.  **To debug a new site provisioning:**
    *   This script runs the entire site creation and setup process synchronously.
    *   It uses hardcoded details for the 'Black Wealth Institute' tenant.
    *   **Command:**
        ```bash
        bench --site platform.rokct.ai execute rokct.rokct.scripts.debug_provisioning.trigger_provisioning_for_debug
        ```

2.  **To debug a site cancellation:**
    *   This script mimics changing a subscription status to "Canceled" to trigger the site deletion process.
    *   You must replace `your-tenant-site.rokct.ai` with the actual site name you want to test.
    *   **Command:**
        ```bash
        bench --site platform.rokct.ai execute rokct.rokct.scripts.debug_cancellation.trigger_cancellation_for_debug --kwargs '{"site_name": "your-tenant-site.rokct.ai"}'
        ```

3.  **To debug the full customer deletion cascade:**
    *   This script deletes a Customer record, which should trigger the cancellation of their subscriptions and the deletion of their site(s).
    *   You must replace `'Customer Name'` with the exact name of the customer you want to delete.
    *   **Command:**
        ```bash
        bench --site platform.rokct.ai execute rokct.rokct.scripts.debug_customer_deletion.trigger_customer_deletion_for_debug --kwargs '{"customer_name": "Customer Name"}'
        ```

### Post-Installation Setup

This app includes an automated setup process that runs when you install it.

#### Automated Build Environment Setup

**This is a critical feature for developers.** If the app is installed on a site designated as the "control panel" (`platform.rokct.ai`), the installation script will perform a comprehensive setup of the development environment required to build the Flutter mobile apps.

This process includes:
*   **Installing System Packages:** It will use `apt-get` to install necessary build tools like `clang`, `cmake`, and `ninja-build`, as well as a specific version of the OpenJDK.
*   **Downloading SDKs:** It will download and install specific, version-locked releases of the Flutter and Android SDKs into a local `sdks` directory within your bench.
*   **Automated PATH Configuration:** The script will automatically and safely modify your user's `~/.bashrc` file to include the necessary environment variables (`FLUTTER_HOME`, `ANDROID_HOME`) and update the system `PATH`.

**All versions for these tools are managed in the `rokct/versions.json` file.** This ensures a consistent, reproducible build environment. After the installation, you must reload your shell (`source ~/.bashrc`) for the changes to take effect.

**Control Panel Site Setup:**

If you are installing this app on your main **Control Panel** site (which must be named `platform.rokct.ai`), the `after_install` script will also automatically configure all the necessary values in your `site_config.json`. This includes setting the `app_role`, `tenant_domain`, and other critical values. No manual editing of configuration files is required.

**Tenant Site Setup:**

Tenant sites are not created manually. They are provisioned automatically via the Control Panel's API.

### Contributing

This app uses `pre-commit` for code formatting and linting. Please [install pre-commit](https://pre-commit.com/#installation) and enable it for this repository:

```bash
cd apps/rokct
pre-commit install
```

Pre-commit is configured to use the following tools for checking and formatting your code:

- ruff
- eslint
- prettier
- pyupgrade

### License

mit

### Important Configuration Notes

#### App Installation Order

For the application branding (logo, app name, etc.) to apply correctly, the `rokct` app should be one of the last apps installed on your site.

Frappe applies settings from apps in the order they are installed. If another app that modifies "Website Settings" is installed after `rokct`, it may override the branding settings set by this app.
