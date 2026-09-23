/// Stub for the Neon datasource.
///
/// The postgres package has been removed from this project as direct
/// client-to-PostgreSQL connections from a mobile app violate 3-tier security
/// architecture. This class is preserved as a placeholder.
///
/// To restore DB connectivity, implement a backend REST/GraphQL API and
/// replace this with an HTTP datasource (e.g., CatalogRemoteDataSource via Dio).
class CatalogNeonDataSource {
  // Intentionally empty — all data flows through CatalogMockDataSource or
  // a future CatalogRemoteDataSource (HTTP API layer).
}
