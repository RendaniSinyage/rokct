import 'dart:io';

import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/extension.dart';
import 'package:admin_desktop/src/core/utils/time_service.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/presentation/theme/app_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CustomDateTimeField extends StatefulWidget {
  final String? Function(String?)? validation;
  final void Function(DateTime)? onDateChange;
  final void Function(TimeOfDay)? onTimeChange;
  final CupertinoDatePickerMode mode;
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final int minuteInterval;
  final double iconSize;
  final EdgeInsetsGeometry? contentPadding;
  final bool readOnly;
  final String? label;

  const CustomDateTimeField({
    super.key,
    this.validation,
    this.onDateChange,
    this.onTimeChange,
    this.minDate,
    this.maxDate,
    this.mode = CupertinoDatePickerMode.time,
    this.minuteInterval = 1,
    this.iconSize = 18,
    this.contentPadding,
    this.readOnly = false,
    this.label,
    this.initialDate,
  });

  @override
  State<CustomDateTimeField> createState() => _CustomDateTimeFieldState();
}

class _CustomDateTimeFieldState extends State<CustomDateTimeField>
    with SingleTickerProviderStateMixin {
  RenderBox? _childBox;
  OverlayEntry? _overlayEntry;
  TimePickerSpinnerController? _controller;

  late AnimationController _animationController;
  late Tween<double> _colorTween;
  late Animation<double?> _animation;

  DateTime? _selectedDateTime;
  late DateTime _selectedDateTimeSpinner;
  IconData? iconAssets;
  String? time;
  late Function setStateValue;
  final FocusNode _focusNode = FocusNode();

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final datetime = _selectedDateTimeSpinner;
      final bool isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          switch (widget.mode) {
            case CupertinoDatePickerMode.time:
              _selectedDateTimeSpinner = datetime.add(const Duration(minutes: 1));
              break;
            case CupertinoDatePickerMode.date:
              _selectedDateTimeSpinner = datetime.add(const Duration(days: 1));
              break;
            case CupertinoDatePickerMode.dateAndTime:
              if (isShiftPressed) {
                _selectedDateTimeSpinner = datetime.add(const Duration(days: 1));
              } else {
                _selectedDateTimeSpinner = datetime.add(const Duration(minutes: 1));
              }
              break;
            default:
              break;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          switch (widget.mode) {
            case CupertinoDatePickerMode.time:
              _selectedDateTimeSpinner = datetime.subtract(const Duration(minutes: 1));
              break;
            case CupertinoDatePickerMode.date:
              _selectedDateTimeSpinner = datetime.subtract(const Duration(days: 1));
              break;
            case CupertinoDatePickerMode.dateAndTime:
              if (isShiftPressed) {
                _selectedDateTimeSpinner = datetime.subtract(const Duration(days: 1));
              } else {
                _selectedDateTimeSpinner = datetime.subtract(const Duration(minutes: 1));
              }
              break;
            default:
              break;
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDate;
    _selectedDateTimeSpinner = widget.initialDate ?? DateTime.now().add(const Duration(minutes: 1));
    _controller = TimePickerSpinnerController();
    _controller?.addListener(_updateView);
    setInitialTimes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _childBox = context.findRenderObject() as RenderBox?;
      }
    });

    _colorTween = Tween(begin: 0, end: 1);
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _animation = _colorTween.animate(_animationController);
  }

  @override
  void didUpdateWidget(covariant CustomDateTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedDateTime = widget.initialDate;
    _selectedDateTimeSpinner = widget.initialDate ?? DateTime.now().add(const Duration(minutes: 1));
  }

  setInitialTimes() {
    switch (widget.mode) {
      case CupertinoDatePickerMode.time:
        time = _selectedDateTime == null
            ? null
            : TimeService.timeFormat(_selectedDateTime);
        iconAssets = Icons.access_time;
        break;
      case CupertinoDatePickerMode.date:
        time = _selectedDateTime == null
            ? null
            : TimeService.dateFormatDM(_selectedDateTime!);
        iconAssets = Icons.calendar_month;
        break;
      case CupertinoDatePickerMode.dateAndTime:
        time = _selectedDateTime == null
            ? null
            : DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime!);
        iconAssets = Icons.calendar_month;
        break;
      case CupertinoDatePickerMode.monthYear:
        break;
    }
  }

  @override
  void dispose() {
    _hideMenu();
    _controller?.removeListener(_updateView);
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField(
        validator: widget.validation,
        initialValue: time,
        builder: (FormFieldState<String> state) {
          var child = _timeWidget(state);
          setStateValue = () => state.didChange(time);
          if (Platform.isIOS) {
            return child;
          } else {
            return PopScope(
              onPopInvoked: (s) => _hideMenu(),
              canPop: true,
              child: child,
            );
          }
        });
  }

  Widget _buildWindowsPicker() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward, color: AppStyle.white),
              onPressed: () {
                setState(() {
                  _selectedDateTimeSpinner = _selectedDateTimeSpinner.add(
                      widget.mode == CupertinoDatePickerMode.date ?
                      const Duration(days: 1) :
                      const Duration(minutes: 1)
                  );
                });
              },
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            widget.mode == CupertinoDatePickerMode.date ?
            DateFormat('MMM dd, yyyy').format(_selectedDateTimeSpinner) :
            DateFormat('HH:mm').format(_selectedDateTimeSpinner),
            style: AppStyle.interNormal(
              size: 24,
              color: AppStyle.white,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_downward, color: AppStyle.white),
              onPressed: () {
                setState(() {
                  _selectedDateTimeSpinner = _selectedDateTimeSpinner.subtract(
                      widget.mode == CupertinoDatePickerMode.date ?
                      const Duration(days: 1) :
                      const Duration(minutes: 1)
                  );
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Use Up/Down arrows or click buttons',
          style: AppStyle.interNormal(
            size: 12,
            color: AppStyle.white,
          ),
        ),
      ],
    );
  }

  _showMenu() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        double screenWidth = MediaQuery.sizeOf(context).width;
        double screenHeight = MediaQuery.sizeOf(context).height;

        final size = _childBox!.size;
        final offset = _childBox!.localToGlobal(const Offset(0, 0));

        Widget menu = Container(
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radius),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: AppStyle.black.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 225,
                  width: 300,
                  child: Focus(
                    focusNode: _focusNode,
                    onKeyEvent: (node, event) {
                      _handleKeyEvent(event);
                      return KeyEventResult.handled;
                    },
                    autofocus: true,
                    child: Platform.isWindows ?
                    _buildWindowsPicker()
                        : CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: AppStyle.interNormal(color: AppStyle.white),
                        ),
                        primaryColor: AppStyle.white,
                        brightness: Brightness.dark,
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: CupertinoDatePicker(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          minimumDate: widget.minDate,
                          maximumDate: widget.maxDate,
                          minuteInterval: widget.minuteInterval,
                          initialDateTime: _selectedDateTimeSpinner,
                          use24hFormat: true,
                          mode: widget.mode,
                          onDateTimeChanged: (dateTime) {
                            setState(() {
                              if (widget.minDate != null &&
                                  dateTime.isBefore(widget.minDate!)) {
                                _selectedDateTimeSpinner = widget.minDate!;
                              } else if (widget.maxDate != null &&
                                  dateTime.isAfter(widget.maxDate!)) {
                                _selectedDateTimeSpinner = widget.maxDate!;
                              } else {
                                _selectedDateTimeSpinner = dateTime;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                DefaultTextStyle(
                  style: AppStyle.interNormal(color: AppStyle.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          _animationController.reverse();
                          _selectedDateTimeSpinner = _selectedDateTime ?? DateTime.now();
                          Future.delayed(const Duration(milliseconds: 150), () {
                            _hideMenu();
                          });
                        },
                        child: Text(
                          AppHelpers.getTranslation(TrKeys.cancel),
                          style: AppStyle.interNormal(size: 14, color: AppStyle.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _animationController.reverse();
                          setState(() => _selectedDateTime = _selectedDateTimeSpinner);
                          Future.delayed(const Duration(milliseconds: 150), () {
                            if (widget.mode == CupertinoDatePickerMode.time) {
                              widget.onTimeChange?.call(_selectedDateTimeSpinner.toTime);
                            } else {
                              widget.onDateChange?.call(_selectedDateTimeSpinner);
                            }
                            setInitialTimes();
                            setStateValue();
                            _hideMenu();
                          });
                        },
                        child: Text(
                          AppHelpers.getTranslation(TrKeys.ok),
                          style: AppStyle.interNormal(size: 14, color: AppStyle.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );

        Widget menuWithPositioned = AnimatedBuilder(
          animation: _animation,
          builder: (BuildContext context, Widget? child) {
            final value = _animation.value ?? 0;
            final centerHorizontal = offset.dx + (size.width) / 2;

            final menuWidth = 300.0;

            double left = centerHorizontal - ((menuWidth / 2) * value);
            double right = screenWidth - (centerHorizontal + ((menuWidth / 2) * value));
            double? top = offset.dy - ((220 / 2) * value);
            double? bottom;

            if (left < 5) {
              left = 5;
              right = screenWidth - (menuWidth + 10);
            }

            if (right < 5) {
              right = 5;
              left = screenWidth - (menuWidth + 10);
            }

            if (top < 5) {
              top = 5;
              bottom = null;
            }

            if (top != null && top + 240 > screenHeight) {
              bottom = 5;
              top = null;
            }

            return Positioned(
              left: left,
              right: right,
              top: top,
              bottom: bottom,
              child: Container(
                width: menuWidth,
                constraints: BoxConstraints(
                  maxHeight: 270 * value,
                ),
                child: SingleChildScrollView(child: menu),
              ),
            );
          },
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _controller?.hideMenu(),
                child: Container(color: AppStyle.black),
              ),
            ),
            menuWithPositioned,
          ],
        );
      },
    );
    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
      _animationController.forward();
      _focusNode.requestFocus();
    }
  }

  Widget _timeWidget(FormFieldState<String> state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: REdgeInsets.only(right: 6, bottom: 2),
            child: Text(
              "${AppHelpers.getTranslation(widget.label ?? '')} ${widget.validation != null ? '*' : ''}",
              style: AppStyle.interNormal(size: 14, color: AppStyle.white),
            ),
          ),
        InkWell(
          onTap: widget.readOnly
              ? null
              : () {
            _controller?.showMenu();
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide.merge(
                  const BorderSide(color: AppStyle.icon),
                  const BorderSide(color: AppStyle.icon),
                ),
              ),
              borderRadius: BorderRadius.circular(AppConstants.radius.r),
            ),
            padding: widget.contentPadding ??
                REdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.value ??
                        AppHelpers.getTranslation(TrKeys.pleaseSelect),
                    style: AppStyle.interNormal(
                      size: 14,
                      color: state.value == null ? AppStyle.textHint : AppStyle.white,
                    ),
                  ),
                ),
                Icon(
                  iconAssets,
                  size: widget.iconSize,
                  color: state.value == null ? AppStyle.textHint : AppStyle.white,
                ),
              ],
            ),
          ),
        ),
        state.hasError
            ? Padding(
          padding: REdgeInsets.only(left: 14, top: 4),
          child: Text(
            state.errorText ?? '',
            style: AppStyle.interRegular(size: 12, color: AppStyle.red),
          ),
        )
            : Container()
      ],
    );
  }

  _hideMenu() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    _focusNode.unfocus();
  }

  _updateView() {
    bool menuIsShowing = _controller?.menuIsShowing ?? false;
    if (menuIsShowing) {
      _showMenu();
    } else {
      _hideMenu();
    }
  }
}

class TimePickerSpinnerController extends ChangeNotifier {
  bool menuIsShowing = false;
  bool isUpdate = false;

  void showMenu() {
    menuIsShowing = true;
    notifyListeners();
  }

  void hideMenu() {
    menuIsShowing = false;
    notifyListeners();
  }

  void toggleMenu() {
    menuIsShowing = !menuIsShowing;
    notifyListeners();
  }

  void updateMenu() {
    isUpdate = true;
    hideMenu();
    showMenu();
    isUpdate = false;
  }
}
