from django.urls import path
from . import views
from django.views.generic import RedirectView
from django.contrib.auth.views import LogoutView

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('signup/', views.signup_view, name='signup'),
    path('logout/', views.logout_view, name='logout'),  # Now this should work
    path('', views.home_view, name='home'),
    path('chatbot/', views.chatbot_view, name='chatbot'),
    path('leaderboard/', views.leaderboard_view, name='leaderboard'),
    path('quiz/', views.daily_quiz_view, name='daily_quiz'),
    path('profile/', views.profile_view, name='profile'),
    path('generate-quiz/', views.generate_quiz_view, name='generate_quiz'),
    path('files/', views.user_files_view, name='user_files'),
    # Add the URL for file deletion
    path('delete-file/', views.delete_file_view, name='delete_file'),
    path('classrooms/', views.classroom_list_view, name='classroom_list'),
    path('classrooms/create/', views.create_classroom_view, name='create_classroom'),
    path('classrooms/join/', views.join_classroom_view, name='join_classroom'),
    path('classrooms/<int:classroom_id>/', views.classroom_detail_view, name='classroom_detail'),
    path('classrooms/<int:classroom_id>/leave/', views.leave_classroom_view, name='leave_classroom'),
]