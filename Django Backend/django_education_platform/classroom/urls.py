from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'', views.ClassroomViewSet, basename='classroom')

classroom_sessions = views.SessionViewSet.as_view({
    'get': 'list',
    'post': 'create'
})

urlpatterns = [
    path('', include(router.urls)),
    path('<int:classroom_pk>/sessions/', classroom_sessions, name='classroom-sessions'),
    path('questions/<int:pk>/submit/', views.submit_answer, name='submit-answer'),
]