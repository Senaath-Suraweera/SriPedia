from django.db import models
import uuid
from django.conf import settings

class Classroom(models.Model):
    name = models.CharField(max_length=100)
    unique_id = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    teacher = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='teaching_classrooms')
    students = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='enrolled_classrooms', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class ClassSession(models.Model):
    classroom = models.ForeignKey(Classroom, on_delete=models.CASCADE, related_name='sessions')
    title = models.CharField(max_length=200)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    is_active = models.BooleanField(default=True)

class SessionQuestion(models.Model):
    session = models.ForeignKey(ClassSession, on_delete=models.CASCADE, related_name='questions')
    question_text = models.TextField()
    correct_answer = models.CharField(max_length=200)
    options = models.JSONField()  # Store multiple choice options

class StudentResponse(models.Model):
    student = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    question = models.ForeignKey(SessionQuestion, on_delete=models.CASCADE)
    answer = models.CharField(max_length=200)
    is_correct = models.BooleanField()
    response_time = models.DateTimeField(auto_now_add=True)