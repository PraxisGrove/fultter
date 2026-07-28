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

Android signing and Play Console deployment:

```txt
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

## Workflows

- `flutter_ci.yml`: format, analyze, unit/widget tests.
- `deploy_android.yml`: manual Play Console internal track deployment.
- `ios_build.yml`: manual unsigned iOS release build. Add signing and App Store
  Connect upload only when the project has an approved distribution setup.

Release workflows are intentionally manual so a new project does not fail CI before signing and store credentials are configured.
