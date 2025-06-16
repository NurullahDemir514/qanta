import '../../../l10n/app_localizations.dart';

class GreetingUtils {
  static String getGreetingByTime(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return l10n.goodMorning;      // 05:00 - 11:59 "Günaydın! ☀️"
    } else if (hour >= 12 && hour < 17) {
      return l10n.goodAfternoon;    // 12:00 - 16:59 "İyi günler! 🌤️"
    } else if (hour >= 17 && hour < 21) {
      return l10n.goodEvening;      // 17:00 - 20:59 "İyi akşamlar! 🌆"
    } else {
      return l10n.goodNight;        // 21:00 - 04:59 "İyi geceler! 🌙"
    }
  }

  /// Kullanıcının tam adından sadece ilk kısmını (ilk boşluğa kadar) alır
  /// Örnek: "Onur Demir" -> "Onur"
  static String getFirstName(String fullName) {
    if (fullName.isEmpty) return fullName;
    
    final spaceIndex = fullName.indexOf(' ');
    if (spaceIndex == -1) {
      // Boşluk yoksa tüm adı döndür
      return fullName;
    }
    
    // İlk boşluğa kadar olan kısmı döndür
    return fullName.substring(0, spaceIndex);
  }
} 