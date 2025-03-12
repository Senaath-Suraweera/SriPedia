from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    USER_TYPE_CHOICES = (
        ('student', 'Student'),
        ('teacher', 'Teacher'),
    )
    user_type = models.CharField(max_length=10, choices=USER_TYPE_CHOICES)
    points = models.IntegerField(default=0)

    def __str__(self):
        return f"{self.username} ({self.user_type})"

class StudentProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student_profile')
    grade = models.CharField(max_length=50, blank=True)
    completed_quizzes = models.ManyToManyField('quiz.DailyQuiz', blank=True)

    def __str__(self):
        return f"{self.user.username}'s Student Profile"

class TeacherProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='teacher_profile')
    subject = models.CharField(max_length=100, blank=True)
    qualifications = models.TextField(blank=True)

    def __str__(self):
        return f"{self.user.username}'s Teacher Profile"