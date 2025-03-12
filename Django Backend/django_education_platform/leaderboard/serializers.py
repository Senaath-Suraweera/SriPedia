from rest_framework import serializers
from .models import LeaderboardEntry

class LeaderboardEntrySerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = LeaderboardEntry
        fields = ['id', 'username', 'total_points', 'last_updated']
        read_only_fields = ['total_points', 'last_updated']