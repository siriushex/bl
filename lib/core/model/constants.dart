abstract class Constants {
  static const appName =
      String.fromEnvironment('app_name', defaultValue: 'ZeonConnect');
  static const githubUrl = "https://github.com/hiddify/hiddify-next";
  static const githubReleasesApiUrl =
      "https://api.github.com/repos/hiddify/hiddify-next/releases";
  static const githubLatestReleaseUrl =
      "https://github.com/hiddify/hiddify-next/releases/latest";
  static const appCastUrl =
      "https://raw.githubusercontent.com/hiddify/hiddify-next/main/appcast.xml";
  static const telegramChannelUrl = "https://t.me/hiddify";
  static const privacyPolicyUrl = "https://hiddify.com/privacy-policy/";
  static const termsAndConditionsUrl = "https://hiddify.com/terms/";
  static const cfWarpPrivacyPolicy =
      "https://www.cloudflare.com/application/privacypolicy/";
  static const cfWarpTermsOfService =
      "https://www.cloudflare.com/application/terms/";

  static const backendApiBaseUrl = String.fromEnvironment(
    'backend_api_base_url',
    defaultValue: 'https://api.zeonconnect.example',
  );

  static const telegramLoginUrl = String.fromEnvironment(
    'telegram_login_url',
    defaultValue: 'https://app.zeonconnect.example/telegram-login',
  );

  static const telegramBotUsername = String.fromEnvironment(
    'telegram_bot_username',
    defaultValue: 'ZeonConnectBot',
  );

  static const telegramBotStartParameter = String.fromEnvironment(
    'telegram_bot_start_parameter',
    defaultValue: 'subscribe',
  );

  static const deepLinkScheme = String.fromEnvironment(
    'deep_link_scheme',
    defaultValue: 'zeonconnect',
  );

  static Uri get telegramBotAppLink =>
      Uri.parse('tg://resolve?domain=$telegramBotUsername');

  static Uri get telegramBotWebLink =>
      Uri.parse('https://t.me/$telegramBotUsername');

  static Uri get telegramBotCheckoutWebLink => Uri.parse(
        'https://t.me/$telegramBotUsername?start=$telegramBotStartParameter',
      );

  static Uri get telegramBotCheckoutAppLink => Uri.parse(
        'tg://resolve?domain=$telegramBotUsername&start=$telegramBotStartParameter',
      );
}

const kAnimationDuration = Duration(milliseconds: 250);
