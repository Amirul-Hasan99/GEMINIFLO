class AppConfig {
  /// If [useMockData] is true, repositories will use comprehensive in-memory
  /// and mock data services that accurately mimic the Laravel API contracts.
  /// When set to false, all requests route to [EnvConfig.baseUrl] via Dio.
  static bool useMockData = false;

  /// Whether to use direct Neon Serverless PostgreSQL Database
  static bool useNeonDb = true;

  /// Toggle between Mock Mode and Live API Mode
  static void setMockMode(bool enabled) {
    useMockData = enabled;
  }

  /// Toggle Neon Database usage
  static void setNeonDb(bool enabled) {
    useNeonDb = enabled;
  }
}
