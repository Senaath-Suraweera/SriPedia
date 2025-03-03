from django.contrib import admin
from .models import UserProfile  # Change CustomUser to UserProfile

# Register your models here
admin.site.register(UserProfile)