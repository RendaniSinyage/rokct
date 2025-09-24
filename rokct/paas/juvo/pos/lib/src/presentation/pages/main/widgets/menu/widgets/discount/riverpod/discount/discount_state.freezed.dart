// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discount_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DiscountState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  List<DiscountData> get discounts => throw _privateConstructorUsedError;

  /// Create a copy of DiscountState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DiscountStateCopyWith<DiscountState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DiscountStateCopyWith<$Res> {
  factory $DiscountStateCopyWith(
          DiscountState value, $Res Function(DiscountState) then) =
      _$DiscountStateCopyWithImpl<$Res, DiscountState>;
  @useResult
  $Res call({bool isLoading, bool hasMore, List<DiscountData> discounts});
}

/// @nodoc
class _$DiscountStateCopyWithImpl<$Res, $Val extends DiscountState>
    implements $DiscountStateCopyWith<$Res> {
  _$DiscountStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DiscountState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? hasMore = null,
    Object? discounts = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      discounts: null == discounts
          ? _value.discounts
          : discounts // ignore: cast_nullable_to_non_nullable
              as List<DiscountData>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DiscountStateImplCopyWith<$Res>
    implements $DiscountStateCopyWith<$Res> {
  factory _$$DiscountStateImplCopyWith(
          _$DiscountStateImpl value, $Res Function(_$DiscountStateImpl) then) =
      __$$DiscountStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, bool hasMore, List<DiscountData> discounts});
}

/// @nodoc
class __$$DiscountStateImplCopyWithImpl<$Res>
    extends _$DiscountStateCopyWithImpl<$Res, _$DiscountStateImpl>
    implements _$$DiscountStateImplCopyWith<$Res> {
  __$$DiscountStateImplCopyWithImpl(
      _$DiscountStateImpl _value, $Res Function(_$DiscountStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DiscountState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? hasMore = null,
    Object? discounts = null,
  }) {
    return _then(_$DiscountStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      discounts: null == discounts
          ? _value._discounts
          : discounts // ignore: cast_nullable_to_non_nullable
              as List<DiscountData>,
    ));
  }
}

/// @nodoc

class _$DiscountStateImpl extends _DiscountState {
  const _$DiscountStateImpl(
      {this.isLoading = false,
      this.hasMore = true,
      final List<DiscountData> discounts = const []})
      : _discounts = discounts,
        super._();

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool hasMore;
  final List<DiscountData> _discounts;
  @override
  @JsonKey()
  List<DiscountData> get discounts {
    if (_discounts is EqualUnmodifiableListView) return _discounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_discounts);
  }

  @override
  String toString() {
    return 'DiscountState(isLoading: $isLoading, hasMore: $hasMore, discounts: $discounts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DiscountStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            const DeepCollectionEquality()
                .equals(other._discounts, _discounts));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading, hasMore,
      const DeepCollectionEquality().hash(_discounts));

  /// Create a copy of DiscountState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DiscountStateImplCopyWith<_$DiscountStateImpl> get copyWith =>
      __$$DiscountStateImplCopyWithImpl<_$DiscountStateImpl>(this, _$identity);
}

abstract class _DiscountState extends DiscountState {
  const factory _DiscountState(
      {final bool isLoading,
      final bool hasMore,
      final List<DiscountData> discounts}) = _$DiscountStateImpl;
  const _DiscountState._() : super._();

  @override
  bool get isLoading;
  @override
  bool get hasMore;
  @override
  List<DiscountData> get discounts;

  /// Create a copy of DiscountState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DiscountStateImplCopyWith<_$DiscountStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

