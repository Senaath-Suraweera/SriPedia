from django.shortcuts import render
from django.http import JsonResponse
from .models import TimelineEvent
from django.views import View
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .models import TimelineEvent, DailyUpdate
from .serializers import TimelineEventSerializer, DailyUpdateSerializer

class TimelineView(View):
    def get(self, request):
        events = TimelineEvent.objects.all().order_by('-date')
        data = [{"id": event.id, "title": event.title, "description": event.description, "date": event.date} for event in events]
        return JsonResponse(data, safe=False)

class TimelineDetailView(View):
    def get(self, request, event_id):
        try:
            event = TimelineEvent.objects.get(id=event_id)
            data = {
                "id": event.id,
                "title": event.title,
                "description": event.description,
                "date": event.date
            }
            return JsonResponse(data)
        except TimelineEvent.DoesNotExist:
            return JsonResponse({"error": "Event not found"}, status=404)

class TimelineEventListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    queryset = TimelineEvent.objects.all().order_by('date')
    serializer_class = TimelineEventSerializer

class TimelineEventDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    queryset = TimelineEvent.objects.all()
    serializer_class = TimelineEventSerializer

class DailyUpdateListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    queryset = DailyUpdate.objects.all().order_by('-created_at')
    serializer_class = DailyUpdateSerializer