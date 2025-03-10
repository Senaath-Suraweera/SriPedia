from django.core.management.base import BaseCommand
from django.apps import apps

class Command(BaseCommand):
    help = 'Inspect model structure in the database'

    def handle(self, *args, **options):
        # Get models
        UserProfile = apps.get_model('authentication', 'UserProfile')
        Classroom = apps.get_model('authentication', 'Classroom')
        User = apps.get_model('auth', 'User')
        
        # Print UserProfile structure
        self.stdout.write(self.style.SUCCESS("UserProfile Fields:"))
        for field in UserProfile._meta.get_fields():
            self.stdout.write(f"  - {field.name} ({field.__class__.__name__})")
        
        # Print Classroom structure
        self.stdout.write(self.style.SUCCESS("\nClassroom Fields:"))
        for field in Classroom._meta.get_fields():
            self.stdout.write(f"  - {field.name} ({field.__class__.__name__})")
        
        # Check relationships
        self.stdout.write(self.style.SUCCESS("\nRelationships:"))
        
        # Check if Classroom has 'students' field
        if hasattr(Classroom, 'students'):
            self.stdout.write("Classroom has 'students' field")
            
            # Check a sample classroom
            try:
                classroom = Classroom.objects.first()
                if classroom:
                    self.stdout.write(f"Sample classroom: {classroom}")
                    student_count = classroom.students.count()
                    self.stdout.write(f"Students: {student_count}")
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error accessing students: {str(e)}"))
        else:
            self.stdout.write(self.style.WARNING("Classroom does NOT have 'students' field"))
            
        # Print User-Classroom relationships
        self.stdout.write(self.style.SUCCESS("\nUser-Classroom relationships:"))
        sample_user = User.objects.first()
        if sample_user:
            self.stdout.write(f"Sample user: {sample_user.username}")
            related_classrooms = Classroom.objects.filter(students=sample_user)
            self.stdout.write(f"Related classrooms count: {related_classrooms.count()}")
        else:
            self.stdout.write("No users found")