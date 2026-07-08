enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment parse(String value) {
    return switch (value) {
      'dev' => AppEnvironment.dev,
      'staging' => AppEnvironment.staging,
      'prod' => AppEnvironment.prod,
      _ => AppEnvironment.dev,
    };
  }
}
