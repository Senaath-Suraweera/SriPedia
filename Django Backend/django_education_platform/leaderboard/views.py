from django.shortcuts import render
from django.http import JsonResponse
from .models import LeaderboardEntry
from django.contrib.auth.decorators import login_required
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .serializers import LeaderboardEntrySerializer
from rest_framework import generics
from rest_framework.views import APIView
from django.db.models import Count

@login_required
def leaderboard_view(request):
    entries = LeaderboardEntry.objects.order_by('-score')[:10]  # Get top 10 entries
    data = {
        'leaderboard': [
            {
                'username': entry.user.username,
                'score': entry.score
            } for entry in entries
        ]
    }
    return JsonResponse(data)

@login_required
def user_score_view(request):
    user_entry = LeaderboardEntry.objects.filter(user=request.user).first()
    score = user_entry.score if user_entry else 0
    data = {
        'username': request.user.username,
        'score': score
    }
    return JsonResponse(data)

class LeaderboardListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = LeaderboardEntrySerializer
    queryset = LeaderboardEntry.objects.all().order_by('-total_points')[:10]

class UserRankView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        LeaderboardEntry.update_leaderboard()
        try:
            entry = LeaderboardEntry.objects.get(user=request.user)
            rank = LeaderboardEntry.objects.filter(
                total_points__gt=entry.total_points
            ).count() + 1
            return Response({
                'rank': rank,
                'total_points': entry.total_points
            })
        except LeaderboardEntry.DoesNotExist:
            return Response({'rank': 0, 'total_points': 0})