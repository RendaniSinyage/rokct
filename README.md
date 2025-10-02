### The ROKCT app

All custom work lives here

### Installation

You can install this app using the [bench](https://github.com/frappe/bench) CLI:

```bash
cd $PATH_TO_YOUR_BENCH
bench get-app $URL_OF_THIS_REPO --branch develop
bench install-app rokct
```

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

### Post-Installation Setup

This app includes an automated setup process that runs when you install it.

**Control Panel Site Setup:**

If you are installing this app on your main **Control Panel** site (which must be named `platform.rokct.ai`), the `after_install` script will automatically configure all the necessary values in your `site_config.json`. This includes setting the `app_role`, `tenant_domain`, and other critical values. No manual editing of configuration files is required.

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
