# Django REST API - User Management

A simple REST API implementation for managing user data built with Django REST Framework.

## Features

- RESTful API for CRUD operations on User entity
- PostgreSQL database integration
- Docker containerization
- API Documentation with Swagger/ReDoc
- ORM migrations

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET    | /api/users/ | List all users |
| POST   | /api/users/ | Create a new user |
| GET    | /api/users/{id}/ | Get a specific user |
| PUT    | /api/users/{id}/ | Update a specific user |
| PATCH  | /api/users/{id}/ | Partially update a specific user |
| DELETE | /api/users/{id}/ | Delete a specific user |

## API Documentation

- Swagger UI: `/swagger/`
- ReDoc: `/redoc/`

## Setup and Running

### Prerequisites
- Docker and Docker Compose

### Running with Docker

1. Clone the repository
2. Navigate to the project directory
3. Create a `.env` file with required environment variables (see example below)
4. Build and run the application:
   ```
   docker-compose up -d --build
   ```
5. Run migrations (with --noinput for automated setups):
   ```
   docker-compose exec web python manage.py migrate --noinput
   ```
   
   Or for interactive mode:
   ```
   docker-compose exec web python manage.py migrate
   ```
6. Create a superuser (optional):
   ```
   docker-compose exec web python manage.py createsuperuser
   ```

### Environment Variables

Create a `.env` file in the project root with these variables:

```
DEBUG=True
SECRET_KEY=your-secret-key
DB_NAME=users
DB_USER=mohamed
DB_PASSWORD=2003
DB_HOST=db
DB_PORT=5432
ALLOWED_HOSTS=[*]
```

## Project Structure

```
api_project/
│
├── core/                   # Django project settings
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
│
├── users/                  # Users app
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── migrations/
│   ├── models.py
│   ├── serializers.py
│   ├── urls.py
│   └── views.py
│
├── nginx/                  # Nginx configuration
│   └── conf.d/
│       └── default.conf
│
├── .env                    # Environment variables
├── Dockerfile              # Docker configuration for Django app
├── docker-compose.yml      # Docker compose configuration
├── init_app.sh             # Initialization script
├── manage.py               # Django management script
└── requirements.txt        # Python dependencies
```

## Technology Stack

- **Django**: Web framework
- **Django REST Framework**: RESTful API toolkit
- **PostgreSQL**: Database
- **Gunicorn**: WSGI HTTP Server
- **Nginx**: Web server and reverse proxy
- **Docker & Docker Compose**: Containerization
- **drf-yasg**: Swagger/ReDoc API documentation
