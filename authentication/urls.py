from django.urls import path, include
from . import views
from . import api
from django.views.generic import RedirectView
from django.contrib.auth.views import LogoutView
from rest_framework.routers import DefaultRouter

from . import classroom_api

router = DefaultRouter()
router.register(r'users', api.UserViewSet)
router.register(r'classrooms', classroom_api.ClassroomViewSet, basename='classroom')

# Create nested routes for classroom quizzes
classroom_router = DefaultRouter()
classroom_router.register(r'quizzes', classroom_api.ClassroomQuizViewSet, basename='classroom-quiz')

urlpatterns = [
    # Make sure you have a login view defined
    path('login/', views.login_view, name='login'),
    path('signup/', views.firebase_signup_view, name='signup'),
    path('logout/', views.firebase_logout_view, name='logout'),
    path('', views.dashboard_view, name='home'),
    path('home/', views.home_view, name='home_page'),  # For /auth/home/
    path('chatbot/', views.chatbot_view, name='chatbot'),
    path('leaderboard/', views.leaderboard_view, name='leaderboard'),
    path('quiz/', views.daily_quiz_view, name='daily_quiz'),
    path('profile/', views.profile_view, name='profile'),
    path('generate-quiz/', views.generate_quiz_view, name='generate_quiz'),
    path('files/', views.user_files_view, name='user_files'),
    # Add the URL for file deletion
    path('delete-file/', views.delete_file_view, name='delete_file'),
<<<<<<< Updated upstream
    path('classrooms/', views.classroom_list_view, name='classroom_list'),
    path('classrooms/create/', views.create_classroom_view, name='create_classroom'),
    path('classrooms/join/', views.join_classroom_view, name='join_classroom'),
    path('classrooms/<int:classroom_id>/', views.classroom_detail_view, name='classroom_detail'),
    path('classrooms/<int:classroom_id>/leave/', views.leave_classroom_view, name='leave_classroom'),
    path('classrooms/<int:classroom_id>/edit/', views.edit_classroom_view, name='edit_classroom'),
    path('classrooms/<int:classroom_id>/regenerate-code/', views.regenerate_join_code_view, name='regenerate_join_code'),
    path('classrooms/<int:classroom_id>/remove-student/<int:student_id>/', views.remove_student_view, name='remove_student'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
=======
    path('', RedirectView.as_view(url='login/', permanent=False), name='auth_root'),
    path('quiz/submit/', views.submit_quiz_view, name='submit_quiz'),

    # Classroom URLs
    path('classrooms/', views.classroom_list, name='classroom_list'),
    path('classrooms/create/', views.classroom_create, name='classroom_create'),
    path('classrooms/<uuid:classroom_id>/', views.classroom_detail, name='classroom_detail'),
    path('classrooms/<uuid:classroom_id>/edit/', views.classroom_edit, name='classroom_edit'),
    path('classrooms/<uuid:classroom_id>/delete/', views.classroom_delete, name='classroom_delete'),
    path('classrooms/<uuid:classroom_id>/students/', views.classroom_students, name='classroom_students'),
    path('classrooms/<uuid:classroom_id>/materials/', views.classroom_materials, name='classroom_materials'),
    path('classrooms/<uuid:classroom_id>/materials/upload/', views.upload_material, name='upload_material'),
    path('classrooms/join/', views.join_classroom, name='join_classroom'),
    path('classrooms/<uuid:classroom_id>/materials/<int:material_id>/delete/', views.delete_material_view, name='delete_material'),
    
    # Quiz URLs
    path('classrooms/<uuid:classroom_id>/quizzes/', views.classroom_quizzes, name='classroom_quizzes'),
    path('classrooms/<uuid:classroom_id>/quizzes/create/', views.create_quiz, name='create_quiz'),
    path('classrooms/<uuid:classroom_id>/quizzes/<int:quiz_id>/', views.quiz_detail, name='quiz_detail'),
    path('classrooms/<uuid:classroom_id>/quizzes/<int:quiz_id>/edit/', views.edit_quiz, name='edit_quiz'),
    path('classrooms/<uuid:classroom_id>/quizzes/<int:quiz_id>/delete/', views.delete_quiz, name='delete_quiz'),
    path('classrooms/<uuid:classroom_id>/quizzes/<int:quiz_id>/take/', views.take_quiz, name='take_quiz'),
    path('classrooms/<uuid:classroom_id>/quizzes/<int:quiz_id>/submit/', views.submit_quiz_view_classroom, name='submit_quiz_view_classroom'),
    path('classrooms/<uuid:classroom_id>/quizzes/<int:quiz_id>/results/', views.quiz_results_view, name='quiz_results'),

    path('historical-timeline/', views.historical_timeline, name='historical_timeline'),
    path('api/events-for-year/<int:year>/', views.get_events_for_year, name='events_for_year'),


    path('api/login/', api.api_login, name='api_login'),
    path('api/signup/', api.api_signup, name='api_signup'),
    path('api/profile/', api.api_user_profile, name='api_profile'),
    path('api/classrooms/join/', classroom_api.join_classroom_api, name='join-classroom-api'),
    path('api/quizzes/<int:quiz_id>/submit/', classroom_api.submit_quiz_api, name='submit-quiz-api'),
    path('api/', include(router.urls)),
    path('api/classrooms/<uuid:classroom_id>/', include(classroom_router.urls)),
>>>>>>> Stashed changes
]