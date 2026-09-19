enum Environment { development, production }

class EnvConfig {
  static Environment currentEnvironment = Environment.development;

  static void setEnvironment(Environment env) {
    currentEnvironment = env;
  }

  static bool get isDev => currentEnvironment == Environment.development;
  static bool get isProd => currentEnvironment == Environment.production;

  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.production:
        return 'https://api.geminiflo.com/api';
      case Environment.development:
        // When running on Android emulator use 10.0.2.2, on Windows/iOS use localhost:8000
        return 'http://10.0.2.2:8000/api';
    }
  }
}
