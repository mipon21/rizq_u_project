import 'package:flutter/material.dart';
import 'package:rizq/app/utils/constants/colors.dart';
import 'package:rizq/app/utils/constants/sizes.dart';
import '../../utils/constants/colors.dart';

class MAppBarTheme {
  MAppBarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    backgroundColor: MColors.primary,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: MColors.white, size: MSizes.iconMd),
    actionsIconTheme: IconThemeData(color: MColors.white, size: MSizes.iconMd),
    titleTextStyle: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: MColors.white,
    ),
  );
  static const darkAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 0,
    backgroundColor: MColors.primary,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: MColors.white, size: MSizes.iconMd),
    actionsIconTheme: IconThemeData(color: MColors.white, size: MSizes.iconMd),
    titleTextStyle: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: MColors.white,
    ),
  );
}
