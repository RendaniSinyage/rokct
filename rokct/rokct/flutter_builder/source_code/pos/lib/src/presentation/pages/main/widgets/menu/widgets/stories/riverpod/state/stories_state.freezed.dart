// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stories_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$StoriesState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<StoriesData> get stories => throw _privateConstructorUsedError;

  /// Create a copy of StoriesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoriesStateCopyWith<StoriesState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoriesStateCopyWith<$Res> {
  factory $StoriesStateCopyWith(
          StoriesState value, $Res Function(StoriesState) then) =
      _$StoriesStateCopyWithImpl<$Res, StoriesState>;
  @useResult
  $Res call({bool isLoading, List<StoriesData> stories});
}

/// @nodoc
class _$StoriesStateCopyWithImpl<$Res, $Val extends StoriesState>
    implements $StoriesStateCopyWith<$Res> {
  _$StoriesStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoriesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? stories = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      stories: null == stories
          ? _value.stories
          : stories // ignore: cast_nullable_to_non_nullable
              as List<StoriesData>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoriesStateImplCopyWith<$Res>
    implements $StoriesStateCopyWith<$Res> {
  factory _$$StoriesStateImplCopyWith(
          _$StoriesStateImpl value, $Res Function(_$StoriesStateImpl) then) =
      __$$StoriesStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, List<StoriesData> stories});
}

/// @nodoc
class __$$StoriesStateImplCopyWithImpl<$Res>
    extends _$StoriesStateCopyWithImpl<$Res, _$StoriesStateImpl>
    implements _$$StoriesStateImplCopyWith<$Res> {
  __$$StoriesStateImplCopyWithImpl(
      _$StoriesStateImpl _value, $Res Function(_$StoriesStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoriesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? stories = null,
  }) {
    return _then(_$StoriesStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      stories: null == stories
          ? _value._stories
          : stories // ignore: cast_nullable_to_non_nullable
              as List<StoriesData>,
    ));
  }
}

/// @nodoc

class _$StoriesStateImpl extends _StoriesState {
  const _$StoriesStateImpl(
      {this.isLoading = false, final List<StoriesData> stories = const []})
      : _stories = stories,
        super._();

  @override
  @JsonKey()
  final bool isLoading;
  final List<StoriesData> _stories;
  @override
  @JsonKey()
  List<StoriesData> get stories {
    if (_stories is EqualUnmodifiableListView) return _stories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stories);
  }

  @override
  String toString() {
    return 'StoriesState(isLoading: $isLoading, stories: $stories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoriesStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(other._stories, _stories));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isLoading, const DeepCollectionEquality().hash(_stories));

  /// Create a copy of StoriesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoriesStateImplCopyWith<_$StoriesStateImpl> get copyWith =>
      __$$StoriesStateImplCopyWithImpl<_$StoriesStateImpl>(this, _$identity);
}

abstract class _StoriesState extends StoriesState {
  const factory _StoriesState(
      {final bool isLoading,
      final List<StoriesData> stories}) = _$StoriesStateImpl;
  const _StoriesState._() : super._();

  @override
  bool get isLoading;
  @override
  List<StoriesData> get stories;

  /// Create a copy of StoriesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoriesStateImplCopyWith<_$StoriesStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

