import 'package:flutter/material.dart';

/// Colours for everything the tester draws: floating button, panel, chips,
/// buttons, inputs, toast.
///
/// - [primaryColor]: floating button, selected chips, filled buttons, the
///   selected dispatch mode, focus borders, pulse ring, accents.
/// - [secondaryColor]: panel background and input/card surfaces.
/// - [textColor]: text and icons drawn on [primaryColor] (button icon,
///   filled-button labels, selected chips).
/// - [panelTextColor]: text and icons on [secondaryColor]. When `null` a
///   black or white that contrasts with [secondaryColor] is used.
class DeeplinkTesterTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final Color? panelTextColor;

  const DeeplinkTesterTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    this.panelTextColor,
  });

  /// Derives the theme from the host app's [ThemeData].
  factory DeeplinkTesterTheme.fromHost(ThemeData host) {
    return DeeplinkTesterTheme(
      primaryColor: host.colorScheme.primary,
      secondaryColor: host.colorScheme.surface,
      textColor: host.colorScheme.onPrimary,
      panelTextColor: host.colorScheme.onSurface,
    );
  }

  Color get onSecondary => panelTextColor ?? contrastOf(secondaryColor);

  /// Black or white, whichever reads better on [background].
  static Color contrastOf(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  /// Builds a full Material theme so every stock widget in the panel picks
  /// the right colours. [host] supplies the font family.
  ThemeData toThemeData(ThemeData host) {
    final onSurface = onSecondary;
    final brightness = ThemeData.estimateBrightnessForColor(secondaryColor);
    final subtle = Color.alphaBlend(
      onSurface.withValues(alpha: 0.08),
      secondaryColor,
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: textColor,
      primaryContainer: Color.alphaBlend(
        primaryColor.withValues(alpha: 0.18),
        secondaryColor,
      ),
      onPrimaryContainer: onSurface,
      secondary: primaryColor,
      onSecondary: textColor,
      tertiary: primaryColor,
      onTertiary: textColor,
      error: host.colorScheme.error,
      onError: host.colorScheme.onError,
      surface: secondaryColor,
      onSurface: onSurface,
      surfaceContainerHighest: subtle,
      onSurfaceVariant: onSurface.withValues(alpha: 0.7),
      outline: onSurface.withValues(alpha: 0.4),
      inverseSurface: onSurface,
      onInverseSurface: secondaryColor,
    );
    final onPrimaryOrSurface = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected) ? textColor : onSurface,
    );
    final primaryWhenSelected = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected) ? primaryColor : subtle,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: host.textTheme.bodyMedium?.fontFamily,
      scaffoldBackgroundColor: secondaryColor,
      canvasColor: secondaryColor,
      dividerColor: scheme.outline,
      iconTheme: IconThemeData(color: onSurface),
      textTheme: host.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: subtle,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        labelStyle: TextStyle(color: onSurface),
        secondaryLabelStyle: TextStyle(color: textColor),
        iconTheme: IconThemeData(color: onSurface, size: 16),
        side: BorderSide.none,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: primaryWhenSelected,
          foregroundColor: onPrimaryOrSurface,
          iconColor: onPrimaryOrSurface,
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: onSurface),
      ),
      listTileTheme: ListTileThemeData(
        textColor: onSurface,
        iconColor: onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.8)),
        hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.5)),
        helperStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outline),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: onSurface),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(secondaryColor),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(secondaryColor),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(foregroundColor: onSurface),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeeplinkTesterTheme &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.textColor == textColor &&
        other.panelTextColor == panelTextColor;
  }

  @override
  int get hashCode =>
      primaryColor.hashCode ^
      secondaryColor.hashCode ^
      textColor.hashCode ^
      panelTextColor.hashCode;
}
