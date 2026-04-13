import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const bg = Color(0xFFF5F7FA);
  static const bg2 = Color(0xFFFFFFFF);
  static const bg3 = Color(0xFFEEF2F7);
  static const bg4 = Color(0xFFE5EAF1);
  static const card = Color(0xFFFFFFFF);
  static const card2 = Color(0xFFF2F5F9);

  // Accent
  static const accent = Color(0xFF0F766E);
  static const accent2 = Color(0xFF0E7490);
  static const accent3 = Color(0xFF0284C7);
  static const accent4 = Color(0xFFB45309);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted = Color(0xFF6B7280);

  // Semantic
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);
  static const gold = Color(0xFFEAB308);

  // Border
  static const border = Color(0x1F111827);
  static const border2 = Color(0x1A111827);

  // Badge backgrounds
  static const badgeBest = Color(0x1F0F766E);
  static const badgeCheap = Color(0x1F10B981);
  static const badgeRated = Color(0x1FB45309);
  static const badgeFast = Color(0x1F0E7490);

  // Platform
  static Color amazon = const Color(0xFFEAF1FF);
  static Color flipkart = const Color(0xFFEFFBF4);
  static Color myntra = const Color(0xFFFFF1F5);
}

class AppTextStyles {
  static TextStyle sora(double size, FontWeight weight, Color color) =>
      GoogleFonts.sora(fontSize: size, fontWeight: weight, color: color);

  static TextStyle dmSans(double size, FontWeight weight, Color color) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);

  static final heading1 = GoogleFonts.sora(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static final heading2 = GoogleFonts.sora(
    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static final heading3 = GoogleFonts.sora(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static final body = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static final bodySmall = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static final caption = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted);

  static final price = GoogleFonts.sora(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static final priceSmall = GoogleFonts.sora(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.accent);
}
