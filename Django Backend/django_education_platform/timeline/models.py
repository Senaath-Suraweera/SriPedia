from django.db import models
from django.conf import settings

class TimelineEvent(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    description = models.TextField()
    date = models.DateField()
    importance = models.IntegerField(default=1)
    
    class Meta:
        ordering = ['date']

    def __str__(self):
        return f"{self.title} ({self.date})"

class DailyUpdate(models.Model):
    event = models.ForeignKey(TimelineEvent, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Update for {self.event.title} on {self.created_at}"