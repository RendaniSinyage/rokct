// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deliveryman_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DeliverymanState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isUpdate => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  List<UserData> get users => throw _privateConstructorUsedError;
  int get statusIndex => throw _privateConstructorUsedError;

  /// Create a copy of DeliverymanState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeliverymanStateCopyWith<DeliverymanState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliverymanStateCopyWith<$Res> {
  factory $DeliverymanStateCopyWith(
          DeliverymanState value, $Res Function(DeliverymanState) then) =
      _$DeliverymanStateCopyWithImpl<$Res, DeliverymanState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isUpdate,
      bool hasMore,
      List<UserData> users,
      int statusIndex});
}

/// @nodoc
class _$DeliverymanStateCopyWithImpl<$Res, $Val extends DeliverymanState>
    implements $DeliverymanStateCopyWith<$Res> {
  _$DeliverymanStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeliverymanState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isUpdate = null,
    Object? hasMore = null,
    Object? users = null,
    Object? statusIndex = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isUpdate: null == isUpdate
          ? _value.isUpdate
          : isUpdate // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      users: null == users
          ? _value.users
          : users // ignore: cast_nullable_to_non_nullable
              as List<UserData>,
      statusIndex: null == statusIndex
          ? _value.statusIndex
          : statusIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeliverymanStateImplCopyWith<$Res>
    implements $DeliverymanStateCopyWith<$Res> {
  factory _$$DeliverymanStateImplCopyWith(_$DeliverymanStateImpl value,
          $Res Function(_$DeliverymanStateImpl) then) =
      __$$DeliverymanStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isUpdate,
      bool hasMore,
      List<UserData> users,
      int statusIndex});
}

/// @nodoc
class __$$DeliverymanStateImplCopyWithImpl<$Res>
    extends _$DeliverymanStateCopyWithImpl<$Res, _$DeliverymanStateImpl>
    implements _$$DeliverymanStateImplCopyWith<$Res> {
  __$$DeliverymanStateImplCopyWithImpl(_$DeliverymanStateImpl _value,
      $Res Function(_$DeliverymanStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeliverymanState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isUpdate = null,
    Object? hasMore = null,
    Object? users = null,
    Object? statusIndex = null,
  }) {
    return _then(_$DeliverymanStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isUpdate: null == isUpdate
          ? _value.isUpdate
          : isUpdate // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      users: null == users
          ? _value._users
          : users // ignore: cast_nullable_to_non_nullable
              as List<UserData>,
      statusIndex: null == statusIndex
          ? _value.statusIndex
          : statusIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$DeliverymanStateImpl extends _DeliverymanState {
  const _$DeliverymanStateImpl(
      {this.isLoading = false,
      this.isUpdate = false,
      this.hasMore = true,
      final List<UserData> users = const [],
      this.statusIndex = -1})
      : _users = users,
        super._();

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isUpdate;
  @override
  @JsonKey()
  final bool hasMore;
  final List<UserData> _users;
  @override
  @JsonKey()
  List<UserData> get users {
    if (_users is EqualUnmodifiableListView) return _users;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_users);
  }

  @override
  @JsonKey()
  final int statusIndex;

  @override
  String toString() {
    return 'DeliverymanState(isLoading: $isLoading, isUpdate: $isUpdate, hasMore: $hasMore, users: $users, statusIndex: $statusIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliverymanStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isUpdate, isUpdate) ||
                other.isUpdate == isUpdate) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            const DeepCollectionEquality().equals(other._users, _users) &&
            (identical(other.statusIndex, statusIndex) ||
                other.statusIndex == statusIndex));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading, isUpdate, hasMore,
      const DeepCollectionEquality().hash(_users), statusIndex);

  /// Create a copy of DeliverymanState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliverymanStateImplCopyWith<_$DeliverymanStateImpl> get copyWith =>
      __$$DeliverymanStateImplCopyWithImpl<_$DeliverymanStateImpl>(
          this, _$identity);
}

abstract class _DeliverymanState extends DeliverymanState {
  const factory _DeliverymanState(
      {final bool isLoading,
      final bool isUpdate,
      final bool hasMore,
      final List<UserData> users,
      final int statusIndex}) = _$DeliverymanStateImpl;
  const _DeliverymanState._() : super._();

  @override
  bool get isLoading;
  @override
  bool get isUpdate;
  @override
  bool get hasMore;
  @override
  List<UserData> get users;
  @override
  int get statusIndex;

  /// Create a copy of DeliverymanState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliverymanStateImplCopyWith<_$DeliverymanStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

