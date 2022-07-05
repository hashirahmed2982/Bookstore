import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cs/utils/colors.dart';

final headingtitle = GoogleFonts.raleway(
  fontSize: 32.0,
  fontWeight: FontWeight.bold,
  fontStyle: FontStyle.italic,
  color: AppColors.heading,
  letterSpacing: -1.0,
);

final captiontitle = GoogleFonts.raleway(
  fontSize: 24,
  fontWeight: FontWeight.w300,
  color: AppColors.captioncolor,
  letterSpacing: -1.0,
);

final text = GoogleFonts.raleway(
    color: AppColors.textColor, fontSize: 25,
);

final textButton = GoogleFonts.raleway(
  color: AppColors.textColor,
  decoration: TextDecoration.underline,
);

final appbarText = GoogleFonts.raleway(
    color: AppColors.appBarTextColor,
  fontWeight: FontWeight.bold,
);

final buttonText = GoogleFonts.raleway(
  color: AppColors.textColor,
  fontWeight: FontWeight.w500,
);

final button = OutlinedButton.styleFrom(
  backgroundColor: AppColors.buttonColor,
);

final gmailButton = OutlinedButton.styleFrom(
  backgroundColor: AppColors.gmailButtonColor,
);

final fbButton = OutlinedButton.styleFrom(
  backgroundColor: AppColors.fbButtonColor,
);

final cancelProductButton = TextButton.styleFrom(
  backgroundColor: AppColors.cancelButtonColor,
);

final addedToBookmarksButton = TextButton.styleFrom(
  backgroundColor: AppColors.addedToBookmarksColor,
);