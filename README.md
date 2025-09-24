### The ROKCT app

All custom work lives here

### Installation

You can install this app using the [bench](https://github.com/frappe/bench) CLI:

```bash
cd $PATH_TO_YOUR_BENCH
bench get-app $URL_OF_THIS_REPO --branch develop
bench install-app rokct
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
