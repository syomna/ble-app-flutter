import 'package:flutter/widgets.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static late double _safeAreaHorizontal;
  static late double _safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  // Figma scale factors
  static late double scaleWidth;
  static late double scaleHeight;

  // Initialization method with optional min and max scale factors
  static void init(BuildContext context,
      {double figmaWidth = 360,
      double figmaHeight = 778,
      double minScale = 0.8,
      double maxScale = 1.2}) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    // Calculate block sizes for percentage-based scaling
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    // Calculate safe area adjustments
    _safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    _safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal =
        (_mediaQueryData.size.width - _safeAreaHorizontal) / 100;
    safeBlockVertical = (_mediaQueryData.size.height - _safeAreaVertical) / 100;

    // Calculate scale factors based on Figma frame dimensions
    double widthScale = screenWidth / figmaWidth;
    double heightScale = screenHeight / figmaHeight;
    double scale = widthScale < heightScale ? widthScale : heightScale;

    // Apply min and max scaling constraints
    scale = scale.clamp(minScale, maxScale);

    scaleWidth = scale;
    scaleHeight = scale;
  }

  static double getHeight(double height) {
    return height * scaleHeight;
  }

  static double getWidth(double width) {
    return width * scaleWidth;
  }

  static double getFontSize(double fontSize) {
    return fontSize * scaleWidth;
  }
}

enum DeviceType { tablet, largePhone, smallPhone }

class DeviceUtils {
  static DeviceType getDeviceType(double screenWidth) {
    if (screenWidth >= 1024) {
      return DeviceType.tablet;
    } else if (screenWidth >= 600) {
      return DeviceType.largePhone;
    } else {
      return DeviceType.smallPhone;
    }
  }
}
