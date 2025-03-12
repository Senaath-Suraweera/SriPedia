from django.db import models
from django.conf import settings

class Lesson(models.Model):
    title = models.CharField(max_length=200)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    teacher = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='lessons')
    order = models.IntegerField(default=0)  # Add this field

    class Meta:
        ordering = ['order', 'created_at']

    def __str__(self):
        return self.title

class LessonProgress(models.Model):
    student = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='lesson_progress')
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='progress')
    completed = models.BooleanField(default=False)
    score = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"{self.student.username} - {self.lesson.title} - {'Completed' if self.completed else 'Not Completed'}"