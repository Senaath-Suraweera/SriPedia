from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.db import connection

class Command(BaseCommand):
    help = 'Check model structure directly using SQL'

    def handle(self, *args, **options):
        self.stdout.write("Checking database schema...")
        
        # Check UserProfile table schema
        with connection.cursor() as cursor:
            cursor.execute("PRAGMA table_info(authentication_userprofile)")
            columns = cursor.fetchall()
            
            self.stdout.write("\nUserProfile columns:")
            for col in columns:
                self.stdout.write(f"  - {col[1]} ({col[2]})")
        
        # Check Classroom table schema
        with connection.cursor() as cursor:
            cursor.execute("PRAGMA table_info(authentication_classroom)")
            columns = cursor.fetchall()
            
            self.stdout.write("\nClassroom columns:")
            for col in columns:
                self.stdout.write(f"  - {col[1]} ({col[2]})")
                
        # Check M2M table for students
        with connection.cursor() as cursor:
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'authentication_classroom_%'")
            tables = cursor.fetchall()
            
            if tables:
                self.stdout.write("\nFound M2M tables:")
                for table in tables:
                    self.stdout.write(f"  - {table[0]}")
                    
                    # Check the first M2M table structure
                    cursor.execute(f"PRAGMA table_info({table[0]})")
                    m2m_columns = cursor.fetchall()
                    for col in m2m_columns:
                        self.stdout.write(f"    - {col[1]} ({col[2]})")
            else:
                self.stdout.write(self.style.WARNING("\nNo M2M tables found for Classroom"))
                
        # Count users and profiles
        with connection.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM auth_user")
            user_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM authentication_userprofile")
            profile_count = cursor.fetchone()[0]
            
            self.stdout.write(f"\nUsers: {user_count}, Profiles: {profile_count}")
        
        self.stdout.write(self.style.SUCCESS("\nCheck complete"))