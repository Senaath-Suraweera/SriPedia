from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, StudentProfile, TeacherProfile

class StudentProfileInline(admin.StackedInline):
    model = StudentProfile
    can_delete = False

class TeacherProfileInline(admin.StackedInline):
    model = TeacherProfile
    can_delete = False

class CustomUserAdmin(UserAdmin):
    list_display = ('username', 'email', 'user_type', 'points', 'is_staff')
    list_filter = ('user_type', 'is_staff', 'is_superuser')
    fieldsets = UserAdmin.fieldsets + (
        ('Custom Fields', {'fields': ('user_type', 'points')}),
    )
    inlines = [StudentProfileInline, TeacherProfileInline]

admin.site.register(User, CustomUserAdmin)
admin.site.register(StudentProfile)
admin.site.register(TeacherProfile)