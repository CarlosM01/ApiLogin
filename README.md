# Login API

A robust FastAPI-based backend for user authentication and management. This API provides endpoints for user registration, listing, updating, and secure login, integrated with a PostgreSQL database.

## 🚀 Quick Start

Configure the entire environment (venv, .env, dependencies, and Docker build) with a single command:

```bash
make setup
```

## 🛠️ Development

### Local Execution
To run the API locally using Uvicorn:

```bash
make run
# or with hot-reload
make dev
```

The API will be available at [http://localhost:8000](http://localhost:8000).

### Docker Execution
To run the API using Docker Compose:

```bash
make up
```

To view logs:
```bash
make logs
```

To stop the containers:
```bash
make down
```

## 📖 API Documentation

Once the server is running, you can access the interactive API documentation:

- **Swagger UI**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

## 📡 Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/users` | Create a new user account |
| `GET` | `/users` | List all registered users |
| `GET` | `/users/{id}` | Retrieve details for a specific user |
| `PATCH` | `/users/{id}` | Update user information |
| `DELETE` | `/users/{id}` | Delete a user account |
| `POST` | `/login` | Authenticate and login |

## ⚙️ Configuration

The API is configured via environment variables. Copy `.env.example` to `.env` (automatically handled by `make setup`) and adjust as needed:

- `DATABASE_URL`: Connection string for PostgreSQL.
- `SSH_*`: Configuration for the optional SSH tunnel.

## 🧹 Code Quality

Run linting and formatting checks:

```bash
make lint
make format
```
