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
- `src/app/features/` contains feature-local handlers, types, and repositories.
- `src/main.tx` stays thin and only starts the application.

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
- Generic modules: `src/modules/*`

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

The public client API is fetch-style:

```tx
import { fetch } from "./src/modules/http/index.tx";

let response = fetch("https://api.github.com/users/tejx");
```

Supported request config fields:
- `method`
- `body`
- `headers`
- `json`
- `insecureTls`

`http://` uses plain TCP. `https://` uses TLS from `std:net`.

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
- Feature code now lives beside its own types and repository logic under `src/app/features/`.
- `mongo_probe` is the quickest way to confirm direct Mongo connectivity and auth.
