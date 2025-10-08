(function() {
    // 1. Define Sidebar Structure
    const navItems = {
        'Seller': [
            { icon: 'home-line', route: '/app', name: 'Home' },
            { icon: 'shopping-bag-2-line', route: '/app/order', name: 'Orders' },
            { icon: 'user-search-line', route: '/app/customer', name: 'Customers' },
            { icon: 'table-line', route: '/app/table', name: 'Tables' },
            { icon: 'money-dollar-circle-line', route: '/app/sales-invoice', name: 'Sales History' },
            { icon: 'pie-chart-line', route: '/app/income', name: 'Income' },
            { icon: 'bread-line', route: '/app/stock', name: 'Inventory' },
            { icon: 'blur-off-line', route: '/app/dashboard', name: 'Dashboard' },
        ],
        'Cook': [
            { icon: 'restaurant-line', route: '/app/kitchen', name: 'Kitchen' },
        ],
        'Waiter': [
            { icon: 'home-line', route: '/app', name: 'Home' },
            { icon: 'shopping-bag-line', route: '/app/order', name: 'Orders' },
            { icon: 'table-line', route: '/app/table', name: 'Tables' },
        ],
        'System Manager': [ // Admin role
            { icon: 'shopping-bag-2-line', route: '/app/order', name: 'Orders' },
            { icon: 'user-search-line', route: '/app/customer', name: 'Customers' },
            { icon: 'blur-off-line', route: '/app/dashboard', name: 'Dashboard' },
        ]
    };

    function buildSidebar() {
        // If sidebar already exists, don't build it again
        if (document.querySelector('.custom-sidebar-container')) {
            return;
        }

        // 2. Get User Roles
        const userRoles = frappe.user.roles;

        // Determine which set of nav items to use
        let itemsToShow = [];
        if (userRoles.includes('System Manager')) {
            itemsToShow = navItems['System Manager'];
        } else if (userRoles.includes('Seller')) {
            itemsToShow = navItems['Seller'];
        } else if (userRoles.includes('Waiter')) {
            itemsToShow = navItems['Waiter'];
        } else if (userRoles.includes('Cook')) {
            itemsToShow = navItems['Cook'];
        }

        if (itemsToShow.length === 0) return; // No custom sidebar for this role

        // 3. Hide Default Sidebar & Create New One
        const pageContainer = document.querySelector('.page-container');
        if (!pageContainer) return;

        const existingSidebar = document.querySelector('.workspace-sidebar');
        if (existingSidebar) {
            existingSidebar.style.display = 'none';
        }

        const customSidebar = document.createElement('div');
        customSidebar.className = 'custom-sidebar-container';

        const navList = document.createElement('ul');
        navList.className = 'custom-sidebar-nav';

        // 4. Build Sidebar Content
        itemsToShow.forEach(item => {
            const listItem = document.createElement('li');
            const link = document.createElement('a');
            link.href = item.route;
            link.className = 'nav-item';
            link.dataset.route = item.route;
            link.innerHTML = `<i class="ri ri-${item.icon}"></i>`;

            link.addEventListener('click', (e) => {
                e.preventDefault();
                frappe.set_route(item.route);
            });

            listItem.appendChild(link);
            navList.appendChild(listItem);
        });

        const logoutItem = document.createElement('li');
        logoutItem.className = 'logout-item';
        const logoutLink = document.createElement('a');
        logoutLink.href = '#';
        logoutLink.innerHTML = '<i class="ri ri-logout-circle-line"></i>';
        logoutLink.onclick = (e) => {
            e.preventDefault();
            frappe.app.logout();
        };
        logoutItem.appendChild(logoutLink);

        customSidebar.appendChild(navList);
        customSidebar.appendChild(logoutItem);

        // Inject sidebar
        pageContainer.insertBefore(customSidebar, pageContainer.firstChild);
        document.body.classList.add('custom-sidebar-active');
    }

    function updateActiveState() {
        const currentRoute = frappe.get_route_str();
        const sidebar = document.querySelector('.custom-sidebar-container');
        if (!sidebar) return;

        const navItems = sidebar.querySelectorAll('.nav-item');
        navItems.forEach(item => {
            if (item.dataset.route === currentRoute) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });
    }

    function handleRouteChange() {
        buildSidebar(); // This will only create the sidebar once
        updateActiveState(); // This will update the active icon on every route change
    }

    // Use frappe.router.on to handle SPA navigation and initial load
    frappe.router.on('change', handleRouteChange);

})();