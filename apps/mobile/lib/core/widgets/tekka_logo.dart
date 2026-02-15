import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TekkaLogo extends StatelessWidget {
  final double height;

  const TekkaLogo({super.key, this.height = 28});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/tekka_logo.svg',
      height: height,
      semanticsLabel: 'Tekka',
    );
  }
}
