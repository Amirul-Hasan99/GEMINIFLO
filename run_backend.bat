@echo off
setlocal
if "%NEON_DATABASE_URL%"postgresql://neondb_owner:npg_An3OriHysUC0@ep-snowy-haze-at8e3hc2-pooler.c-9.us-east-1.aws.neon.tech/GEMINIFLO?sslmode=require&channel_binding=require"" (
  echo NEON_DATABASE_URL belum diatur pada environment.
  exit /b 1
)
dart run backend/server.dart --host 0.0.0.0 --port 8000
