class AppConstants {
  AppConstants._();

  static const String appName = 'ميزانيتي AI';
  static const String currency = 'ج.م';
  static const double alertHighRatio = 0.85;
  static const double alertSpikeRatio = 1.15;
  static const int spikeMonthsWindow = 3;

  static const List<String> incomeTypes = ['ثابت', 'متغير', 'أخرى'];

  static const String roleManager = 'manager';
  static const String roleRecorder = 'recorder';

  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'طعام',     'type': 'variable', 'icon': 'restaurant'},
    {'name': 'بقالة',    'type': 'variable', 'icon': 'shopping_basket'},
    {'name': 'مواصلات',  'type': 'variable', 'icon': 'directions_car'},
    {'name': 'فواتير',   'type': 'fixed',    'icon': 'receipt_long'},
    {'name': 'إيجار',    'type': 'fixed',    'icon': 'home'},
    {'name': 'كهرباء',   'type': 'fixed',    'icon': 'bolt'},
    {'name': 'غاز',      'type': 'fixed',    'icon': 'local_fire_department'},
    {'name': 'ماء',      'type': 'fixed',    'icon': 'water_drop'},
    {'name': 'إنترنت',   'type': 'fixed',    'icon': 'wifi'},
    {'name': 'صحة',      'type': 'variable', 'icon': 'medical_services'},
    {'name': 'تعليم',    'type': 'variable', 'icon': 'school'},
    {'name': 'ترفيه',    'type': 'variable', 'icon': 'movie'},
    {'name': 'ملابس',    'type': 'variable', 'icon': 'checkroom'},
    {'name': 'أخرى',     'type': 'variable', 'icon': 'more_horiz'},
  ];

  static const List<Map<String, String>> knownAiApps = [
    {'name': 'ChatGPT',  'package': 'com.openai.chatgpt'},
    {'name': 'Gemini',   'package': 'com.google.android.apps.bard'},
    {'name': 'Claude',   'package': 'com.anthropic.claude'},
    {'name': 'Copilot',  'package': 'com.microsoft.copilot'},
    {'name': 'DeepSeek', 'package': 'com.deepseek.chat'},
    {'name': 'Perplexity','package': 'ai.perplexity.app.android'},
  ];
}
