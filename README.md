# TejX HTTP + Mongo Demo

This repository is a small REST API built in TejX. It shows how to:

- boot an app from a thin `src/main.tx`
- serve HTTP requests through a reusable `server` module
- talk to MongoDB directly through a reusable `mongo` module
- keep app-specific helpers inside `src/app`
- keep module-internal helpers inside each module folder

The app is a rental-style demo with users, products, orders, events, reports, login, and one outbound HTTP example.

## What Is In This Codebase

There are two main layers.

### 1. Reusable modules

- `src/modules/server/`
  A lightweight HTTP server and router. It owns request parsing, route matching, path params, method checks, JSON responses, and route logging.
- `src/modules/mongo/`
  A direct MongoDB client implemented over the wire protocol. It owns BSON encoding/decoding, SCRAM auth, and command execution.

These module folders are self-contained. The app does not leak into them.

### 2. App layer

- `src/app/server.tx`
  Bootstraps config, connects to Mongo, loads app state, initializes the router, and starts listening.
- `src/app/router/`
  Connects HTTP routes to feature handlers.
- `src/app/features/`
  Business features such as users, products, orders, auth, reports, events, and external fetch.
- `src/app/core/`
  Shared app-only helpers for persistence, IDs, response helpers, store updates, and state.
- `src/app/helpers/json.tx`
  App-local typed JSON helper used only by app code.

## Runtime Model

At startup the app:

1. Resolves environment/config values.
2. Opens a Mongo connection.
3. Authenticates the Mongo session.
4. Loads users, products, orders, and events into one in-memory `AppState`.
5. Starts the HTTP server and routes all requests through that shared runtime state.

On writes, the app updates:

- the in-memory state
- MongoDB
- the event log

This means reads are served from the loaded runtime state, while writes keep Mongo and memory in sync.

## Project Layout

```text
.
├── build.sh
├── examples/
│   ├── clients/
│   │   └── internal_client.tx
│   └── probes/
│       ├── https_probe.tx
│       ├── json_probe.tx
│       ├── mongo_probe.tx
│       └── verify_net.tx
├── src/
│   ├── main.tx
│   ├── app/
│   │   ├── config/
│   │   │   └── env.tx
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── events/
│   │   │   ├── external/
│   │   │   ├── orders/
│   │   │   ├── products/
│   │   │   ├── reports/
│   │   │   ├── search/
│   │   │   └── users/
│   │   ├── helpers/
│   │   │   └── json.tx
│   │   ├── router/
│   │   ├── runtime/
│   │   └── server.tx
│   └── modules/
│       ├── mongo/
│       └── server/
└── README.md
```

## Important Entry Points

- `src/main.tx`
  Process entrypoint. It only calls `runApplication()`.
- `src/app/server.tx`
  Main bootstrap flow.
- `src/app/router/index.tx`
  Full route registration.
- `src/app/router/handlers.tx`
  Bridges route contexts into feature handlers.
- `src/modules/server/index.tx`
  HTTP server, router, route params, JSON response helpers, and logging.
- `src/modules/mongo/index.tx`
  Public Mongo module surface.

## Build And Run

Prerequisites:

- `tejxc` available on `PATH`, or installed at `~/.tejx/bin/tejxc`
- MongoDB reachable locally or via a URI

Build the server:

```bash
./build.sh
```

Run the server:

```bash
./build/server
```

## Configuration

Preferred Mongo setup is a single URI:

```bash
export MONGO_URL='mongodb://root:password123@localhost:27017/demo?replicaSet=rs0&authSource=admin'
```

Supported environment variables:

| Variable                                  | Purpose                                  | Default                   |
| ----------------------------------------- | ---------------------------------------- | ------------------------- |
| `PORT`                                    | HTTP listen port                         | `3000`                    |
| `APP_BASE_URL`                            | Public base URL used for startup display | `http://127.0.0.1:<PORT>` |
| `MONGO_URL` / `MONGO_URI` / `MONGODB_URI` | Full Mongo connection string             | unset                     |
| `MONGO_HOST`                              | Mongo host when not using a URI          | `127.0.0.1`               |
| `MONGO_PORT`                              | Mongo port when not using a URI          | `27017`                   |
| `MONGO_DATABASE`                          | Logical database name                    | `demo`                    |
| `MONGO_USERNAME` / `MONGO_USER`           | Mongo username                           | `root`                    |
| `MONGO_PASSWORD`                          | Mongo password                           | `password123`             |
| `MONGO_AUTH_SOURCE`                       | Auth database                            | `admin`                   |
| `MONGO_REPLICA_SET`                       | Replica set name                         | `rs0`                     |

## HTTP And Data Conventions

- All API responses are JSON.
- Item timestamps such as `createdAt` are epoch milliseconds.
- Generated IDs use a prefix-based format such as `user-<timestamp>-<n>`.
- Collection endpoints return a normalized shape:

```json
{
  "count": 2,
  "ids": ["user-1", "user-2"],
  "items": {
    "user-1": { "...": "..." },
    "user-2": { "...": "..." }
  }
}
```

- Most app-level errors return:

```json
{
  "error": "message"
}
```

- Router-level method mismatches return:

```json
{
  "error": "Method not allowed",
  "allowed": ["GET", "POST"]
}
```

- Route misses return:

```json
{
  "error": "Route not found"
}
```

## API Reference

### Root And Diagnostics

#### `GET /`

Returns a welcome document with the top-level API list.

Response shape:

```json
{
  "message": "Welcome to TejX REST API",
  "version": "1.0.0",
  "endpoints": [
    "/health",
    "/api/auth/login",
    "/api/users",
    "/api/products",
    "/api/orders",
    "/api/reports/summary",
    "/api/events",
    "/api/external"
  ]
}
```

#### `GET /health`

Returns a lightweight liveness document.

Response shape:

```json
{
  "status": "ok",
  "service": "tejx-http-mongo-demo",
  "storage": "mongodb://root:***@127.0.0.1:27017/demo?authSource=admin&replicaSet=rs0",
  "counts": {
    "users": 0,
    "products": 0,
    "orders": 0,
    "events": 0
  }
}
```

#### `GET /api/reports/summary`

Returns a live summary of the loaded app state.

Response shape:

```json
{
  "summary": {
    "users": 0,
    "products": 0,
    "orders": 0,
    "events": 0,
    "revenue": 0.0,
    "lowStock": {
      "count": 0,
      "ids": [],
      "items": {}
    }
  },
  "storage": "mongodb://root:***@127.0.0.1:27017/demo?authSource=admin&replicaSet=rs0"
}
```

#### `GET /api/search?q=<text>`

Performs a simple in-memory substring search across users, products, orders, and events.

Response:

```json
{
  "query": "alice",
  "count": 1,
  "users": {
    "count": 1,
    "ids": ["user-..."],
    "items": {
      "user-...": {
        "id": "user-...",
        "name": "Alice",
        "email": "alice@example.com",
        "role": "customer",
        "createdAt": 0
      }
    }
  },
  "products": {
    "count": 0,
    "ids": [],
    "items": {}
  },
  "orders": {
    "count": 0,
    "ids": [],
    "items": {}
  },
  "events": {
    "count": 0,
    "ids": [],
    "items": {}
  }
}
```

Status: `200`

#### `GET /api/external`

Fetches `https://dummyjson.com/products/1` with built-in `fetchSync(...)` and returns the upstream JSON body.

If the upstream call fails, the endpoint still returns a demo fallback payload:

```json
{
  "id": 1,
  "title": "Fallback Demo Product",
  "description": "Static fallback returned because the upstream request failed",
  "price": 99.99,
  "category": "demo",
  "source": "fallback",
  "upstreamAvailable": false,
  "upstreamError": "..."
}
```

### Auth

#### `POST /api/auth/login`

Validates a user by matching the in-memory user collection on `email` and `password`.

Request body:

```json
{
  "email": "alice@example.com",
  "password": "secret"
}
```

Success response:

```json
{
  "token": "token-user-...-...",
  "user": {
    "id": "user-...",
    "name": "Alice",
    "email": "alice@example.com",
    "role": "customer",
    "createdAt": 0
  }
}
```

Common failures:

- `400` if the body is missing or invalid JSON
- `400` if `email` or `password` is empty
- `401` for invalid credentials

### Users

#### `GET /api/users`

Returns all users as a collection view.

User item shape:

```json
{
  "id": "user-...",
  "name": "Alice",
  "email": "alice@example.com",
  "role": "customer",
  "createdAt": 0
}
```

#### `POST /api/users`

Creates a user and records an event.

Request body:

```json
{
  "name": "Alice",
  "email": "alice@example.com",
  "password": "secret",
  "role": "customer"
}
```

Notes:

- `role` defaults to `customer`
- response does not include the password

Common failures:

- `400` if `name`, `email`, or `password` is missing
- `400` for invalid JSON
- `409` if the email already exists

#### `GET /api/users/:userId`

Returns one user view.

#### `PUT /api/users/:userId`

Updates any provided user fields.

Allowed body fields:

```json
{
  "name": "Alice Updated",
  "email": "alice.updated@example.com",
  "role": "admin",
  "password": "new-secret"
}
```

Common failures:

- `404` if the user does not exist
- `409` if the new email already belongs to another user
- `400` for invalid JSON

#### `DELETE /api/users/:userId`

Deletes a user and records an event.

Response:

```json
{
  "deleted": true,
  "id": "user-..."
}
```

Constraint:

- returns `409` if the user still owns orders

### Products

#### `GET /api/products`

Returns all products as a collection view.

Product item shape:

```json
{
  "id": "product-...",
  "name": "Keyboard",
  "price": 1299.0,
  "stock": 5,
  "category": "accessories",
  "createdAt": 0
}
```

#### `POST /api/products`

Creates a product and records an event.

Request body:

```json
{
  "name": "Keyboard",
  "price": 1299.0,
  "stock": 5,
  "category": "accessories"
}
```

Notes:

- `category` defaults to `misc`
- `stock` defaults to `0`

Common failures:

- `400` if `name` or `price` is missing
- `400` for invalid JSON

#### `GET /api/products/:productId`

Returns one product view.

#### `PUT /api/products/:productId`

Updates any provided product fields.

Allowed body fields:

```json
{
  "name": "Keyboard Pro",
  "price": 1499.0,
  "stock": 3,
  "category": "accessories"
}
```

#### `DELETE /api/products/:productId`

Deletes a product and records an event.

Response:

```json
{
  "deleted": true,
  "id": "product-..."
}
```

Constraint:

- returns `409` if the product already appears in an order

### Orders

#### `GET /api/orders`

Returns all orders as a collection view.

Order item shape:

```json
{
  "id": "order-...",
  "userId": "user-...",
  "productIds": ["product-1", "product-2"],
  "total": 2598.0,
  "status": "pending",
  "createdAt": 0
}
```

#### `POST /api/orders`

Creates an order and records an event.

Request body:

```json
{
  "userId": "user-...",
  "productIds": ["product-1", "product-2"],
  "status": "pending"
}
```

Notes:

- `status` defaults to `pending`
- `total` is calculated from the referenced product prices

Common failures:

- `400` if `userId` or `productIds` is missing
- `404` if the user does not exist
- `404` if any product ID does not exist
- `400` for invalid JSON

#### `GET /api/orders/:orderId`

Returns one order view.

#### `PUT /api/orders/:orderId`

Only updates the order status.

Request body:

```json
{
  "status": "paid"
}
```

Common failures:

- `400` if `status` is missing or empty
- `400` for invalid JSON
- `404` if the order does not exist

#### `DELETE /api/orders/:orderId`

Deletes an order and records an event.

Response:

```json
{
  "deleted": true,
  "id": "order-..."
}
```

### Events

#### `GET /api/events`

Read-only audit trail of app mutations.

Event item shape:

```json
{
  "id": "event-...",
  "action": "created",
  "entity": "user",
  "entityId": "user-...",
  "createdAt": 0
}
```

Events are appended automatically for:

- user create, update, delete
- product create, update, delete
- order create, update, delete

### Common Status Codes

- `200` successful read or update
- `201` resource created
- `400` invalid JSON or missing required fields
- `401` invalid login
- `404` resource or route not found
- `405` method not allowed
- `409` business rule conflict
- `500` unexpected internal failure

## Module Notes

### `server` module

`src/modules/server/index.tx` provides:

- raw HTTP request parsing
- `ServerRequest` and `ServerResponse`
- JSON/text response helpers
- route tree matching with path params
- method-aware routing with `405` handling
- request logging

### `mongo` module

`src/modules/mongo/index.tx` is the public Mongo entrypoint.

Internally it owns:

- connection string parsing and config mapping
- BSON encoding and decoding
- SCRAM-SHA-256 authentication
- OP_MSG command framing
- direct socket-based Mongo communication

The Mongo module returns plain values across its public boundary. App-specific JSON wrapping stays in `src/app`.

## Built-In HTTP Client

Outbound HTTP calls use the language runtime directly through built-in `fetchSync(...)` or `fetch(...)`.

Example:

```tx
let response = fetchSync("https://dummyjson.com/products/1", {
    timeoutMs: 10000
});
```

There is no custom HTTP client module in this app anymore.

## Notes

- The app is Mongo-only. Old file-backed storage is removed.
- `GET /health` is a shallow liveness and cache summary endpoint.
- `GET /api/search` searches the currently loaded in-memory state.
- `build.sh` auto-detects the sibling `../tejx-lang` toolchain when it exists.
