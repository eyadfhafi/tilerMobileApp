import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';

class AnalysisCheckState extends StatelessWidget {
  const AnalysisCheckState({
    super.key,
    this.isPass = false,
    this.isWarning = false,
    this.isConflict = false,
    required this.height,
  });

  final bool isPass;
  final bool isWarning;
  final bool isConflict;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (isPass) {
      return Container(
        width: height / (height / 24),
        height: height / (height / 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / (height / 8)),
            color: Color(0xFF1AE1A6)),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/check.svg',
            height: height / (height / 16),
            width: height / (height / 16),
          ),
        ),
      );
    } else if (isWarning) {
      return Container(
        width: height / (height / 24),
        height: height / (height / 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / (height / 8)),
            color: Color(0xFFFF891C)),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/exclamation.svg',
            height: height / (height / 16),
            width: height / (height / 16),
          ),
        ),
      );
    } else if (isConflict) {
      return Container(
        width: height / (height / 24),
        height: height / (height / 24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / (height / 8)),
            color: Color(0xFFD61C3C)),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/exclamation.svg',
            height: height / (height / 16),
            width: height / (height / 16),
          ),
        ),
      );
    }
    return Container(
      width: height / (height / 24),
      height: height / (height / 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / (height / 8)),
        color: Color(0xFF1F1F1F).withOpacity(0.05),
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/clock.svg',
          height: height / (height / 10),
          width: height / (height / 10),
        ),
      ),
    );
  }
}
