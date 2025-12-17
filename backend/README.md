# Netflix Clone Backend API

## Setup

1. Install dependencies:
```bash
cd backend
npm install
```

2. Copy environment file:
```bash
cp .env.example .env
```

3. Update `.env` with your database credentials

4. Run database migrations:
```bash
npm run migrate
```

5. Start the server:
```bash
npm run dev
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Users
- `GET /api/users/me` - Get current user (requires authentication)

## Docker Setup

Use `docker-compose.yml` in the root directory to run PostgreSQL and backend together.

