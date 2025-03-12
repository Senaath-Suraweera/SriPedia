from rest_framework import serializers
from .models import TimelineEvent, DailyUpdate

class TimelineEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = TimelineEvent
        fields = ['id', 'title', 'description', 'date', 'importance']

class DailyUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyUpdate
        fields = ['id', 'event', 'content', 'created_at']