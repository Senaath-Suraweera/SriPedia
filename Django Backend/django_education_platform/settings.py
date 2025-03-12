# ...existing code...

INSTALLED_APPS += [
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'accounts',
    'quiz',
    'lessons',
    'timeline',
    'classroom',
]

MIDDLEWARE.insert(0, 'corsheaders.middleware.CorsMiddleware')

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    )
}

CORS_ALLOWED_ORIGINS = [
    "http://localhost:8000",  # Flutter web
    "http://localhost:3000",  # Flutter desktop
]

AUTH_USER_MODEL = 'accounts.User'

# ...existing code...