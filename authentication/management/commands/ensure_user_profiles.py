from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from authentication.models import UserProfile

class Command(BaseCommand):
    help = 'Ensures all users have a UserProfile with a role'

    def handle(self, *args, **options):
        users_without_profiles = 0
        users_updated = 0
        
        for user in User.objects.all():
            profile, created = UserProfile.objects.get_or_create(
                user=user,
                defaults={'role': 'student'}
            )
            
            if created:
                users_without_profiles += 1
                self.stdout.write(f"Created profile for {user.username}")
            else:
                # Make sure they have a role
                if not profile.role:
                    profile.role = 'student'
                    profile.save()
                    users_updated += 1
                    self.stdout.write(f"Updated profile for {user.username}")
        
        self.stdout.write(self.style.SUCCESS(
            f"Done! Created {users_without_profiles} new profiles, updated {users_updated} existing profiles."
        ))