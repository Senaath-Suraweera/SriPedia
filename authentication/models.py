from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver

class UserProfile(models.Model):
    # Role constants for easy reference
    STUDENT = 'student'
    TEACHER = 'teacher'
    
    ROLE_CHOICES = (
        (STUDENT, 'Student'),
        (TEACHER, 'Teacher'),
    )
    
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default=STUDENT)
    firebase_uid = models.CharField(max_length=128, blank=True, null=True)  # Store Firebase UID
    # Points field - if this is missing in your DB, uncomment and run migrations
    # points = models.IntegerField(default=0)  
    
    def __str__(self):
        return f"{self.user.username} ({self.role})"
    
    # Add a property to access joined_classrooms through the User model
    @property
    def joined_classrooms(self):
        return Classroom.objects.filter(students=self.user)

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """Create a UserProfile for every new User"""
    if created:
        UserProfile.objects.create(user=instance, role='student')

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """Save the UserProfile whenever the User is saved"""
    if hasattr(instance, 'userprofile'):
        instance.userprofile.save()
    else:
        # If for some reason the profile doesn't exist, create one
        UserProfile.objects.create(user=instance, role='student')

class Classroom(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    join_code = models.CharField(max_length=8, unique=True)
    teacher = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_classrooms')
    students = models.ManyToManyField(User, related_name='joined_classrooms', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name
    
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