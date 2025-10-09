// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$StockState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<Stocks> get stocks => throw _privateConstructorUsedError;

  /// Create a copy of StockState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockStateCopyWith<StockState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockStateCopyWith<$Res> {
  factory $StockStateCopyWith(
          StockState value, $Res Function(StockState) then) =
      _$StockStateCopyWithImpl<$Res, StockState>;
  @useResult
  $Res call({bool isLoading, List<Stocks> stocks});
}

/// @nodoc
class _$StockStateCopyWithImpl<$Res, $Val extends StockState>
    implements $StockStateCopyWith<$Res> {
  _$StockStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? stocks = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      stocks: null == stocks
          ? _value.stocks
          : stocks // ignore: cast_nullable_to_non_nullable
              as List<Stocks>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StockStateImplCopyWith<$Res>
    implements $StockStateCopyWith<$Res> {
  factory _$$StockStateImplCopyWith(
          _$StockStateImpl value, $Res Function(_$StockStateImpl) then) =
      __$$StockStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, List<Stocks> stocks});
}

/// @nodoc
class __$$StockStateImplCopyWithImpl<$Res>
    extends _$StockStateCopyWithImpl<$Res, _$StockStateImpl>
    implements _$$StockStateImplCopyWith<$Res> {
  __$$StockStateImplCopyWithImpl(
      _$StockStateImpl _value, $Res Function(_$StockStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of StockState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? stocks = null,
  }) {
    return _then(_$StockStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      stocks: null == stocks
          ? _value._stocks
          : stocks // ignore: cast_nullable_to_non_nullable
              as List<Stocks>,
    ));
  }
}

/// @nodoc

class _$StockStateImpl extends _StockState {
  const _$StockStateImpl(
      {this.isLoading = false, final List<Stocks> stocks = const []})
      : _stocks = stocks,
        super._();

  @override
  @JsonKey()
  final bool isLoading;
  final List<Stocks> _stocks;
  @override
  @JsonKey()
  List<Stocks> get stocks {
    if (_stocks is EqualUnmodifiableListView) return _stocks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stocks);
  }

  @override
  String toString() {
    return 'StockState(isLoading: $isLoading, stocks: $stocks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(other._stocks, _stocks));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isLoading, const DeepCollectionEquality().hash(_stocks));

  /// Create a copy of StockState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockStateImplCopyWith<_$StockStateImpl> get copyWith =>
      __$$StockStateImplCopyWithImpl<_$StockStateImpl>(this, _$identity);
}

abstract class _StockState extends StockState {
  const factory _StockState({final bool isLoading, final List<Stocks> stocks}) =
      _$StockStateImpl;
  const _StockState._() : super._();

  @override
  bool get isLoading;
  @override
  List<Stocks> get stocks;

  /// Create a copy of StockState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockStateImplCopyWith<_$StockStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

