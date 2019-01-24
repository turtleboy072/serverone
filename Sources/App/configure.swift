import FluentSQLite
import Vapor
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(LeafProvider())
    
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
     middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .sqlite)
    services.register(migrations)
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    let websockets = NIOWebSocketServer.default()
    var browserClient: WebSocket?
    var phoneClient: WebSocket?
    websockets.get("devicews") { ws, req in
        print("ws connnected")
        
        var pingTimer: DispatchSourceTimer? = nil
        pingTimer = DispatchSource.makeTimerSource()
        pingTimer?.schedule(deadline: .now(), repeating: .seconds(25))
        pingTimer?.setEventHandler { ws.send(Data()) }
        pingTimer?.resume()
        
        ws.onText { ws, text in
            if text == "im from website" {
                browserClient = ws
            } else if text == "im from device" {
                phoneClient = ws
                phoneClient?.send("sendImage")
            }
        }
        ws.onBinary({ (ws, data) in
            browserClient?.send(data)
            phoneClient?.send("sendImage")
        })
    }
    services.register(websockets, as: WebSocketServer.self)
}
