// --- Global Variables ---
let map, drawingManager, geocoder, searchMarker;
let competitorLocations = []; // Only holds competitor-specific markers
let masterZones = [];
let masterRoutes = [];
let selectedCompetitor = null;
let addingLocation = false;

const PRIMARY_ROUTE_COLOR = '#FF0000';
const SECONDARY_ROUTE_COLOR = '#FFA500';
const zoneColors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF', '#FFA500', '#800080', '#008000', '#FFC0CB', '#800000', '#008080'];

// --- Initialization ---

function initMap() {
    map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: -22.34058, lng: 30.01341},
        zoom: 10,
        styles: [{ featureType: "poi", elementType: "labels", stylers: [{ visibility: "off" }] }]
    });

    geocoder = new google.maps.Geocoder();
    drawingManager = new google.maps.drawing.DrawingManager({
        drawingMode: null,
        drawingControl: false,
        polygonOptions: { editable: false, clickable: false },
        polylineOptions: { editable: false, clickable: false }
    });
    drawingManager.setMap(map);

    map.addListener('click', function(e) {
        if (addingLocation) {
            addLocation(e.latLng);
            toggleAddingLocation(); // Turn off after adding one location
        }
    });

    setupUI();
    loadCompetitors();
    loadMasterData(); // Load zones and routes on page load
}

function setupUI() {
    $('#search-button').on('click', searchLocation);
    $('#add-location-btn').on('click', () => toggleAddingLocation());
    $('#save-data-btn').on('click', saveCompetitorLocations);
    $('#clear-all-btn').on('click', clearCompetitorLocations); // Now only clears competitor locations

    $('#competitor-select').on('change', function() {
        selectedCompetitor = $(this).val();
        loadLocationTypesForCompetitor(selectedCompetitor);
        loadCompetitorLocations(selectedCompetitor);
    });
}

// --- UI Logic ---

function toggleAddingLocation() {
    addingLocation = !addingLocation;
    $('#add-location-btn').toggleClass('btn-primary', addingLocation).toggleClass('btn-default', !addingLocation);
}

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
            showNotification("Couldn't find the location.", "error");
        }
    });
}

// --- Data Display ---

function addLocation(position, name = null, type = null) {
    const locationType = type || $('#location-type-select').val();
    const locationTypeName = type ? $('#location-type-select option[value="' + type + '"]').text() : $('#location-type-select option:selected').text();

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

    marker.location_type = locationType;
    competitorLocations.push(marker);

    marker.addListener('rightclick', function() {
        marker.setMap(null);
        competitorLocations = competitorLocations.filter(m => m !== marker);
    });
}

function drawZone(zone_data) {
    const path = JSON.parse(zone_data.zone_path).map(p => new google.maps.LatLng(p.lat, p.lng));
    const polygon = new google.maps.Polygon({
        paths: path,
        map: map,
        editable: false,
        clickable: false,
        fillColor: zoneColors[masterZones.length % zoneColors.length],
        strokeColor: zoneColors[masterZones.length % zoneColors.length],
        fillOpacity: 0.2
    });
    masterZones.push(polygon);
}

function drawRoute(route_data) {
    const path = JSON.parse(route_data.route_path).map(p => new google.maps.LatLng(p.lat, p.lng));
    const polyline = new google.maps.Polyline({
        path: path,
        map: map,
        editable: false,
        clickable: false,
        strokeColor: route_data.route_type === 'Primary' ? PRIMARY_ROUTE_COLOR : SECONDARY_ROUTE_COLOR,
        strokeOpacity: 0.7
    });
    masterRoutes.push(polyline);
}

function clearCompetitorLocations() {
    competitorLocations.forEach(marker => marker.setMap(null));
    competitorLocations = [];
}

// --- Frappe Integration ---

function loadCompetitors() {
    frappe.call({
        method: "frappe.client.get_list",
        args: { doctype: "Competitor", fields: ["name", "competitor_name"], limit_page_length: 1000 },
        callback: (r) => {
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

function loadMasterData() {
    frappe.call({
        method: "rokct.rokct.doctype.competitor.competitor.get_map_data",
        callback: (r) => {
            if (r.message && r.message.status === "success") {
                r.message.data.zones.forEach(drawZone);
                r.message.data.routes.forEach(drawRoute);
            }
        }
    });
}

function loadLocationTypesForCompetitor(competitor) {
    const $select = $('#location-type-select');
    const $button = $('#add-location-btn');
    $select.empty().attr('disabled', true);
    $button.attr('disabled', true);

    if (!competitor) return;

    frappe.client.get('Competitor', competitor).then(doc => {
        if (doc && doc.industry) {
            frappe.client.get_list('Location Type', {
                filters: { 'industry': doc.industry },
                fields: ['name', 'location_type_name'],
                limit_page_length: 100
            }).then(types => {
                if (types && types.length > 0) {
                    types.forEach(type => {
                        $select.append(`<option value="${type.name}">${type.location_type_name}</option>`);
                    });
                    $select.attr('disabled', false);
                    $button.attr('disabled', false);
                } else {
                    $select.append('<option value="">No location types for this industry</option>');
                }
            });
        }
    });
}

function loadCompetitorLocations(competitor) {
    clearCompetitorLocations();
    if (!competitor) return;

    frappe.call({
        method: "rokct.rokct.doctype.competitor.competitor.get_map_data",
        args: { competitor: competitor },
        callback: (r) => {
            if (r.message && r.message.status === "success") {
                r.message.data.locations.forEach(loc => {
                    const geo = JSON.parse(loc.location_geolocation);
                    const position = new google.maps.LatLng(geo.coordinates[1], geo.coordinates[0]);
                    addLocation(position, loc.location_name, loc.location_type);
                });
            }
        }
    });
}

function saveCompetitorLocations() {
    if (!selectedCompetitor) {
        showNotification("Please select a competitor first.", "warning");
        return;
    }

    const locations_data = competitorLocations.map(m => ({
        type: m.location_type,
        name: m.getLabel().text,
        lat: m.getPosition().lat(),
        lng: m.getPosition().lng()
    }));

    frappe.call({
        method: "rokct.rokct.doctype.competitor.competitor.save_competitor_locations",
        args: {
            competitor: selectedCompetitor,
            locations_data: JSON.stringify(locations_data)
        },
        callback: (r) => {
            if (r.message && r.message.status === "success") {
                showNotification("Competitor locations saved successfully.", "success");
            } else {
                showNotification("Error saving locations. " + (r.message ? r.message.message : ""), "error");
            }
        }
    });
}

function showNotification(message, type) {
    frappe.show_alert({
        message: message,
        indicator: type === 'error' ? 'red' : (type === 'success' ? 'green' : 'orange')
    });
}