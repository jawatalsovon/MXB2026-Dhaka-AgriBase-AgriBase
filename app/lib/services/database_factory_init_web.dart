// Web initialization: sqflite handles web databases automatically
// No explicit initialization needed for web platform
class DatabaseFactoryInitializer {
  static void initialize() {
    // On web, sqflite uses the default factory which works with browser storage
    // The sqlite3.wasm binary handles the database operations
    // No explicit FFI initialization needed
  }
}
