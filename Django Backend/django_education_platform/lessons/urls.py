from django.urls import path
from . import views

urlpatterns = [
    path('', views.LessonListView.as_view(), name='lesson-list'),
    path('<int:pk>/', views.LessonDetailView.as_view(), name='lesson-detail'),
    path('create/', views.create_lesson, name='lesson-create'),
    path('<int:pk>/update/', views.update_lesson, name='lesson-update'),
    path('<int:pk>/delete/', views.delete_lesson, name='lesson-delete'),
]