// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_zone_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DeliveryZoneState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isSaving => throw _privateConstructorUsedError;
  List<List<double>> get deliveryZones => throw _privateConstructorUsedError;
  List<LatLng> get tappedPoints => throw _privateConstructorUsedError;
  Set<Polygon> get polygon => throw _privateConstructorUsedError;

  /// Create a copy of DeliveryZoneState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeliveryZoneStateCopyWith<DeliveryZoneState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryZoneStateCopyWith<$Res> {
  factory $DeliveryZoneStateCopyWith(
          DeliveryZoneState value, $Res Function(DeliveryZoneState) then) =
      _$DeliveryZoneStateCopyWithImpl<$Res, DeliveryZoneState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isSaving,
      List<List<double>> deliveryZones,
      List<LatLng> tappedPoints,
      Set<Polygon> polygon});
}

/// @nodoc
class _$DeliveryZoneStateCopyWithImpl<$Res, $Val extends DeliveryZoneState>
    implements $DeliveryZoneStateCopyWith<$Res> {
  _$DeliveryZoneStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeliveryZoneState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isSaving = null,
    Object? deliveryZones = null,
    Object? tappedPoints = null,
    Object? polygon = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryZones: null == deliveryZones
          ? _value.deliveryZones
          : deliveryZones // ignore: cast_nullable_to_non_nullable
              as List<List<double>>,
      tappedPoints: null == tappedPoints
          ? _value.tappedPoints
          : tappedPoints // ignore: cast_nullable_to_non_nullable
              as List<LatLng>,
      polygon: null == polygon
          ? _value.polygon
          : polygon // ignore: cast_nullable_to_non_nullable
              as Set<Polygon>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeliveryZoneStateImplCopyWith<$Res>
    implements $DeliveryZoneStateCopyWith<$Res> {
  factory _$$DeliveryZoneStateImplCopyWith(_$DeliveryZoneStateImpl value,
          $Res Function(_$DeliveryZoneStateImpl) then) =
      __$$DeliveryZoneStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isSaving,
      List<List<double>> deliveryZones,
      List<LatLng> tappedPoints,
      Set<Polygon> polygon});
}

/// @nodoc
class __$$DeliveryZoneStateImplCopyWithImpl<$Res>
    extends _$DeliveryZoneStateCopyWithImpl<$Res, _$DeliveryZoneStateImpl>
    implements _$$DeliveryZoneStateImplCopyWith<$Res> {
  __$$DeliveryZoneStateImplCopyWithImpl(_$DeliveryZoneStateImpl _value,
      $Res Function(_$DeliveryZoneStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeliveryZoneState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isSaving = null,
    Object? deliveryZones = null,
    Object? tappedPoints = null,
    Object? polygon = null,
  }) {
    return _then(_$DeliveryZoneStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryZones: null == deliveryZones
          ? _value._deliveryZones
          : deliveryZones // ignore: cast_nullable_to_non_nullable
              as List<List<double>>,
      tappedPoints: null == tappedPoints
          ? _value._tappedPoints
          : tappedPoints // ignore: cast_nullable_to_non_nullable
              as List<LatLng>,
      polygon: null == polygon
          ? _value._polygon
          : polygon // ignore: cast_nullable_to_non_nullable
              as Set<Polygon>,
    ));
  }
}

/// @nodoc

class _$DeliveryZoneStateImpl extends _DeliveryZoneState {
  const _$DeliveryZoneStateImpl(
      {this.isLoading = false,
      this.isSaving = false,
      final List<List<double>> deliveryZones = const [],
      final List<LatLng> tappedPoints = const [],
      final Set<Polygon> polygon = const {}})
      : _deliveryZones = deliveryZones,
        _tappedPoints = tappedPoints,
        _polygon = polygon,
        super._();

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isSaving;
  final List<List<double>> _deliveryZones;
  @override
  @JsonKey()
  List<List<double>> get deliveryZones {
    if (_deliveryZones is EqualUnmodifiableListView) return _deliveryZones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deliveryZones);
  }

  final List<LatLng> _tappedPoints;
  @override
  @JsonKey()
  List<LatLng> get tappedPoints {
    if (_tappedPoints is EqualUnmodifiableListView) return _tappedPoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tappedPoints);
  }

  final Set<Polygon> _polygon;
  @override
  @JsonKey()
  Set<Polygon> get polygon {
    if (_polygon is EqualUnmodifiableSetView) return _polygon;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_polygon);
  }

  @override
  String toString() {
    return 'DeliveryZoneState(isLoading: $isLoading, isSaving: $isSaving, deliveryZones: $deliveryZones, tappedPoints: $tappedPoints, polygon: $polygon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryZoneStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            const DeepCollectionEquality()
                .equals(other._deliveryZones, _deliveryZones) &&
            const DeepCollectionEquality()
                .equals(other._tappedPoints, _tappedPoints) &&
            const DeepCollectionEquality().equals(other._polygon, _polygon));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      isSaving,
      const DeepCollectionEquality().hash(_deliveryZones),
      const DeepCollectionEquality().hash(_tappedPoints),
      const DeepCollectionEquality().hash(_polygon));

  /// Create a copy of DeliveryZoneState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryZoneStateImplCopyWith<_$DeliveryZoneStateImpl> get copyWith =>
      __$$DeliveryZoneStateImplCopyWithImpl<_$DeliveryZoneStateImpl>(
          this, _$identity);
}

abstract class _DeliveryZoneState extends DeliveryZoneState {
  const factory _DeliveryZoneState(
      {final bool isLoading,
      final bool isSaving,
      final List<List<double>> deliveryZones,
      final List<LatLng> tappedPoints,
      final Set<Polygon> polygon}) = _$DeliveryZoneStateImpl;
  const _DeliveryZoneState._() : super._();

  @override
  bool get isLoading;
  @override
  bool get isSaving;
  @override
  List<List<double>> get deliveryZones;
  @override
  List<LatLng> get tappedPoints;
  @override
  Set<Polygon> get polygon;

  /// Create a copy of DeliveryZoneState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryZoneStateImplCopyWith<_$DeliveryZoneStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

