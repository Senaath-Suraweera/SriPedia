from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from authentication.models import UserProfile, Classroom

class Command(BaseCommand):
    help = 'Check and fix classroom model relationships'

    def handle(self, *args, **options):
        self.stdout.write("Checking classroom models...")
        
        # Check UserProfile model
        profiles_count = UserProfile.objects.count()
        users_count = User.objects.count()
        self.stdout.write(f"Found {profiles_count} profiles for {users_count} users")
        
        # Create profiles for users that don't have one
        users_without_profiles = User.objects.filter(userprofile__isnull=True)
        for user in users_without_profiles:
            UserProfile.objects.create(user=user, role=UserProfile.STUDENT)
            self.stdout.write(f"Created profile for {user.username}")
        
        # Check Classroom model
        classrooms_count = Classroom.objects.count()
        self.stdout.write(f"Found {classrooms_count} classrooms")
        
        # Check if Classroom model has students field
        sample_classroom = Classroom.objects.first()
        if sample_classroom:
            try:
                students_count = sample_classroom.students.count()
                self.stdout.write(f"Sample classroom: {sample_classroom.name} has {students_count} students")
            except AttributeError:
                self.stdout.write(self.style.ERROR("Classroom model does not have 'students' field"))
                self.stdout.write(self.style.WARNING("You need to run migrations to fix this"))
        
        # Check classroom-student relationships
        for classroom in Classroom.objects.all():
            self.stdout.write(f"Classroom: {classroom.name}")
            self.stdout.write(f"  Teacher: {classroom.teacher.username}")
            try:
                students = classroom.students.all()
                self.stdout.write(f"  Students: {students.count()}")
            except AttributeError:
                self.stdout.write(self.style.ERROR("  Error: No students field"))
        
        self.stdout.write(self.style.SUCCESS("Check complete"))