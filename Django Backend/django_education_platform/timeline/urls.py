from django.urls import path
from . import views

urlpatterns = [
    path('', views.TimelineEventListView.as_view(), name='timeline-list'),
    path('<int:pk>/', views.TimelineEventDetailView.as_view(), name='timeline-detail'),
    path('updates/', views.DailyUpdateListView.as_view(), name='daily-updates'),
]