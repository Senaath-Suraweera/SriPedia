from django.urls import path
from . import views

urlpatterns = [
    path('', views.LeaderboardListView.as_view(), name='leaderboard-list'),
    path('rank/', views.UserRankView.as_view(), name='user-rank'),
]