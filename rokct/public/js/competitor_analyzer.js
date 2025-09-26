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

// --- UI Setup and Event Handlers ---

function setupUI() {
    // Search
    $('#search-button').on('click', searchLocation);

    // Controls - Updated for dynamic location types
    $('#add-location-btn').on('click', () => toggleAdding('location'));
    $('#add-zone-btn').on('click', () => toggleAdding('zone'));
    $('#add-taxi-route-btn').on('click', () => toggleAdding('taxiRoute'));
    $('#add-secondary-taxi-route-btn').on('click', () => toggleAdding('secondaryTaxiRoute'));

    // Data
    $('#save-data-btn').on('click', saveCompetitorData);
    $('#clear-all-btn').on('click', clearAll);

    // Competitor selection
    $('#competitor-select').on('change', function() {
        selectedCompetitor = $(this).val();
        loadLocationTypesForCompetitor(selectedCompetitor);
        if (selectedCompetitor) {
            loadCompetitorMapData(selectedCompetitor);
        } else {
            clearAll();
        }
    });
}

let addingLocation = false; // Simplified state

function toggleAdding(type) {
    // Store the current state before resetting
    const wasAdding = {
        location: addingLocation,
        zone: addingZone,
        taxiRoute: addingTaxiRoute,
        secondaryTaxiRoute: addingSecondaryTaxiRoute
    };

    // Reset all modes
    addingLocation = addingZone = addingTaxiRoute = addingSecondaryTaxiRoute = false;
    drawingManager.setDrawingMode(null);

    // Toggle the selected type on or off
    if (type === 'location' && !wasAdding.location) addingLocation = true;
    if (type === 'zone' && !wasAdding.zone) addingZone = true;
    if (type === 'taxiRoute' && !wasAdding.taxiRoute) addingTaxiRoute = true;
    if (type === 'secondaryTaxiRoute' && !wasAdding.secondaryTaxiRoute) addingSecondaryTaxiRoute = true;

    // Set drawing manager if a drawing mode is active
    if (addingZone) drawingManager.setDrawingMode(google.maps.drawing.OverlayType.POLYGON);
    else if (addingTaxiRoute) drawingManager.setDrawingMode(google.maps.drawing.OverlayType.POLYLINE);
    else if (addingSecondaryTaxiRoute) drawingManager.setDrawingMode(google.maps.drawing.OverlayType.POLYLINE);

    updateButtonStates();
}

function updateButtonStates() {
    $('#add-location-btn').toggleClass('btn-primary', addingLocation).toggleClass('btn-default', !addingLocation);
    $('#add-zone-btn').toggleClass('btn-primary', addingZone).toggleClass('btn-default', !addingZone);
    $('#add-taxi-route-btn').toggleClass('btn-primary', addingTaxiRoute).toggleClass('btn-default', !addingTaxiRoute);
    $('#add-secondary-taxi-route-btn').toggleClass('btn-primary', addingSecondaryTaxiRoute).toggleClass('btn-default', !addingSecondaryTaxiRoute);
}

// --- Map Element Creation ---

function searchLocation() {
    const address = $('#search-input').val();
    if (!address) return;

    geocoder.geocode({ 'address': address }, function(results, status) {
        if (status === 'OK') {
            map.setCenter(results[0].geometry.location);
            map.setZoom(12);
            if (searchMarker) searchMarker.setMap(null);
            searchMarker = new google.maps.Marker({ map: map, position: results[0].geometry.location });
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
    polygon.setOptions({ fillColor: getUniqueColor(), strokeColor: getUniqueColor() });
    zones.push({ polygon: polygon, name: zoneName });
}

function addTaxiRoute(polyline, name = null) {
    const routeName = name || prompt("Enter a name for this main taxi route:");
    if (!routeName) {
        polyline.setMap(null);
        return;
    }
    polyline.setOptions({ strokeColor: PRIMARY_ROUTE_COLOR });
    taxiRoutes.push({ polyline: polyline, name: routeName, type: 'Primary' });
}

function addSecondaryTaxiRoute(polyline, name = null) {
    const routeName = name || prompt("Enter a name for this secondary taxi route:");
    if (!routeName) {
        polyline.setMap(null);
        return;
    }
    polyline.setOptions({ strokeColor: SECONDARY_ROUTE_COLOR });
    secondaryTaxiRoutes.push({ polyline: polyline, name: routeName, type: 'Secondary' });
}

// This replaces placeMarker and addSpaza
function addLocation(position, name = null, type = null) {
    const locationType = type || $('#location-type-select').val();
    const locationTypeName = type ? type : $('#location-type-select option:selected').text();

    if (!locationType) {
        showNotification("Please select a location type first.", "warning");
        return;
    }
    const locationName = name || prompt(`Enter a name for this ${locationTypeName}:`);
    if (!locationName) return;

    let marker = new google.maps.Marker({
        position: position,
        map: map,
        draggable: true,
        label: { text: locationName },
    });

    marker.location_type = locationType; // Store the type's name (which is its ID)
    markers.push(marker);

    marker.addListener('rightclick', function() {
        marker.setMap(null);
        markers = markers.filter(m => m !== marker);
    });
}

// --- Data Handling ---

function clearAll() {
    markers.forEach(marker => marker.setMap(null));
    markers = [];
    zones.forEach(zone => zone.polygon.setMap(null));
    zones = [];
    taxiRoutes.forEach(route => route.polyline.setMap(null));
    taxiRoutes = [];
    secondaryTaxiRoutes.forEach(route => route.polyline.setMap(null));
    secondaryTaxiRoutes = [];
    if (searchMarker) searchMarker.setMap(null);
    if (heatmap) heatmap.setMap(null);
    $('#results').html('');
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