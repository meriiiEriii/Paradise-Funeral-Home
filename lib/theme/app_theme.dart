import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Corporate blue ramp — calm, desaturated, print-like.
  static const brand50 = Color(0xFFF2F6FD);
  static const brand100 = Color(0xFFE4EDFA);
  static const brand200 = Color(0xFFC6DAF4);
  static const brand300 = Color(0xFF97BCED);
  static const brand400 = Color(0xFF6197DF);
  static const brand500 = Color(0xFF3B76CE);
  static const brand600 = Color(0xFF235CB0);
  static const brand700 = Color(0xFF1C4A90);
  static const brand800 = Color(0xFF183C74);
  static const brand900 = Color(0xFF142F5C);

  // Neutral slate accent (replaces the old teal).
  static const slate = Color(0xFF3E5C8A);
  static const slateDeep = Color(0xFF273D5E);
  static const slateSoft = Color(0xFFE9EFF7);

  static const ink = Color(0xFF16233A);
  static const canvas = Color(0xFFF6F8FB);
  static const success = Color(0xFF177A4B);
  static const warning = Color(0xFF96660A);
  static const danger = Color(0xFFB03A2E);
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
    success: Color(0xFF177A4B),
    successSoft: Color(0xFFE4F3EB),
    warning: Color(0xFF96660A),
    warningSoft: Color(0xFFF8F1DF),
    danger: Color(0xFFB03A2E),
    dangerSoft: Color(0xFFFBEAE7),
    accent: Color(0xFF3E5C8A),
    accentSoft: Color(0xFFE9EFF7),
    brandSoft: Color(0xFFE4EDFA),
    surfaceAlt: Color(0xFFF2F5F9),
    border: Color(0xFFDFE5EE),
    muted: Color(0xFF5D6B80),
    heroStart: Color(0xFF17395F),
    heroEnd: Color(0xFF215789),
  );

  static const dark = AppPalette(
    success: Color(0xFF6FBF97),
    successSoft: Color(0xFF142A20),
    warning: Color(0xFFD9B36A),
    warningSoft: Color(0xFF2A2110),
    danger: Color(0xFFE58B84),
    dangerSoft: Color(0xFF321714),
    accent: Color(0xFF8CA6C9),
    accentSoft: Color(0xFF16233A),
    brandSoft: Color(0xFF16253C),
    surfaceAlt: Color(0xFF152134),
    border: Color(0xFF24344D),
    muted: Color(0xFF8B9BB3),
    heroStart: Color(0xFF122742),
    heroEnd: Color(0xFF1B3E66),
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
          secondary: AppColors.slate,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.slateSoft,
          onSecondaryContainer: AppColors.slateDeep,
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
          primary: const Color(0xFF8FB3E8),
          onPrimary: const Color(0xFF0D2138),
          primaryContainer: const Color(0xFF1A3860),
          onPrimaryContainer: const Color(0xFFD6E4FA),
          secondary: const Color(0xFF9FB4D4),
          onSecondary: const Color(0xFF131F30),
          secondaryContainer: const Color(0xFF1D2F49),
          onSecondaryContainer: const Color(0xFFDCE5F2),
          surface: const Color(0xFF101824),
          onSurface: const Color(0xFFE7EDF6),
          surfaceContainerHighest: palette.surfaceAlt,
          outline: palette.border,
          outlineVariant: const Color(0xFF1C2B42),
          error: const Color(0xFFE58B84),
          onError: const Color(0xFF360D0A),
        );
    return _build(scheme, palette, canvas: const Color(0xFF0B111C));
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
      fontFamily: 'PlusJakartaSans',
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
        toolbarHeight: 64,
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
          borderRadius: BorderRadius.circular(14),
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
        fillColor: isDark ? palette.surfaceAlt : Colors.white,
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
        border: _inputBorder(palette.border),
        enabledBorder: _inputBorder(palette.border),
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
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
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
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
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
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
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
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          highlightColor: scheme.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        extendedTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF1C2B42) : AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: Colors.white,
          fontSize: 13.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.all(16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrimColor: Colors.black.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.muted,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceAlt,
        side: BorderSide(color: palette.border),
        labelStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          color: isDark ? const Color(0xFF22334C) : AppColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
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
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: palette.muted,
        ),
        dataTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: palette.muted,
        labelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
        indicatorColor: scheme.primary,
        dividerColor: palette.border,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    final themed = base.apply(
      fontFamily: 'PlusJakartaSans',
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return themed.copyWith(
      displaySmall: themed.displaySmall?.copyWith(
        fontFamily: 'Lora',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineMedium: themed.headlineMedium?.copyWith(
        fontFamily: 'Lora',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      headlineSmall: themed.headlineSmall?.copyWith(
        fontFamily: 'Lora',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: themed.titleLarge?.copyWith(
        fontFamily: 'Lora',
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleMedium: themed.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: themed.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: themed.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: themed.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
