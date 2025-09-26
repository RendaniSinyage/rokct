let map, drawingManager, geocoder, searchMarker, heatmap;
let markers = [];
let spazas = [];
let zones = [];
let taxiRoutes = [];
let secondaryTaxiRoutes = [];
let addingStations = false;
let addingSpazas = false;
let addingZone = false;
let addingTaxiRoute = false;
let addingSecondaryTaxiRoute = false;
let activeZone = null;
let spazaCounter = 1;
let selectedCompetitor = null;

const PRIMARY_ROUTE_COLOR = '#FF0000';  // Red
const SECONDARY_ROUTE_COLOR = '#FFA500';  // Orange

const zoneColors = [
    '#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF',
    '#FFA500', '#800080', '#008000', '#FFC0CB', '#800000', '#008080'
];

function getUniqueColor() {
    const usedColors = zones.map(zone => zone.color);
    return zoneColors.find(color => !usedColors.includes(color)) || '#' + Math.floor(Math.random()*16777215).toString(16);
}

// This function will be called by the Google Maps script once it's loaded
function initMap() {
    console.log("initMap function called");
    if (!document.getElementById('map')) {
        console.error("Map element not found");
        return;
    }
    map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: -22.34058, lng: 30.01341},
        zoom: 10,
        styles: [
            {
                featureType: "poi",
                elementType: "labels",
                stylers: [{ visibility: "off" }]
            }
        ]
    });

    geocoder = new google.maps.Geocoder();

    drawingManager = new google.maps.drawing.DrawingManager({
        drawingMode: null,
        drawingControl: false,
        polygonOptions: {
            editable: true,
            fillOpacity: 0.3,
            strokeWeight: 2
        },
        polylineOptions: {
            strokeWeight: 3
        }
    });
    drawingManager.setMap(map);

    google.maps.event.addListener(drawingManager, 'polygoncomplete', function(polygon) {
        if (addingZone) {
            addZone(polygon);
        }
        drawingManager.setDrawingMode(null);
        addingZone = false;
        updateButtonStates();
    });

    google.maps.event.addListener(drawingManager, 'polylinecomplete', function(polyline) {
        if (addingTaxiRoute) {
            addTaxiRoute(polyline);
            addingTaxiRoute = false;
        } else if (addingSecondaryTaxiRoute) {
            addSecondaryTaxiRoute(polyline);
            addingSecondaryTaxiRoute = false;
        }
        drawingManager.setDrawingMode(null);
        updateButtonStates();
    });

    map.addListener('click', function(e) {
        if (addingStations) {
            placeMarker(e.latLng);
        } else if (addingSpazas) {
            addSpaza(e.latLng);
        }
    });

    setupUI();
    loadCompetitors();
}

function setupUI() {
    // Search
    $('#search-button').on('click', searchLocation);

    // Controls
    $('#add-station-btn').on('click', () => toggleAdding('stations'));
    $('#add-spaza-btn').on('click', () => toggleAdding('spazas'));
    $('#add-zone-btn').on('click', () => toggleAdding('zone'));
    $('#add-taxi-route-btn').on('click', () => toggleAdding('taxiRoute'));
    $('#add-secondary-taxi-route-btn').on('click', () => toggleAdding('secondaryTaxiRoute'));

    // Data
    $('#save-data-btn').on('click', saveCompetitorData);
    $('#clear-all-btn').on('click', clearAll);

    // Competitor selection
    $('#competitor-select').on('change', function() {
        selectedCompetitor = $(this).val();
        if (selectedCompetitor) {
            loadCompetitorData(selectedCompetitor);
        } else {
            clearAll();
        }
    });
}

function toggleAdding(type) {
    addingStations = type === 'stations' ? !addingStations : false;
    addingSpazas = type === 'spazas' ? !addingSpazas : false;

    addingZone = type === 'zone' ? !addingZone : false;
    if (addingZone) drawingManager.setDrawingMode(google.maps.drawing.OverlayType.POLYGON);

    addingTaxiRoute = type === 'taxiRoute' ? !addingTaxiRoute : false;
    if (addingTaxiRoute) drawingManager.setDrawingMode(google.maps.drawing.OverlayType.POLYLINE);

    addingSecondaryTaxiRoute = type === 'secondaryTaxiRoute' ? !addingSecondaryTaxiRoute : false;
    if (addingSecondaryTaxiRoute) drawingManager.setDrawingMode(google.maps.drawing.OverlayType.POLYLINE);

    if (type !== 'zone' && type !== 'taxiRoute' && type !== 'secondaryTaxiRoute') {
        drawingManager.setDrawingMode(null);
    }

    updateButtonStates();
}

function updateButtonStates() {
    $('#add-station-btn').toggleClass('btn-primary', addingStations).toggleClass('btn-default', !addingStations);
    $('#add-spaza-btn').toggleClass('btn-primary', addingSpazas).toggleClass('btn-default', !addingSpazas);
    $('#add-zone-btn').toggleClass('btn-primary', addingZone).toggleClass('btn-default', !addingZone);
    $('#add-taxi-route-btn').toggleClass('btn-primary', addingTaxiRoute).toggleClass('btn-default', !addingTaxiRoute);
    $('#add-secondary-taxi-route-btn').toggleClass('btn-primary', addingSecondaryTaxiRoute).toggleClass('btn-default', !addingSecondaryTaxiRoute);
}

function searchLocation() {
    const address = $('#search-input').val();
    if (!address) return;

    geocoder.geocode({ 'address': address }, function(results, status) {
        if (status === 'OK') {
            map.setCenter(results[0].geometry.location);
            map.setZoom(12);
            if (searchMarker) searchMarker.setMap(null);
            searchMarker = new google.maps.Marker({
                map: map,
                position: results[0].geometry.location
            });
        } else {
            showNotification("Couldn't find the location. Please try again.", "error");
        }
    });
}

function addZone(polygon, name = null) {
    const zoneName = name || prompt("Enter a name for this zone:");
    if (!zoneName) {
        polygon.setMap(null);
        return;
    }
    const zoneColor = getUniqueColor();
    polygon.setOptions({
        fillColor: zoneColor,
        strokeColor: zoneColor
    });
    const zone = {
        polygon: polygon,
        name: zoneName,
        color: zoneColor,
    };
    zones.push(zone);
}

function addTaxiRoute(polyline, name = null) {
    const routeName = name || prompt("Enter a name for this main taxi route:");
    if (!routeName) {
        polyline.setMap(null);
        return;
    }
    polyline.setOptions({ strokeColor: PRIMARY_ROUTE_COLOR });
    const route = { polyline: polyline, name: routeName, type: 'Primary' };
    taxiRoutes.push(route);
}

function addSecondaryTaxiRoute(polyline, name = null) {
    const routeName = name || prompt("Enter a name for this secondary taxi route:");
    if (!routeName) {
        polyline.setMap(null);
        return;
    }
    polyline.setOptions({ strokeColor: SECONDARY_ROUTE_COLOR });
    const route = { polyline: polyline, name: routeName, type: 'Secondary' };
    secondaryTaxiRoutes.push(route);
}

function addSpaza(location, name = null) {
    const spazaName = name || `Spaza ${spazaCounter++}`;
    const spaza = new google.maps.Marker({
        position: location,
        map: map,
        label: { text: spazaName },
        icon: {
            path: google.maps.SymbolPath.CIRCLE,
            scale: 8,
            fillColor: "#FFD700",
            fillOpacity: 0.8,
            strokeWeight: 2,
            strokeColor: "#FFA500"
        }
    });
    spazas.push({marker: spaza, name: spazaName});
}

function placeMarker(location, name = null) {
    const stationName = name || prompt("Enter a name for this station:");
    if (!stationName) return;

    let marker = new google.maps.Marker({
        position: location,
        map: map,
        draggable: true,
        label: { text: stationName },
    });
    markers.push(marker);

    marker.addListener('rightclick', function() {
        marker.setMap(null);
        markers = markers.filter(m => m !== marker);
    });
}

function clearAll() {
    markers.forEach(marker => marker.setMap(null));
    markers = [];
    spazas.forEach(spaza => spaza.marker.setMap(null));
    spazas = [];
    zones.forEach(zone => zone.polygon.setMap(null));
    zones = [];
    taxiRoutes.forEach(route => route.polyline.setMap(null));
    taxiRoutes = [];
    secondaryTaxiRoutes.forEach(route => route.polyline.setMap(null));
    secondaryTaxiRoutes = [];
    if (searchMarker) searchMarker.setMap(null);
    if (heatmap) heatmap.setMap(null);
    $('#results').html('');
    showNotification("All data cleared.", "info");
}

function showNotification(message, type) {
    frappe.show_alert({
        message: message,
        indicator: type === 'error' ? 'red' : (type === 'success' ? 'green' : 'orange')
    });
}

// --- Frappe Integration Functions (to be implemented) ---

function loadCompetitors() {
    frappe.call({
        method: "frappe.client.get_list",
        args: {
            doctype: "Competitor",
            fields: ["name", "competitor_name"],
            limit_page_length: 1000
        },
        callback: function(r) {
            if (r.message) {
                const select = $('#competitor-select');
                select.empty().append('<option value="">Select a Competitor</option>');
                r.message.forEach(comp => {
                    select.append(`<option value="${comp.name}">${comp.competitor_name}</option>`);
                });
            }
        }
    });
}

function loadCompetitorData(competitor) {
    clearAll();
    if (!competitor) return;

    frappe.call({
        method: "rokct.rokct.doctype.competitor.competitor.get_competitor_map_data",
        args: { competitor: competitor },
        callback: function(r) {
            if (r.message && r.message.status === "success") {
                const data = r.message.data;

                // Load locations (stations and spazas)
                data.locations.forEach(loc => {
                    const geo = JSON.parse(loc.location_geolocation);
                    const position = new google.maps.LatLng(geo.coordinates[1], geo.coordinates[0]);
                    if (loc.location_type === 'Station') {
                        placeMarker(position, loc.location_name);
                    } else if (loc.location_type === 'Spaza') {
                        addSpaza(position, loc.location_name);
                    }
                });

                // Load zones
                data.zones.forEach(zone_data => {
                    const path = JSON.parse(zone_data.zone_path).map(p => new google.maps.LatLng(p.lat, p.lng));
                    const polygon = new google.maps.Polygon({
                        paths: path,
                        map: map,
                        editable: true
                    });
                    addZone(polygon, zone_data.zone_name);
                });

                // Load routes
                data.routes.forEach(route_data => {
                    const path = JSON.parse(route_data.route_path).map(p => new google.maps.LatLng(p.lat, p.lng));
                    const polyline = new google.maps.Polyline({
                        path: path,
                        map: map,
                        editable: true
                    });
                    if (route_data.route_type === 'Primary') {
                        addTaxiRoute(polyline, route_data.route_name);
                    } else {
                        addSecondaryTaxiRoute(polyline, route_data.route_name);
                    }
                });

                showNotification("Competitor data loaded.", "success");
            } else {
                showNotification("Error loading competitor data.", "error");
            }
        }
    });
}

function saveCompetitorData() {
    if (!selectedCompetitor) {
        showNotification("Please select a competitor first.", "warning");
        return;
    }

    const data = {
        locations: [
            ...markers.map(m => ({ type: 'Station', name: m.getLabel().text, lat: m.getPosition().lat(), lng: m.getPosition().lng() })),
            ...spazas.map(s => ({ type: 'Spaza', name: s.name, lat: s.marker.getPosition().lat(), lng: s.marker.getPosition().lng() }))
        ],
        zones: zones.map(z => ({
            name: z.name,
            path: z.polygon.getPath().getArray().map(p => ({lat: p.lat(), lng: p.lng()}))
        })),
        routes: [...taxiRoutes, ...secondaryTaxiRoutes].map(r => ({
            name: r.name,
            type: r.type,
            path: r.polyline.getPath().getArray().map(p => ({lat: p.lat(), lng: p.lng()}))
        }))
    };

    frappe.call({
        method: "rokct.rokct.doctype.competitor.competitor.save_competitor_map_data",
        args: {
            competitor: selectedCompetitor,
            data: JSON.stringify(data)
        },
        callback: function(r) {
            if (r.message && r.message.status === "success") {
                showNotification("Map data saved successfully.", "success");
            } else {
                showNotification("Error saving map data. " + (r.message ? r.message.message : ""), "error");
            }
        }
    });
}