# Reference data boundary

`FakeReferenceRepository` is the offline default. To connect an API, add a
Dio-backed implementation of `ReferenceRepository` in this directory, keep
wire models in DTOs, and map transport errors to the shared `Failure` types.

Select the new implementation by overriding `referenceRepositoryProvider` at
the application boundary. Domain and presentation code must continue to depend
only on `ReferenceRepository`; they do not need to change when the data source
changes.
