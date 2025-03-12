from django.test import TestCase
from .models import TimelineEvent

class TimelineEventTests(TestCase):

    def setUp(self):
        TimelineEvent.objects.create(title="Event 1", description="Description for event 1", date="2023-01-01")
        TimelineEvent.objects.create(title="Event 2", description="Description for event 2", date="2023-02-01")

    def test_timeline_event_creation(self):
        event = TimelineEvent.objects.get(title="Event 1")
        self.assertEqual(event.description, "Description for event 1")
        self.assertEqual(event.date, "2023-01-01")

    def test_timeline_event_list(self):
        events = TimelineEvent.objects.all()
        self.assertEqual(events.count(), 2)

    def test_timeline_event_str(self):
        event = TimelineEvent.objects.get(title="Event 1")
        self.assertEqual(str(event), "Event 1")