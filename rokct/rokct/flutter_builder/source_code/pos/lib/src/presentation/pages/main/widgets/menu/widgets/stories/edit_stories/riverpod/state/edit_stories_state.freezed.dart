// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_stories_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EditStoriesState {
  bool get isLoading => throw _privateConstructorUsedError;
  ProductData? get selectProduct => throw _privateConstructorUsedError;
  List<ProductData> get products => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  List<String> get listOfUrls => throw _privateConstructorUsedError;
  StoriesData? get story => throw _privateConstructorUsedError;
  TextEditingController? get textEditingController =>
      throw _privateConstructorUsedError;

  /// Create a copy of EditStoriesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditStoriesStateCopyWith<EditStoriesState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditStoriesStateCopyWith<$Res> {
  factory $EditStoriesStateCopyWith(
          EditStoriesState value, $Res Function(EditStoriesState) then) =
      _$EditStoriesStateCopyWithImpl<$Res, EditStoriesState>;
  @useResult
  $Res call(
      {bool isLoading,
      ProductData? selectProduct,
      List<ProductData> products,
      List<String> images,
      List<String> listOfUrls,
      StoriesData? story,
      TextEditingController? textEditingController});
}

/// @nodoc
class _$EditStoriesStateCopyWithImpl<$Res, $Val extends EditStoriesState>
    implements $EditStoriesStateCopyWith<$Res> {
  _$EditStoriesStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditStoriesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? selectProduct = freezed,
    Object? products = null,
    Object? images = null,
    Object? listOfUrls = null,
    Object? story = freezed,
    Object? textEditingController = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      selectProduct: freezed == selectProduct
          ? _value.selectProduct
          : selectProduct // ignore: cast_nullable_to_non_nullable
              as ProductData?,
      products: null == products
          ? _value.products
          : products // ignore: cast_nullable_to_non_nullable
              as List<ProductData>,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      listOfUrls: null == listOfUrls
          ? _value.listOfUrls
          : listOfUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      story: freezed == story
          ? _value.story
          : story // ignore: cast_nullable_to_non_nullable
              as StoriesData?,
      textEditingController: freezed == textEditingController
          ? _value.textEditingController
          : textEditingController // ignore: cast_nullable_to_non_nullable
              as TextEditingController?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EditStoriesStateImplCopyWith<$Res>
    implements $EditStoriesStateCopyWith<$Res> {
  factory _$$EditStoriesStateImplCopyWith(_$EditStoriesStateImpl value,
          $Res Function(_$EditStoriesStateImpl) then) =
      __$$EditStoriesStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      ProductData? selectProduct,
      List<ProductData> products,
      List<String> images,
      List<String> listOfUrls,
      StoriesData? story,
      TextEditingController? textEditingController});
}

/// @nodoc
class __$$EditStoriesStateImplCopyWithImpl<$Res>
    extends _$EditStoriesStateCopyWithImpl<$Res, _$EditStoriesStateImpl>
    implements _$$EditStoriesStateImplCopyWith<$Res> {
  __$$EditStoriesStateImplCopyWithImpl(_$EditStoriesStateImpl _value,
      $Res Function(_$EditStoriesStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditStoriesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? selectProduct = freezed,
    Object? products = null,
    Object? images = null,
    Object? listOfUrls = null,
    Object? story = freezed,
    Object? textEditingController = freezed,
  }) {
    return _then(_$EditStoriesStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      selectProduct: freezed == selectProduct
          ? _value.selectProduct
          : selectProduct // ignore: cast_nullable_to_non_nullable
              as ProductData?,
      products: null == products
          ? _value._products
          : products // ignore: cast_nullable_to_non_nullable
              as List<ProductData>,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      listOfUrls: null == listOfUrls
          ? _value._listOfUrls
          : listOfUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      story: freezed == story
          ? _value.story
          : story // ignore: cast_nullable_to_non_nullable
              as StoriesData?,
      textEditingController: freezed == textEditingController
          ? _value.textEditingController
          : textEditingController // ignore: cast_nullable_to_non_nullable
              as TextEditingController?,
    ));
  }
}

/// @nodoc

class _$EditStoriesStateImpl extends _EditStoriesState {
  const _$EditStoriesStateImpl(
      {this.isLoading = false,
      this.selectProduct = null,
      final List<ProductData> products = const [],
      final List<String> images = const [],
      final List<String> listOfUrls = const [],
      this.story = null,
      this.textEditingController = null})
      : _products = products,
        _images = images,
        _listOfUrls = listOfUrls,
        super._();

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final ProductData? selectProduct;
  final List<ProductData> _products;
  @override
  @JsonKey()
  List<ProductData> get products {
    if (_products is EqualUnmodifiableListView) return _products;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_products);
  }

  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  final List<String> _listOfUrls;
  @override
  @JsonKey()
  List<String> get listOfUrls {
    if (_listOfUrls is EqualUnmodifiableListView) return _listOfUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_listOfUrls);
  }

  @override
  @JsonKey()
  final StoriesData? story;
  @override
  @JsonKey()
  final TextEditingController? textEditingController;

  @override
  String toString() {
    return 'EditStoriesState(isLoading: $isLoading, selectProduct: $selectProduct, products: $products, images: $images, listOfUrls: $listOfUrls, story: $story, textEditingController: $textEditingController)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditStoriesStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.selectProduct, selectProduct) ||
                other.selectProduct == selectProduct) &&
            const DeepCollectionEquality().equals(other._products, _products) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality()
                .equals(other._listOfUrls, _listOfUrls) &&
            (identical(other.story, story) || other.story == story) &&
            (identical(other.textEditingController, textEditingController) ||
                other.textEditingController == textEditingController));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      selectProduct,
      const DeepCollectionEquality().hash(_products),
      const DeepCollectionEquality().hash(_images),
      const DeepCollectionEquality().hash(_listOfUrls),
      story,
      textEditingController);

  /// Create a copy of EditStoriesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditStoriesStateImplCopyWith<_$EditStoriesStateImpl> get copyWith =>
      __$$EditStoriesStateImplCopyWithImpl<_$EditStoriesStateImpl>(
          this, _$identity);
}

abstract class _EditStoriesState extends EditStoriesState {
  const factory _EditStoriesState(
          {final bool isLoading,
          final ProductData? selectProduct,
          final List<ProductData> products,
          final List<String> images,
          final List<String> listOfUrls,
          final StoriesData? story,
          final TextEditingController? textEditingController}) =
      _$EditStoriesStateImpl;
  const _EditStoriesState._() : super._();

  @override
  bool get isLoading;
  @override
  ProductData? get selectProduct;
  @override
  List<ProductData> get products;
  @override
  List<String> get images;
  @override
  List<String> get listOfUrls;
  @override
  StoriesData? get story;
  @override
  TextEditingController? get textEditingController;

  /// Create a copy of EditStoriesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditStoriesStateImplCopyWith<_$EditStoriesStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

