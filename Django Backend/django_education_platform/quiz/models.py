from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import datetime
from django.conf import settings

class Quiz(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

class DailyQuiz(models.Model):
    date = models.DateField(default=timezone.now, unique=True)
    is_active = models.BooleanField(default=True)
    total_questions = models.IntegerField(default=10)

    def __str__(self):
        return f"Quiz for {self.date}"

    @property
    def is_available(self):
        return self.date == timezone.now().date() and self.is_active

class Question(models.Model):
    quiz = models.ForeignKey(Quiz, related_name='questions', on_delete=models.CASCADE)
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.text

class Answer(models.Model):
    question = models.ForeignKey(Question, related_name='answers', on_delete=models.CASCADE)
    text = models.CharField(max_length=200)
    is_correct = models.BooleanField(default=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='quiz_answers')

    def __str__(self):
        return f"{self.text} - {'Correct' if self.is_correct else 'Incorrect'}"

class QuizAttempt(models.Model):
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE)
    quiz = models.ForeignKey(DailyQuiz, on_delete=models.CASCADE)
    current_question = models.IntegerField(default=1)
    completed = models.BooleanField(default=False)
    score = models.IntegerField(default=0)
    attempt_date = models.DateTimeField(auto_now_add=True)
    retry_count = models.IntegerField(default=0)

    class Meta:
        unique_together = ['user', 'quiz']