# Release

CI quality checks run on push and pull request. Release and deployment workflows are generated as manual workflows.

All generated workflows pin Flutter 3.44.8. Update the pin only after the
generator repository's Android and macOS iOS quality gates pass on the new
Flutter patch release.

## GitHub Secrets

The generated workflows contain secret references only. Credential values,
keystores, certificates, provisioning profiles, and private keys must remain in
the repository's encrypted secret store and must never be committed to config or
workflow files.

Android signing:

```txt
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

iOS signing and TestFlight:

```txt
APP_STORE_CONNECT_API_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_PRIVATE_KEY
IOS_CERTIFICATE_BASE64
IOS_CERTIFICATE_PASSWORD
IOS_PROVISIONING_PROFILE_BASE64
APPLE_TEAM_ID
```

## Workflows

- `flutter_ci.yml`: format, analyze, unit/widget tests.
- `integration_tests.yml`: manual Android emulator integration tests.
- `android_release.yml`: manual Android release build.
- `ios_build.yml`: manual iOS build.
- `deploy_android.yml`: manual Play Console internal track deployment.
- `deploy_ios.yml`: manual TestFlight deployment.

Release workflows are intentionally manual so a new project does not fail CI before signing and store credentials are configured.
