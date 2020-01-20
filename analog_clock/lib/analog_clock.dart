// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analog_clock/drawn_border.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'drawn_hand.dart';

/// Total distance traveled by a second hand each millisecond or a second depending upon frames chosen.
final radiansPerMillis = radians(360 / (frames == Frames.one ? 60 : 60000));

/// Total distance traveled by a minute hand each minute.
final radiansPerMinute = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

// Frames per second
// If the value is set to one, then second hand will tick after a second passes.
// If the value is set to twentyFive, then it will move smoothly.
enum Frames { one, twentyFive }

var frames = Frames.twentyFive;

var light = true;

/// A analog clock.
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureMax = '';
  var _temperatureMin = '';
  var _condition = '';
  var _location = '';
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureMin = '${widget.model.lowString}';
      _temperatureMax = '${widget.model.highString}';
      _condition = condition(widget.model.weatherString);
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second or twenty four times in a second so that it looks smoothly moving to human eye
      _timer = Timer(
        Duration(milliseconds: (frames == Frames.one) ? 1000 : 40),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].

    light = Theme.of(context).brightness == Brightness.light;
    final customTheme = light
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Colors.black,
            // Minute hand.
            highlightColor: Colors.grey[800],
            // Second hand.
            accentColor: Colors.red,
            backgroundColor: Color(0xFFE0DFE4),
          )
        : Theme.of(context).copyWith(
            primaryColor: Colors.black,
            highlightColor: Colors.grey[850],
            accentColor: Colors.red[900],
            backgroundColor: Color(0xFF3C4043),
          );

    final textStyle = TextStyle(
      color: light ? customTheme.primaryColor : Colors.white,
      fontWeight: FontWeight.w700,
    );
    final time = DateFormat.Hms().format(DateTime.now());
    final accessible = MediaQuery.of(context).accessibleNavigation;

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
        color: customTheme.backgroundColor,
        child: Stack(
          children: [
            // Location.
            Positioned(
              left: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _location,
                  style: textStyle,
                ),
              ),
            ),

            // The Border of the clock, ticks and the hour indicator text.
            DrawnBorder(
              // Color of border and text.
              color: customTheme.primaryColor,
              // Border thickness.
              thickness: 12,
              // Size of text for the hour numbers.
              textSize:
                  accessible ? 30 : 14 * MediaQuery.textScaleFactorOf(context),
              // Whether theme is light or not.
              light: light,
            ),

            // Hour hand.
            DrawnHand(
              color: customTheme.primaryColor,
              thickness: 10,
              size: 0.4,
              angleRadians: _now.hour * radiansPerHour +
                  (_now.minute / 60) * radiansPerHour,
            ),

            // Minute hand.
            DrawnHand(
              color: customTheme.highlightColor,
              thickness: 10,
              size: 0.6,
              angleRadians: _now.minute * radiansPerMinute,
            ),

            // Second hand.
            DrawnHand(
              color: customTheme.accentColor,
              thickness: 4,
              size: 0.76,
              angleRadians: (frames == Frames.one
                      ? _now.second
                      : _now.second * 1000 + _now.millisecond) *
                  radiansPerMillis,
            ),

            // Dot in center. On top of all hands.
            Center(
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: customTheme.accentColor,
                ),
              ),
            ),

            // Maximum and minimum temperature.
            Positioned(
              top: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '$_temperatureMax ▲\n'
                  '$_temperatureMin ▼',
                  style: textStyle,
                ),
              ),
            ),

            // Condition and temperature.
            Positioned(
              left: 0,
              top: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '$_condition\n'
                  '$_temperature',
                  style: textStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Return string with first letter capital.
  String condition(String c) {
    return c.substring(0, 1).toUpperCase() + c.substring(1);
  }
}
