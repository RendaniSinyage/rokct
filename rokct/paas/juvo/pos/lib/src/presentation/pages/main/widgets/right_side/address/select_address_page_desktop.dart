import 'dart:async';
import 'dart:convert';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/models/data/address_data.dart';
import 'package:admin_desktop/src/models/data/location_data.dart';
import 'package:admin_desktop/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:admin_desktop/src/presentation/components/login_button.dart';
import 'package:admin_desktop/src/presentation/components/buttons/pop_button.dart';
import 'package:admin_desktop/src/presentation/components/keyboard_disable.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:webview_windows/webview_windows.dart';
import '../../../../../../core/constants/constants.dart';
import '../../../../../theme/app_style.dart';
import '../../profile/edit_profile/riverpod/provider/edit_profile_provider.dart';
import 'riverpod/select_address_provider.dart';

class SelectAddressDesktopPage extends ConsumerStatefulWidget {
  final ValueChanged<AddressData> onSelect;
  final LocationData? location;
  final bool isShopEdit;

  const SelectAddressDesktopPage({
    super.key,
    required this.onSelect,
    this.location,
    this.isShopEdit = false,
  });

  @override
  ConsumerState<SelectAddressDesktopPage> createState() =>
      _SelectAddressDesktopPageState();
}

class _SelectAddressDesktopPageState
    extends ConsumerState<SelectAddressDesktopPage> {
  final _controller = WebviewController();
  bool _isWebViewReady = false;
  bool _areControlsVisible = false;
  String _errorMessage = '';
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _loadMap();

      setState(() {
        _isWebViewReady = true;
      });

      _controlsTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _areControlsVisible = true;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing map: $e';
        });
      }
    }
  }

  Future<void> _loadMap() async {
    final lat = widget.location?.latitude ?? AppConstants.demoLatitude;
    final lng = widget.location?.longitude ?? AppConstants.demoLongitude;
    final html = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
          <meta charset="utf-8">
          <style>
            #map { height: 100%; width: 100%; }
            html, body { height: 100%; margin: 0; padding: 0; }
          </style>
          <script src="https://maps.googleapis.com/maps/api/js?key=${AppConstants.googleApiKey}&libraries=places"></script>
          <script>
            var map, marker, geocoder;
            
            function initMap() {
              geocoder = new google.maps.Geocoder();
              map = new google.maps.Map(document.getElementById('map'), {
                center: {lat: $lat, lng: $lng},
                zoom: 18,
                zoomControl: true,
                mapTypeControl: false,
                scaleControl: true,
                streetViewControl: true,
                rotateControl: false,
                fullscreenControl: false
              });
              
              marker = new google.maps.Marker({
                position: {lat: $lat, lng: $lng},
                map: map,
                draggable: true
              });

              marker.addListener('dragend', function(e) {
                var position = marker.getPosition();
                updateLocationDetails(position);
              });
              
              map.addListener('click', function(e) {
                marker.setPosition(e.latLng);
                updateLocationDetails(e.latLng);
              });

              updateLocationDetails(marker.getPosition());
            }

            function updateLocationDetails(latLng) {
  geocoder.geocode({
    location: latLng,
    language: 'en'
  }, function(results, status) {
    if (status === 'OK' && results[0]) {
      const components = results[0].address_components;
      const getComponent = (types) => {
        const match = components.find(component => 
          types.some(type => component.types.includes(type))
        );
        return match ? { short: match.short_name, long: match.long_name } : null;
      };

      // Get detailed address components
      const streetNumber = getComponent(['street_number']);
      const route = getComponent(['route']);
      const subpremise = getComponent(['subpremise']); // For apartment/unit numbers
      const premise = getComponent(['premise']); // For building names
      const neighborhood = getComponent(['neighborhood', 'sublocality_level_1']);
      const locality = getComponent(['locality', 'postal_town']);
      const area = getComponent(['administrative_area_level_1']);
      const country = getComponent(['country']);
      const postalCode = getComponent(['postal_code']);

      // Build precise address
      const addressParts = [];
      
      // Add building/apartment details if available
      if (subpremise) addressParts.push(subpremise.long);
      if (premise) addressParts.push(premise.long);
      
      // Add street address
      const streetAddress = [
        streetNumber?.long,
        route?.long
      ].filter(Boolean).join(' ');
      if (streetAddress) addressParts.push(streetAddress);

      // Add neighborhood/locality
      if (neighborhood?.long) addressParts.push(neighborhood.long);
      if (locality?.long) addressParts.push(locality.long);
      
      // Add area/region
      if (area?.long) addressParts.push(area.long);
      
      // Add country and postal code
      if (country?.long) addressParts.push(country.long);
      if (postalCode?.long) addressParts.push(postalCode.long);

      const formattedAddress = addressParts.join(', ');

      window.chrome.webview.postMessage(JSON.stringify({
        latitude: latLng.lat(),
        longitude: latLng.lng(),
        address: formattedAddress,
        street: streetAddress,
        title: streetAddress || formattedAddress,
        components: {
          streetNumber: streetNumber?.long,
          route: route?.long,
          subpremise: subpremise?.long,
          premise: premise?.long,
          neighborhood: neighborhood?.long,
          locality: locality?.long,
          area: area?.long,
          country: country?.long,
          postalCode: postalCode?.long
        }
      }));
    }
  });
}

            async function searchPlace(query) {
              const service = new google.maps.places.PlacesService(map);
              service.findPlaceFromQuery(
                {
                  query: query,
                  fields: ['geometry', 'formatted_address', 'name']
                },
                function(results, status) {
                  if (status === google.maps.places.PlacesServiceStatus.OK && results.length > 0) {
                    const place = results[0];
                    const latLng = place.geometry.location;
                    marker.setPosition(latLng);
                    map.setCenter(latLng);
                    updateLocationDetails(latLng);
                  }
                }
              );
            }
          </script>
        </head>
        <body onload="initMap()">
          <div id="map"></div>
        </body>
      </html>
    ''';

    await _controller.loadStringContent(html);

    _controller.webMessage.listen((event) {
      try {
        final data = jsonDecode(event);

        final location = LocationData(
          latitude: data['latitude'],
          longitude: data['longitude'],
        );

        final notifier = ref.read(selectAddressProvider.notifier);

        if (mounted) {
          notifier
              .fetchLocationName(LatLng(data['latitude'], data['longitude']));

          notifier.checkDriverZone(
            context: context,
            location: LatLng(data['latitude'], data['longitude']),
            isShopEdit: widget.isShopEdit,
          );
        }
      } catch (e) {
        debugPrint('Error processing web message: $e');
      }
    });
  }

  Future<void> _updateMapCenter(double lat, double lng) async {
    if (_isWebViewReady) {
      await _controller.executeScript('''
        const latLng = new google.maps.LatLng($lat, $lng);
        map.setCenter(latLng);
        marker.setPosition(latLng);
        updateLocationDetails(latLng);
      ''');
    }
  }

  Future<void> _searchPlace(String query) async {
    if (_isWebViewReady) {
      await _controller.executeScript('''
        searchPlace("$query");
      ''');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selectAddressProvider);
    final event = ref.read(selectAddressProvider.notifier);

    return KeyboardDisable(
      child: Scaffold(
        backgroundColor: AppStyle.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                if (_isWebViewReady)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppStyle.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Webview(_controller),
                      ),
                    ),
                  ),

                if (!_isWebViewReady)
                  Center(
                    child: CircularProgressIndicator(
                      color: AppStyle.brandGreen,
                    ),
                  ),

                if (_errorMessage.isNotEmpty)
                  Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: AppStyle.red,
                        fontSize: 16,
                      ),
                    ),
                  ),

                // Search Bar
                Positioned(
                  top: 54,
                  left: 31,
                  right: 31,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          color: AppStyle.mainBack,
                          offset: Offset(0, 2),
                          blurRadius: 2,
                          spreadRadius: 0,
                        ),
                      ],
                      color: AppStyle.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FlutterRemix.search_line,
                          size: 20,
                          color: AppStyle.black,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: state.textController,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: AppStyle.black,
                              letterSpacing: -0.5,
                            ),
                            onChanged: (value) {
                              event.setQuery(context);
                            },
                            cursorWidth: 1,
                            cursorColor: AppStyle.black,
                            decoration: InputDecoration.collapsed(
                              hintText: AppHelpers.getTranslation(
                                  TrKeys.searchLocation),
                              hintStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: AppStyle.iconButtonBack,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: event.clearSearchField,
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            FlutterRemix.close_line,
                            size: 20,
                            color: AppStyle.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Results
                if (state.isSearching)
                  Positioned(
                    top: 110,
                    left: 31,
                    right: 31,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: AppStyle.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppStyle.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.searchedPlaces.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final place = state.searchedPlaces[index];
                          return InkWell(
                            onTap: () async {
                              event.goToLocation(place: place);
                              _updateMapCenter(place.lat, place.lon);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.displayName,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppStyle.black,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (place.address?["postcode"] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Postcode: ${place.address!["postcode"]}",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: AppStyle.grey,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  const Divider(
                                      height: 1, color: AppStyle.border),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Bottom Controls
                if (_areControlsVisible)
                  Positioned(
                    bottom: 32,
                    left: 31,
                    right: 31,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PopButton(
                              heroTag: 'heroTagAddOrderButton',
                              onTap: widget.isShopEdit
                                  ? () {
                                      ref
                                          .read(editProfileProvider.notifier)
                                          .setShopEdit(1);
                                    }
                                  : null,
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                event.goToMyLocation();
                                if (state.location != null) {
                                  _updateMapCenter(
                                    state.location!.latitude!,
                                    state.location!.longitude!,
                                  );
                                }
                              },
                              child: AnimationButtonEffect(
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppStyle.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppStyle.black),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppStyle.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(FlutterRemix.navigation_fill),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 200,
                              child: LoginButton(
                                isActive: state.isActive,
                                isLoading: state.isLoading,
                                title: AppHelpers.getTranslation(
                                    TrKeys.confirmLocation),
                                onPressed: () {
                                  if (state.isActive) {
                                    context.maybePop();
                                    widget.onSelect(AddressData(
                                      address: state.textController?.text ?? "",
                                      location: state.location,
                                    ));
                                  } else {
                                    AppHelpers.showSnackBar(
                                      context,
                                      AppHelpers.getTranslation(
                                          TrKeys.noDriverZone),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

