<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name') }} API Status</title>
    <link rel="icon" type="image/png" href="https://food.juvo.app/favicon.png">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
  
    <style>
        :root {
            --primary-color: #ff6600;
            --secondary-color: #50E3C2;
            --background-color: rgba(0, 0, 0, 0.6);
            --text-color: #FFFFFF;
            --operational-color: #4CAF50;
            --error-color: rgba(255, 0, 0, 0.5);
            
        }
        body, html {
            height: 100%;
            margin: 0;
            font-family: 'Inter', sans-serif;
            color: var(--text-color);
            overflow-x: hidden;
            overflow-y: auto;
            font-size: 16px;
        }
        .bg {
            background-image: url('https://admin.juvo.app/img/background2.jpg');
            height: 100%;
            background-position: center;
            background-repeat: no-repeat;
            background-size: cover;
            filter: blur(8px);
            -webkit-filter: blur(8px);
            transform: scale(1.1);
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            z-index: -1;
        }
        .overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: rgba(0, 0, 0, 0.5);
            z-index: -1;
        }
        .content {
            position: relative;
            width: 90%;
            max-width: 1200px;
            margin: 2rem auto;
            padding: 2rem;
            background-color: var(--background-color);
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
        }
        h1, h2, h3 {
            color: var(--secondary-color);
            text-align: center;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; }
        h2 { font-size: 1.8rem; margin-top: 2rem; }
        h3 { font-size: 1.5rem; margin-top: 1.5rem; }
        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 1rem;
        }
        .status-item {
            background-color: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            border-radius: 10px;
            transition: all 0.3s ease;
            backdrop-filter: blur(5px);
            -webkit-backdrop-filter: blur(5px);
            text-align: center;
        }
        .status-item:hover {
            transform: translateY(-3px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        
        .status-item.wateros {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            height: auto;
            padding: 1rem;
            overflow: hidden; /* Ensure blur doesn't extend outside the container */
            
        }
        .wateros-label {
            
            fontFamily: 'Nunito', 'Arial Rounded MT Bold', 'Helvetica Rounded', Arial, sans-serif;
            font-size: 2.6rem;
            font-weight: 400;
            line-height: 1;
            margin-bottom: 0.5rem;
            filter: blur(1px); /* Add blur effect */
            text-shadow: 0 0 10px rgba(255, 255, 255, 0.5); /* Optional: add glow effect */
        }

        .wateros-status {
            font-size: 1.0rem;
            font-weight: bold;
        }
        .status-label {
            font-size: 0.9rem;
            color: var(--secondary-color);
            margin-bottom: 0.5rem;
        }
        .status-value {
            font-size: 1.1rem;
            font-weight: 600;
        }
        .collapsible {
            background-color: rgba(255, 255, 255, 0.1);
            color: var(--text-color);
            cursor: pointer;
            padding: 18px;
            width: 100%;
            border: none;
            text-align: left;
            outline: none;
            font-size: 1rem;
            transition: 0.4s;
            border-radius: 10px;
            margin-top: 2rem;
            
        }
        .active, .collapsible:hover {
            background-color: rgba(255, 255, 255, 0.2);
        }
        .collapsible:after {
            content: '\002B';
            color: var(--secondary-color);
            font-weight: bold;
            float: right;
            margin-left: 5px;
        }
        .active:after { content: "\2212"; }
        .collapsible-content {
            padding: 0 18px;
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.2s ease-out;
            background-color: rgba(255, 255, 255, 0.05);
            border-radius: 0 0 10px 10px;
            
        }
        .operational { background-color: var(--operational-color); }
        .error { background-color: var(--error-color); }
        .incident {
            background-color: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            border-radius: 10px;
            margin-top: 1rem;
        }
        .incident-title {
            font-weight: bold;
            margin-bottom: 0.5rem;
        }
        .incident-details {
            font-size: 0.9rem;
        }
        .collapsible-content > * {
            margin-top: 1rem;
        }
        #juvoStatus {
            background-color: var(--primary-color);
            color: white;
            padding: 15px;
            border-radius: 5px;
            text-align: center;
            margin-bottom: 20px;
            font-weight: bold;
            font-size: 1.2rem;
        }
        @media (max-width: 768px) {
            body, html {
                font-size: 14px;
            }
            .content {
                padding: 1rem;
                margin: 1rem auto;
                
            }
            h1 { font-size: 2rem; }
            h2 { font-size: 1.5rem; }
            h3 { font-size: 1.2rem; }
            .status-grid {
                grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
                margin-bottom: 1rem;
            }
            .collapsible {
                padding: 15px;
                
            }
            #juvoStatus {
                font-size: 1rem;
                padding: 10px;
                margin-bottom: 2rem;
            }
        }
        @media (max-width: 480px) {
            body, html {
                font-size: 12px;
            }
            .content {
                width: 95%;
                padding: 0.5rem;
            }
            .status-grid {
                grid-template-columns: 1fr;
                margin-bottom: 2rem
            }
            .status-item {
                padding: 0.5rem;
            }
        }
    </style>
</head>
<body>
    <div class="bg"></div>
    <div class="overlay"></div>
    <div class="content">
        <h1>{{ config('app.name') }} API Status</h1>
        <div id="juvoStatus">{{ config('app.name') }} API Status: Checking...</div>
        <div class="status-grid">
            <div class="status-item">
                <div class="status-label">Uptime</div>
                <div class="status-value" id="uptime">Loading...</div>
            </div>
            <div class="status-item">
                <div class="status-label">Last Restart</div>
                <div class="status-value" id="lastRestart">Loading...</div>
            </div>
            <div class="status-item">
                <div class="status-label">Version</div>
                <div class="status-value" id="version">Loading...</div>
            </div>
            <div class="status-item">
                <div class="status-label">Maintenance</div>
                <div class="status-value" id="maintenance">Loading...</div>
            </div>
        </div>

        <button class="collapsible" id="juvoStatusButton">Juvo Network Status</button>
        <div class="collapsible-content">
            <div class="status-grid" id="juvoStatusGrid"></div>
        </div>

        <button class="collapsible" id="payfastStatusButton">PayFast API Status</button>
        <div class="collapsible-content">
            <div id="payfastOverallStatus" class="status-item"></div>
            <h3>Components</h3>
            <div class="status-grid" id="payfastComponents"></div>
            <div id="payfastMaintenance"></div>
            <div id="payfastIncidents"></div>
        </div>

        <button class="collapsible" id="paystackStatusButton">Paystack API Status</button>
        <div class="collapsible-content">
            <div id="paystackOverallStatus" class="status-item"></div>
            <h3>Components</h3>
            <div class="status-grid" id="paystackComponents"></div>
            <div id="paystackMaintenance"></div>
            <div id="paystackIncidents"></div>
        </div>

        <button class="collapsible" id="flutterwaveStatusButton">Flutterwave API Status</button>
        <div class="collapsible-content">
            <div id="flutterwaveOverallStatus" class="status-item"></div>
            <h3>Components</h3>
            <div class="status-grid" id="flutterwaveComponents"></div>
            <div id="flutterwaveMaintenance"></div>
            <div id="flutterwaveIncidents"></div>
        </div>
    </div>

    <script>
        function updateStatus(data) {
            document.getElementById('uptime').textContent = data.uptime;
            document.getElementById('lastRestart').textContent = data.last_restart;
            document.getElementById('version').textContent = data.version;
            document.getElementById('maintenance').textContent = data.maintenance.status;
            
            const juvoStatusElement = document.getElementById('juvoStatus');
            juvoStatusElement.textContent = `{{ config('app.name') }} API Status: ${data.status}`;
            
            const juvoStatusGrid = document.getElementById('juvoStatusGrid');
            juvoStatusGrid.innerHTML = '';
            const services = ['juvo_food', 'main_website', 'admin_panel', 'juvo_agency', 'one_platform', 'n8n_platform', 'wateros', 'image_server'];
            services.forEach(service => {
                if (data[service]) {
                    const div = document.createElement('div');
                    div.className = `status-item ${data[service].status === 'OK' ? 'operational' : 'error'}`;
                    if (service === 'wateros') {
                        if (data[service].status === 'OK') {
                             div.style.backgroundColor = 'rgba(255, 255, 255, 0.015)';
                            } else {
                             div.style.backgroundColor = 'var(--error-color)';// Red with transparency
                            };
                        div.innerHTML = `
                           <div class="wateros-label"><span style="color: white;">Water</span><span style="color: skyblue;">OS</span></div>
                           
                            <div class="wateros-status">${data[service].status}</div>
                        `;
                        } else if (service === 'image_server') {
                        if (data[service].status === 'OK') {
                             div.style.backgroundColor = 'rgba(255, 255, 255, 0.015)';
                            } else {
                             div.style.backgroundColor = 'var(--error-color)';// Red with transparency
                            };
                        div.innerHTML = `
                            <div class="wateros-label">Images<div class="wateros-status"><span style="color: white;">Storage Network</span></div></div>
                            <div class="wateros-status">${data[service].status}</div>
                        `;
                         } else if (service === 'one_platform') {
                        if (data[service].status === 'OK') {
                             div.style.backgroundColor = 'rgba(255, 255, 255, 0.015)';
                            } else {
                             div.style.backgroundColor = 'var(--error-color)';// Red with transparency
                            };
                        div.innerHTML = `
                            <div class="wateros-label"><span style="color: var(--primary-color);">Juvo</span><span style="color: white;">One</span><div class="wateros-status"><span style="color: white;">Platform</span></div></div>
                            <div class="wateros-status">${data[service].status}</div>
                        `;
                         } else if (service === 'juvo_food') {
                        if (data[service].status === 'OK') {
                             div.style.backgroundColor = 'rgba(255, 255, 255, 0.015)';
                            } else {
                             div.style.backgroundColor = 'var(--error-color)';// Red with transparency
                            };
                        div.innerHTML = `
                            <div class="wateros-label"><span style="color: var(--primary-color);">Juvo</span><span style="color: white;">Food</span><div class="wateros-status"><span style="color: white;">Web App</span></div></div>
                            <div class="wateros-status">${data[service].status}</div>
                        `;
                         } else if (service === 'main_website') {
                        if (data[service].status === 'OK') {
                             div.style.backgroundColor = 'rgba(255, 255, 255, 0.015)';
                            } else {
                             div.style.backgroundColor = 'var(--error-color)';// Red with transparency
                            };
                        div.innerHTML = `
                            <div class="wateros-label"><span style="color: var(--primary-color);">Juvo</span><div class="wateros-status"><span style="color: white;">Corporate</span></div></div>
                            <div class="wateros-status">${data[service].status}</div>
                        `;
                         } else if (service === 'n8n_platform') {
                        if (data[service].status === 'OK') {
                             div.style.backgroundColor = 'rgba(255, 255, 255, 0.015)';
                            } else {
                             div.style.backgroundColor = 'var(--error-color)';// Red with transparency
                            };
                        
                        div.innerHTML = `
                            <div class="wateros-label"><span style="color: var(--primary-color);">N</span><span style="color: white;">8</span><span style="color: var(--primary-color);">N</span><div class="wateros-status"><span style="color: white;">platform</span></div></div>
                            <div class="wateros-status">${data[service].status}</div>
                        `;
                        } else if (service === 'juvo_agency') {
                        if (data[service].status === 'OK') {
                             div.style.backgroundColor = 'rgba(255, 255, 255, 0.015)';
                            } else {
                             div.style.backgroundColor = 'var(--error-color)';// Red with transparency
                            };
                        
                        div.innerHTML = `
                            <div class="wateros-label"><span style="color: white;">Juvo</span><div class="wateros-status"><span>Agency</span></div></div>
                            <div class="wateros-status">${data[service].status}</div>
                        `;
                         } else if (service === 'admin_panel') {
                        if (data[service].status === 'OK') {
                             div.style.backgroundColor = 'rgba(255, 255, 255, 0.015)';
                            } else {
                             div.style.backgroundColor = 'var(--error-color)';// Red with transparency
                            };
                        
                        div.innerHTML = `
                            <div class="wateros-label"><span style="color: var(--primary-color);">Juvo</span><span style="color: white;">Food</span><div class="wateros-status"><span style="color: white;">Admin Panel</span></div></div>
                            <div class="wateros-status">${data[service].status}</div>
                        `;
                    } else {
                        div.innerHTML = `
                            <div class="status-label">${service.replace('_', ' ').toUpperCase()}</div>
                            <div class="status-value">${data[service].status}</div>
                        `;
                    }
                    juvoStatusGrid.appendChild(div);
                }
            });
        }

        function updatePaymentStatus(data, prefix) {
            const overallStatus = document.getElementById(`${prefix}OverallStatus`);
            overallStatus.innerHTML = `
                <div class="status-label">Overall Status</div>
                <div class="status-value">${data.status.description || data.status}</div>
            `;
            overallStatus.className = data.status.description === "All Systems Operational" || data.status === "none" ? 
                "status-item operational" : "status-item error";

            const componentsContainer = document.getElementById(`${prefix}Components`);
            componentsContainer.innerHTML = '';
            for (const key in data.components) {
                const component = data.components[key];
                const componentDiv = document.createElement('div');
                componentDiv.className = `status-item ${component.status === 'operational' ? 'operational' : 'error'}`;
                componentDiv.innerHTML = `<div class="status-label">${component.name}</div>`;
                componentsContainer.appendChild(componentDiv);
            }

            const maintenanceContainer = document.getElementById(`${prefix}Maintenance`);
            if (data.scheduled_maintenance && data.scheduled_maintenance.length > 0) {
                maintenanceContainer.innerHTML = '<h3>Scheduled Maintenance</h3>';
                data.scheduled_maintenance.forEach(maintenance => {
                    const maintenanceDiv = document.createElement('div');
                    maintenanceDiv.className = 'incident';
                    maintenanceDiv.innerHTML = `
                        <div class="incident-title">${maintenance.name}</div>
                        <div class="incident-details">
                            Scheduled for: ${new Date(maintenance.scheduled_for || maintenance.scheduled_until).toLocaleString()}
                        </div>
                    `;
                    maintenanceContainer.appendChild(maintenanceDiv);
                });
            } else {
                maintenanceContainer.innerHTML = '';
            }

            const incidentsContainer = document.getElementById(`${prefix}Incidents`);
            if (data.incidents && data.incidents.length > 0) {
                incidentsContainer.innerHTML = '<h3>Recent Incidents</h3>';
                data.incidents.slice(0, 5).forEach(incident => {
                    const incidentDiv = document.createElement('div');
                    incidentDiv.className = 'incident';
                    incidentDiv.innerHTML = `
                        <div class="incident-title">${incident.name}</div>
                        <div class="incident-details">
                            Status: ${incident.status}<br>
                            Created: ${new Date(incident.created_at).toLocaleString()}
                        </div>
                    `;
                    incidentsContainer.appendChild(incidentDiv);
                });
            } else {
                incidentsContainer.innerHTML = '';
            }
        }

        function checkApiStatus() {
            fetch('https://api.juvo.app/api/v1/rest/status/details')
                .then(response => response.json())
                .then(data => {
                    updateStatus(data.juvo_platform);
                    updatePaymentStatus(data.payfast, 'payfast');
                    updatePaymentStatus(data.paystack, 'paystack');
                    updatePaymentStatus(data.flutterwave, 'flutterwave');
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('juvoStatus').textContent = '{{ config('app.name') }} API Status: Error';
                    document.getElementById('juvoStatus').classList.add('error');
                });
        }

        // Check API status on page load
        checkApiStatus();

        // Recheck API status every 60 seconds
        setInterval(checkApiStatus, 60000);

        // Set up collapsible sections
        var coll = document.getElementsByClassName("collapsible");
        for (var i = 0; i < coll.length; i++) {
            coll[i].addEventListener("click", function() {
                this.classList.toggle("active");
                if (this.id === 'payfastStatusButton') {
                    this.classList.remove('operational');
                }
                var content = this.nextElementSibling;
                if (content.style.maxHeight){
                    content.style.maxHeight = null;
                } else {
                    content.style.maxHeight = content.scrollHeight + "px";
                }
            });
        }
    </script>
</body>
</html>
