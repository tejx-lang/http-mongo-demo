# TejX REST API

A modular TejX REST API demo with:
- `http` for outbound fetch-style requests
- `server` for inbound HTTP handling
- `mongo` for direct MongoDB access over the wire protocol

## Project Structure

```text
├── build/                    # Compiled outputs from build.sh
├── examples/
│   ├── clients/
│   │   └── internal_client.tx
│   └── probes/
│       ├── https_probe.tx
│       ├── json_probe.tx
│       ├── mongo_probe.tx
│       └── verify_net.tx
├── src/
│   ├── app/
│   │   ├── config/
│   │   │   └── env.tx
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── events/
│   │   │   ├── external/
│   │   │   ├── meta/
│   │   │   ├── orders/
│   │   │   ├── products/
│   │   │   ├── reports/
│   │   │   └── users/
│   │   ├── router/
│   │   │   └── index.tx
│   │   └── server.tx
│   ├── main.tx
│   ├── modules/
│   │   ├── http/
│   │   ├── json/
│   │   ├── mongo/
│   │   └── server/
└── build.sh
```

Structure rules:
- `src/modules/` contains reusable generic building blocks.
- `src/app/core/` contains app runtime and persistence wiring.
- `src/app/features/` contains feature-local handlers, types, repositories, and public entrypoints.
- `src/main.tx` stays thin and only starts the application.
- Every reusable module is self-contained inside its own folder and exposed through that folder's `index.tx`.
- If you copy a module folder such as `src/modules/http` or `src/modules/mongo` into another TejX project, it does not depend on `src/app`.

## Getting Started

Prerequisites:
- TejX toolchain on `PATH`
- MongoDB running locally

Build and run:

```bash
./build.sh
./build/server
```

Code entrypoints:
- App bootstrap: `src/app/server.tx`
- Route dispatch: `src/app/router/index.tx`
- Generic modules: `src/modules/*/index.tx`
- Feature public APIs: `src/app/features/*/index.tx` and `src/app/features/*/routes.tx`

Public module entrypoints:
- `src/modules/http/index.tx`
- `src/modules/json/index.tx`
- `src/modules/mongo/index.tx`
- `src/modules/server/index.tx`
- `src/modules/errors/index.tx`

Run the example client:

```bash
./build/internal_client
```

Useful probes:

```bash
./build/https_probe
./build/json_probe
./build/mongo_probe
./build/verify_net
```

## HTTP Module

The public client API lives in `src/modules/http/index.tx`.

Public types and helpers:
- `HttpRequest`
- `HttpResponse`
- `createRequest(...)`
- `createHttpHeaders()`
- `createJsonRequestHeaders()`
- `copyHttpHeaders(...)`
- `fetch(...)`, `get(...)`, `post(...)`, `put(...)`, `patch(...)`, `deleteRequest(...)`

Example:

```tx
import { createRequest, fetch } from "./src/modules/http/index.tx";

let request = createRequest("GET");
let response = fetch("https://api.github.com/users/tejx", request);
```

`http://` uses plain TCP. `https://` uses TLS from `std:net`.

## Mongo Module

The public Mongo API also lives in `src/modules/mongo/index.tx`.

Public types and helpers:
- `MongoConnection`
- `MongoDatabase`
- `createMongoConnection(...)`
- `copyMongoConnection(...)`
- `connectMongo(...)`
- `warmMongoConnection(...)`

Example:

```tx
import { connectMongo, createMongoConnection } from "./src/modules/mongo/index.tx";

let connection = createMongoConnection(
    "",
    "127.0.0.1",
    27017,
    "rental-app",
    "root",
    "password123",
    "admin",
    "rs0"
);
let client = connectMongo(connection);
```

Internal transport/auth/BSON implementation stays inside the module folder. Callers only need the public API from `index.tx`.

## JSON Module

Use the JSON module through `src/modules/json/index.tx`:

```tx
import { parse, readString } from "./src/modules/json/index.tx";

let data = parse("{\"name\":\"tejx\"}");
let name = readString("{\"name\":\"tejx\"}", "name");
```

## API Routes

- `GET /`
- `GET /health`
- `POST /api/auth/login`
- `GET /api/users`
- `POST /api/users`
- `GET /api/users/:id`
- `PUT /api/users/:id`
- `DELETE /api/users/:id`
- `GET /api/products`
- `POST /api/products`
- `GET /api/products/:id`
- `PUT /api/products/:id`
- `DELETE /api/products/:id`
- `GET /api/orders`
- `POST /api/orders`
- `GET /api/orders/:id`
- `PUT /api/orders/:id`
- `DELETE /api/orders/:id`
- `GET /api/reports/summary`
- `GET /api/events`
- `GET /api/external`

## Configuration

Preferred Mongo config is a full connection string:

```bash
export MONGO_URL='mongodb://root:password123@localhost:27017/rental-app?replicaSet=rs0&authSource=admin'
```

Supported environment variables:
- `PORT` default `3000`
- `APP_BASE_URL` default `http://127.0.0.1:3000`
- `MONGO_URL` or `MONGO_URI` or `MONGODB_URI`
- `MONGO_HOST` default `127.0.0.1`
- `MONGO_PORT` default `27017`
- `MONGO_DATABASE` default `rental-app`
- `MONGO_USERNAME` or `MONGO_USER` default `root`
- `MONGO_PASSWORD` default `password123`
- `MONGO_AUTH_SOURCE` default `admin`
- `MONGO_REPLICA_SET` default `rs0`

## Notes

- The app is Mongo-only now; old file-backed storage and seed flow were removed.
- The database bootstrap creates or refreshes the `app_meta` document as needed.
- Each feature owns its own collection serializers and module entrypoints under `src/app/features/`.
- Outside code should import `index.tx` or `routes.tx` from a feature instead of reaching into its internals.
- Outside code should import reusable modules only through `src/modules/*/index.tx`.
- `mongo_probe` is the quickest way to confirm direct Mongo connectivity and auth.
