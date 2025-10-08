(function() {
    function createTopBarElements() {
        const navbar = document.querySelector('.navbar-app .navbar-title-area');
        if (!navbar || document.querySelector('.dynamic-header-container')) {
            // Elements already exist or navbar not found
            return;
        }

        // Create container for new elements
        const topBarContainer = document.createElement('div');
        topBarContainer.className = 'dynamic-header-container';

        // 1. Create Dynamic Header
        const dynamicHeader = document.createElement('div');
        dynamicHeader.className = 'dynamic-header';
        dynamicHeader.innerText = 'Workspace'; // Default text

        // 2. Create Weather Widget
        const weatherWidget = document.createElement('div');
        weatherWidget.className = 'weather-widget';
        weatherWidget.innerHTML = '<i class="ri ri-loader-4-line"></i> Loading...';

        topBarContainer.appendChild(dynamicHeader);
        topBarContainer.appendChild(weatherWidget);

        // Hide original title and inject new container
        const originalTitle = navbar.querySelector('.page-title');
        if (originalTitle) {
            originalTitle.style.display = 'none';
        }
        navbar.appendChild(topBarContainer);

        fetchWeather();
    }

    function updateHeader() {
        const headerElement = document.querySelector('.dynamic-header');
        if (!headerElement) return;

        let currentRoute = frappe.get_route();
        let title = "Workspace"; // Default

        if (currentRoute) {
            if (currentRoute[0] === "app") {
                if (currentRoute.length > 1) {
                    title = frappe.utils.to_title_case(currentRoute[1].replace(/_/g, ' '));
                }
            } else {
                 title = frappe.utils.to_title_case(currentRoute[0].replace(/_/g, ' '));
            }
        }
        headerElement.innerText = title;
    }

    function fetchWeather() {
        const widget = document.querySelector('.weather-widget');
        if (!widget) return;

        frappe.call({
            method: 'rokct.rokct.api.get_weather',
            args: {
                location: 'auto:ip' // Use default location from settings
            },
            callback: function(r) {
                if (r.message && r.message.current) {
                    const weather = r.message;
                    const temp = Math.round(weather.current.temp_c);
                    const iconUrl = weather.current.condition.icon;

                    widget.innerHTML = `
                        <img src="${iconUrl}" alt="${weather.current.condition.text}" class="weather-icon">
                        <span>${temp}°C, ${weather.location.name}</span>
                    `;
                } else {
                    widget.innerHTML = '<i class="ri ri-error-warning-line"></i> Weather unavailable';
                }
            },
            error: function() {
                 widget.innerHTML = '<i class="ri ri-error-warning-line"></i> Weather unavailable';
            }
        });
    }

    function handleRouteChange() {
        createTopBarElements(); // Creates elements if they don't exist
        updateHeader(); // Updates header on every route change
    }

    // Hook into Frappe's route change event
    frappe.router.on('change', handleRouteChange);

})();