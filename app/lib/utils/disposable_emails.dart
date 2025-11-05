import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// [DisposableEmailChecker] provides functionality to check if an email address
/// uses a disposable email domain.
///
/// The list of disposable domains is loaded from a JSON asset file, which makes
/// it easy to update without modifying code.
class DisposableEmailChecker {
  static Set<String>? _domains;
  static bool _initialized = false;

  /// Initialize the disposable email checker by loading the domain list
  /// from the JSON asset file.
  ///
  /// This should be called once during app initialization.
  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/disposable_emails.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final domainsList = data['domains'] as List<dynamic>;

      _domains = Set<String>.from(
        domainsList.map((d) => d.toString().toLowerCase()),
      );

      _initialized = true;
    } catch (e) {
      // If loading fails, use empty set to avoid crashes
      // This gracefully degrades - emails won't be blocked but app won't crash
      _domains = <String>{};
      _initialized = true;
    }
  }

  /// Check if the given email address uses a disposable domain
  ///
  /// Returns true if the email domain is in the disposable list.
  /// Returns false if the domain is not disposable or if the email format is invalid.
  ///
  /// Note: If [init] hasn't been called, this will return false to avoid blocking users.
  static bool isDisposable(String email) {
    if (!_initialized || _domains == null) {
      // Not initialized - fail open (don't block users)
      return false;
    }

    final emailParts = email.toLowerCase().split('@');
    if (emailParts.length < 2) {
      // Invalid email format
      return true;
    }

    final domain = emailParts[emailParts.length - 1];
    return _domains!.contains(domain);
  }

  /// Get statistics about the loaded disposable email list
  ///
  /// Returns a map with:
  /// - `initialized`: Whether the checker has been initialized
  /// - `domainCount`: Number of domains loaded
  static Map<String, dynamic> getStats() {
    return {
      'initialized': _initialized,
      'domainCount': _domains?.length ?? 0,
    };
  }
}

/// [isDisposableEmail] checks if the email is a disposable email.
///
/// This is the legacy function maintained for backward compatibility.
/// New code should use [DisposableEmailChecker.isDisposable] instead.
///
/// **Important**: This function requires [DisposableEmailChecker.init] to be
/// called during app initialization, otherwise it will always return false.
bool isDisposableEmail(String email) {
  return DisposableEmailChecker.isDisposable(email);
}
