import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const brand50 = Color(0xFFF2F7FE);
  static const brand100 = Color(0xFFE1EDFB);
  static const brand200 = Color(0xFFC3DAF7);
  static const brand300 = Color(0xFF8FBAEF);
  static const brand400 = Color(0xFF5A97E3);
  static const brand500 = Color(0xFF2E76CE);
  static const brand600 = Color(0xFF1A5FAE);
  static const brand700 = Color(0xFF144C8F);
  static const brand800 = Color(0xFF0F3B70);
  static const brand900 = Color(0xFF0A2A52);

  static const teal = Color(0xFF0E8F8F);
  static const tealDeep = Color(0xFF075C5C);
  static const tealSoft = Color(0xFFDFF4F4);

  static const ink = Color(0xFF11253C);
  static const canvas = Color(0xFFF2F5FA);
  static const success = Color(0xFF1E8E5A);
  static const warning = Color(0xFFB96E00);
  static const danger = Color(0xFFC0392B);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.accent,
    required this.accentSoft,
    required this.brandSoft,
    required this.surfaceAlt,
    required this.border,
    required this.muted,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color accent;
  final Color accentSoft;
  final Color brandSoft;
  final Color surfaceAlt;
  final Color border;
  final Color muted;
  final Color heroStart;
  final Color heroEnd;

  static const light = AppPalette(
    success: Color(0xFF16794C),
    successSoft: Color(0xFFE2F4EA),
    warning: Color(0xFF9A5B00),
    warningSoft: Color(0xFFFCF0DA),
    danger: Color(0xFFB03325),
    dangerSoft: Color(0xFFFBE8E5),
    accent: Color(0xFF0E8F8F),
    accentSoft: Color(0xFFDFF4F4),
    brandSoft: Color(0xFFE8F1FC),
    surfaceAlt: Color(0xFFEDF3FA),
    border: Color(0xFFD3DEEB),
    muted: Color(0xFF5B6B80),
    heroStart: Color(0xFF0A3568),
    heroEnd: Color(0xFF1F6FC4),
  );

  static const dark = AppPalette(
    success: Color(0xFF57C998),
    successSoft: Color(0xFF143326),
    warning: Color(0xFFE8B15A),
    warningSoft: Color(0xFF33270F),
    danger: Color(0xFFF07A7A),
    dangerSoft: Color(0xFF3A1A1D),
    accent: Color(0xFF4FC3C3),
    accentSoft: Color(0xFF12333A),
    brandSoft: Color(0xFF122A45),
    surfaceAlt: Color(0xFF13253A),
    border: Color(0xFF22374F),
    muted: Color(0xFF8498AF),
    heroStart: Color(0xFF0A2A4F),
    heroEnd: Color(0xFF1B5FA8),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

  @override
  AppPalette copyWith({
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? accent,
    Color? accentSoft,
    Color? brandSoft,
    Color? surfaceAlt,
    Color? border,
    Color? muted,
    Color? heroStart,
    Color? heroEnd,
  }) {
    return AppPalette(
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      brandSoft: brandSoft ?? this.brandSoft,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final palette = AppPalette.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand600,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.brand600,
          onPrimary: Colors.white,
          primaryContainer: AppColors.brand100,
          onPrimaryContainer: AppColors.brand900,
          secondary: AppColors.teal,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.tealSoft,
          onSecondaryContainer: AppColors.tealDeep,
          surface: Colors.white,
          onSurface: AppColors.ink,
          surfaceContainerHighest: palette.surfaceAlt,
          outline: palette.border,
          outlineVariant: AppColors.brand100,
          error: AppColors.danger,
          onError: Colors.white,
        );
    return _build(scheme, palette, canvas: AppColors.canvas);
  }

  static ThemeData dark() {
    final palette = AppPalette.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand400,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF7FB2FF),
          onPrimary: const Color(0xFF082544),
          primaryContainer: const Color(0xFF163A63),
          onPrimaryContainer: const Color(0xFFD8E7FF),
          secondary: const Color(0xFF6FD3D3),
          onSecondary: const Color(0xFF042B2B),
          secondaryContainer: const Color(0xFF123F42),
          onSecondaryContainer: const Color(0xFFC6F0F0),
          surface: const Color(0xFF0F1D2E),
          onSurface: const Color(0xFFE9F0FA),
          surfaceContainerHighest: palette.surfaceAlt,
          outline: palette.border,
          outlineVariant: const Color(0xFF1B2F47),
          error: const Color(0xFFF07A7A),
          onError: const Color(0xFF3A0B0B),
        );
    return _build(scheme, palette, canvas: const Color(0xFF081220));
  }

  static ThemeData _build(
    ColorScheme scheme,
    AppPalette palette, {
    required Color canvas,
  }) {
    final brightness = scheme.brightness;
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Poppins',
    );

    final textTheme = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      canvasColor: canvas,
      splashFactory: InkSparkle.splashFactory,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        shape: Border(bottom: BorderSide(color: palette.border)),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: palette.muted, fontSize: 13.5),
        labelStyle: TextStyle(
          color: palette.muted,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        prefixIconColor: palette.muted,
        suffixIconColor: palette.muted,
        border: _inputBorder(palette.muted.withValues(alpha: 0.42)),
        enabledBorder: _inputBorder(palette.muted.withValues(alpha: 0.42)),
        focusedBorder: _inputBorder(scheme.primary, width: 1.6),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: palette.surfaceAlt,
          disabledForegroundColor: palette.muted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          highlightColor: scheme.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        extendedTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1C3049) : AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 13.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.muted,
          height: 1.5,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: scheme.primary,
        headerForegroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: Colors.black.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.muted,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        side: BorderSide(color: palette.border),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: palette.surfaceAlt,
        circularTrackColor: palette.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : palette.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : palette.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF21374F) : AppColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(
          palette.muted.withValues(alpha: 0.4),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.22),
        selectionHandleColor: scheme.primary,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(palette.surfaceAlt),
        headingTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: palette.muted,
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: scheme.onSurface,
        ),
        dataRowColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? scheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        dividerThickness: 1,
        headingRowHeight: 48,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 68,
        horizontalMargin: 20,
        columnSpacing: 24,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final themed = base.apply(
      fontFamily: 'Poppins',
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return themed.copyWith(
      displaySmall: themed.displaySmall?.copyWith(
        fontFamily: 'Bitter',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: themed.headlineMedium?.copyWith(
        fontFamily: 'Bitter',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: themed.headlineSmall?.copyWith(
        fontFamily: 'Bitter',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: themed.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: themed.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: themed.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: themed.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: themed.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
