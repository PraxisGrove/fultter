# Authentication

The generated app includes backend-neutral session state and route protection.
It does not include an identity provider or backend authorization policy.

## State and credentials

`AuthController` publishes four states: loading, unauthenticated,
authenticated, and session expired. Credential operations are serialized so a
late storage operation cannot overwrite a newer user action.

`AuthCredentialStore` reads, writes, and clears one opaque credential.
`SecureAuthCredentialStore` implements that contract through the shared
`SecureStorage` abstraction. Replace the credential-store provider if your
backend requires a different credential shape or lifecycle; keep provider SDKs
outside the domain contract.

Call `AuthController.authenticate` only after the backend or identity boundary
has established a valid session. Call `signOut` for user-initiated removal and
`expireSession` when the networking boundary reports an expired session. Both
paths clear secure storage before routing settles on an unauthenticated screen.

## Routes

The reference router demonstrates:

- `/public`, which is available in every auth state
- `/sign-in`, the public entry route
- `/loading`, the session restoration route
- `/` and `/protected/:section`, protected routes

Protected deep links are carried through the entry route in the `from` query
parameter. Only local protected paths are accepted as return locations, which
prevents external redirects and entry/loading loops.

Route visibility is a client navigation concern. Enforce permissions and
authorization on the backend.
