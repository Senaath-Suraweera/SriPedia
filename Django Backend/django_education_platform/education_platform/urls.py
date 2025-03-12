from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/quiz/', include('quiz.urls')),
    path('api/lessons/', include('lessons.urls')),
    path('api/timeline/', include('timeline.urls')),
    path('api/classroom/', include('classroom.urls')),
    path('api/leaderboard/', include('leaderboard.urls')),
]