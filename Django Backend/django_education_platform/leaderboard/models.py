from django.db import models
from django.db.models import Sum
from django.conf import settings

class LeaderboardEntry(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    total_points = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = 'Leaderboard entries'
        ordering = ['-total_points']

    def __str__(self):
        return f"{self.user.username} - {self.total_points} points"

    @classmethod
    def update_leaderboard(cls):
        users = settings.AUTH_USER_MODEL.objects.filter(user_type='student').annotate(
            total=Sum('points')
        )
        for user in users:
            cls.objects.update_or_create(
                user=user,
                defaults={'total_points': user.total or 0}
            )