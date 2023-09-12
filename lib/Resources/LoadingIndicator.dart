import 'package:design_project/Resources/resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

Widget buildContainerLoading() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0x88000000),
    ),
    child:Center(
        child: SpinKitThreeBounce(
            size: 25,
            color: const Color(0xDDFFFFFF),
            duration: const Duration(milliseconds: 1200)
        )),
  );
}

Widget buildLoadingProgress() {
  return Center(
        child: SpinKitThreeBounce(
            size: 25,
            color: colorGrey,
            duration: const Duration(milliseconds: 1200)
        ),
  );
}
