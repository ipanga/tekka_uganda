import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TekkaLogo extends StatelessWidget {
  final double height;
  final bool forceLight;

  const TekkaLogo({super.key, this.height = 28, this.forceLight = false});

  @override
  Widget build(BuildContext context) {
    final isDark =
        forceLight || Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/images/tekka_logo_white.svg'
        : 'assets/images/tekka_logo.svg';

    return SvgPicture.asset(asset, height: height, semanticsLabel: 'Tekka');
  }
}
