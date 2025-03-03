from django.db import models
from django.contrib.auth.models import User

class UserProfile(models.Model):
    STUDENT = 'student'
    TEACHER = 'teacher'
    
    ROLE_CHOICES = [
        (STUDENT, 'Student'),
        (TEACHER, 'Teacher'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default=STUDENT)
    
    def __str__(self):
        return f"{self.user.username} ({self.role})"

class Classroom(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    join_code = models.CharField(max_length=10, unique=True)
    teacher = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_classrooms')
    students = models.ManyToManyField(User, related_name='joined_classrooms', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.name} (by {self.teacher.username})"
    
    def student_count(self):
        return self.students.count()

def register(request):
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            # Process form as before
            pass
        else:
            # Print errors to see what's causing the issue
            print(f"Form errors: {form.errors}")
            print(f"Role field errors: {form.errors.get('role', 'No role errors')}")
            print(f"Submitted data: {request.POST}")
    # Rest of the view code