from django.urls import path
from . import views

urlpatterns = [
    path('daily/', views.get_daily_quiz, name='daily_quiz'),
    path('submit/', views.submit_answer, name='submit_answer'),
    path('progress/', views.get_progress, name='quiz_progress'),
]