/// Minimal i18n without extra packages.
class I18n {
  static const en = 'en';
  static const si = 'si';

  static final Map<String, Map<String, String>> _strings = {
    en: {
      'app.title': 'Safelink User',
      'login.title': 'Login',
      'login.email': 'Email',
      'login.password': 'Password',
      'login.button': 'Login',
      'login.toRegister': 'Create an account',
      'login.working': 'Logging in...',

      'register.title': 'Register (User only)',
      'register.fullName': 'Full name',
      'register.button': 'Create account',
      'register.working': 'Creating...',
      'register.success': 'Registration successful. You can login now.',

      'home.title': 'Home',
      'home.loggedIn': 'Logged in!',
      'home.logout': 'Logout',
      'home.profile': 'Profile',
      'home.refreshLocation': 'Refresh location',
      'home.min': 'min',
      'home.tapIfEmergency': 'Press this button in case of emergency',
      'home.quickReport': 'Quick report',
      'home.viewMyIncidents': 'My incidents',

      'incidents.title': 'My Incidents',
      'incidents.unknownId': 'Unknown ID',
      'incident.title': 'Incident',
      'incident.notFound': 'Incident not found',
      'incident.type': 'Type',
      'incident.status': 'Status',
      'incident.priority': 'Priority',
      'incident.description': 'Description',
      'incident.locationText': 'Location',
      'incident.casualties': 'Casualties',
      'incident.bystander': 'Are you a bystander?',
      'incident.eta': 'ETA',
      'incident.officer': 'Officer',
      'incident.images': 'Images',
      'common.yes': 'Yes',
      'common.no': 'No',

      'lang.toggle': 'සිංහල',

      // Friendly errors
      'err.NETWORK': 'Network error — check your connection.',
      'err.UNAUTHORIZED': 'Invalid email or password.',
      'err.DUPLICATE_EMAIL': 'That email is already registered.',
      'err.VALIDATION_ERROR': 'Please check your inputs.',
      'err.UNKNOWN': 'Something went wrong. Please try again.',

      'bot.title': 'Assistant',
      'bot.hi': 'Hi! I can help you add details. Try: "casualties 2", "bystander yes", "note: smoke in the building", or "upload images". Type "help" anytime.',
      'bot.help': 'You can say:\n• casualties 0/1/2...\n• bystander yes/no\n• note: <text>\n• upload images',
      'bot.bystander.ask': 'Are you a bystander? Reply "yes" or "no".',
      'bot.saved': 'Saved!',
      'bot.err': 'Error',
      'bot.fallback': 'Sorry, I didn’t get that. Try "help".',
      'bot.hint': 'Type here...',
      'bot.send': 'Send',
      'bot.addImages': 'Add images',
      'bot.img.ok': 'Images uploaded.',

      'bot.hi_short': 'Let’s add a few quick details.',
      'bot.q.casualties': 'How many casualties?',
      'bot.q.bystander': 'Are you a bystander?',
      'bot.q.type': 'Select the incident type',
      'bot.q.more': 'Anything else?',
      'bot.addNote': 'Add note',
      'bot.note.hint': 'Type your note and press Send.',
      'bot.useChips': 'Please use the quick options above.',
      'bot.restart': 'Start again',
      'bot.skip': 'Skip',
    },
    si: {
      'app.title': 'සේෆ්ලින්ක් පරිශීලක',
      'login.title': 'ඇතුල් වන්න',
      'login.email': 'ඊමේල්',
      'login.password': 'මුරපදය',
      'login.button': 'ඇතුල් වන්න',
      'login.toRegister': 'ගිණුමක් සාදන්න',
      'login.working': 'ඇතුල් වෙමින්...',

      'register.title': 'ලියාපදිංචි වීම (පරිශීලකයාට පමණි)',
      'register.fullName': 'සම්පූර්ණ නම',
      'register.button': 'ගිණුම සෑදෙන්න',
      'register.working': 'සෑදෙමින්...',
      'register.success': 'ලියාපදිංචිය සාර්ථකයි. දැන් ඇතුල් වන්න.',

      'home.title': 'මුල් පිටුව',
      'home.loggedIn': 'ඇතුල් වී ඇත!',
      'home.logout': 'පිටවෙන්න',
      'home.profile': 'පැතිකඩ',
      'home.refreshLocation': 'ස්ථානය යාවත්කාලීන කරන්න',
      'home.min': 'මිනි.',
      'home.tapIfEmergency': 'අත්‍යවශ්‍ය අවස්ථාවකදී මෙම බොත්තම ඔබන්න',
      'home.quickReport': 'ඉක්මන් වාර්තාව',
      'home.viewMyIncidents': 'මගේ සිදුවීම්',

      'lang.toggle': 'English',

      'err.NETWORK': 'ජාල ගැටලුවක් — සම්බන්ධතාවය පරීක්ෂා කරන්න.',
      'err.UNAUTHORIZED': 'ඊමේල් හෝ මුරපදය වැරදියි.',
      'err.DUPLICATE_EMAIL': 'එම ඊමේල් ගිණුම දැනටමත් ලියාපදිංචි වී ඇත.',
      'err.VALIDATION_ERROR': 'පුරප්පාඩු නිවැරදිදැයි පරීක්ෂා කරන්න.',
      'err.UNKNOWN': 'අයැදුම දෝෂ ගත්තේය. නැවත උත්සාහ කරන්න.',

      'incidents.title': 'මගේ සිදුවීම්',
      'incidents.unknownId': 'හැඳුනුම් අංකය නොදන්නා',
      'incident.title': 'සිදුවීම',
      'incident.notFound': 'සිදුවීම හමු නොවිණි',
      'incident.type': 'වර්ගය',
      'incident.status': 'තත්ත්වය',
      'incident.priority': 'ප්‍රමුඛතාව',
      'incident.description': 'විස්තරය',
      'incident.locationText': 'ස්ථානය',
      'incident.casualties': 'ආබාධිතයින්',
      'incident.bystander': 'ඔබ සාක්ෂිකරුවෙක්ද?',
      'incident.eta': 'පැමිණෙන වේලාව',
      'incident.officer': 'නිලධාරී',
      'incident.images': 'රූප',
      'common.yes': 'ඔව්',
      'common.no': 'නැහැ',

      'bot.title': 'සහායකයා',
      'bot.hi': 'ආයුබෝවන්! තොරතුරු එකතු කිරීමට උදව් කරමි. උදා: "casualties 2", "bystander ඔව්", "විස්තර: ගොඩනැගිල්ලේ දුම", හෝ "රූප upload". "help" ටයිප් කරන්න.',
      'bot.help': 'ඔබට කියන්න පුළුවන්:\n• casualties 0/1/2...\n• bystander ඔව්/නැහැ\n• විස්තර: <පෙළ>\n• රූප upload',
      'bot.bystander.ask': 'ඔබ සාක්ෂිකරුවෙක්ද? "ඔව්" හෝ "නැහැ" ලෙස පිළිතුරු දෙන්න.',
      'bot.saved': 'සුරැකිණි!',
      'bot.err': 'දෝෂයක්',
      'bot.fallback': 'කණගාටුයි, එය මට තේරුණේ නැහැ. "help" ටයිප් කරන්න.',
      'bot.hint': 'මෙහි ටයිප් කරන්න...',
      'bot.send': 'යවන්න',
      'bot.addImages': 'රූප එක් කරන්න',
      'bot.img.ok': 'රූප යවනු ලැබීය.',

      'bot.hi_short': 'ඉක්මනින් තොරතුරු කිහිපයක් එකතු කරමු.',
      'bot.q.casualties': 'ආබාධිතයින් කිීයද?',
      'bot.q.bystander': 'ඔබ සාක්ෂිකරුවෙක්ද?',
      'bot.q.type': 'සිදුවීමේ වර්ගය තෝරන්න',
      'bot.q.more': 'තවදුරක් තිබේද?',
      'bot.addNote': 'සටහන එක් කරන්න',
      'bot.note.hint': 'සටහන ටයිප් කර Send ඔබන්න.',
      'bot.useChips': 'ඉහත දී ඇති විකල්ප භාවිතා කරන්න.',
      'bot.restart': 'නැවත ආරම්භ කරන්න',
      'bot.skip': 'එපා',
    },
  };

  /// Translate with safe fallback to English, or return the key itself.
  static String t(String lang, String key) {
    final l = _strings[lang] ?? _strings[en]!;
    return l[key] ?? _strings[en]![key] ?? key;
  }

  /// Convenience: try a code first, then 'UNKNOWN'
  static String error(String lang, String code) =>
      t(lang, 'err.$code') ?? t(lang, 'err.UNKNOWN');
}
