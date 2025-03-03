from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from authentication.models import UserProfile

class Command(BaseCommand):
    help = 'Creates UserProfiles for users that do not have one'

    def handle(self, *args, **options):
        created = 0
        for user in User.objects.all():
            profile, was_created = UserProfile.objects.get_or_create(
                user=user,
                defaults={'role': 'student'}
            )
            if was_created:
                created += 1
        
        self.stdout.write(
            self.style.SUCCESS(f'Created {created} UserProfiles')
        )