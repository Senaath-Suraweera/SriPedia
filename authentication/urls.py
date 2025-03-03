from django.urls import path
from . import views
from django.views.generic import RedirectView
from django.contrib.auth.views import LogoutView

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('signup/', views.signup_view, name='signup'),
    path('home/', views.home_view, name='home'),
    path('chatbot/', views.chatbot_view, name='chatbot'),
    path('leaderboard/', views.leaderboard_view, name='leaderboard'),
    path('quiz/', views.daily_quiz_view, name='daily_quiz'),
    path('profile/', views.profile_view, name='profile'),
    path('logout/', LogoutView.as_view(next_page='login'), name='logout'),
    path('generate-quiz/', views.generate_quiz_view, name='generate_quiz'),
    path('files/', views.user_files_view, name='user_files'),
    # Add the URL for file deletion
    path('delete-file/', views.delete_file_view, name='delete_file'),
    path('', RedirectView.as_view(url='login/', permanent=False), name='auth_root'),
]