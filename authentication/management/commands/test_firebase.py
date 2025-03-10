from django.core.management.base import BaseCommand
import os
import json
import firebase_admin
from firebase_admin import credentials, storage
import datetime

class Command(BaseCommand):
    help = 'Test Firebase credentials and connection'

    def handle(self, *args, **options):
        self.stdout.write("Testing Firebase credentials...")
        
        # Get credentials path
        firebase_cred_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))), 
            'firebase_credentials', 'serviceAccountKey.json'
        )
        
        # Check if file exists
        if not os.path.exists(firebase_cred_path):
            self.stdout.write(self.style.ERROR(f"Credentials file not found at: {firebase_cred_path}"))
            return
            
        self.stdout.write(f"Found credentials file: {firebase_cred_path}")
        
        # Check file permissions
        try:
            self.stdout.write(f"File size: {os.path.getsize(firebase_cred_path)} bytes")
            self.stdout.write(f"File permissions: {oct(os.stat(firebase_cred_path).st_mode & 0o777)}")
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error checking file: {str(e)}"))
        
        # Try to parse JSON
        try:
            with open(firebase_cred_path, 'r') as f:
                cred_data = json.load(f)
                
            # Print key information without showing sensitive data
            self.stdout.write("\nCredential information:")
            self.stdout.write(f"  project_id: {cred_data.get('project_id', 'NOT FOUND')}")
            self.stdout.write(f"  client_email: {cred_data.get('client_email', 'NOT FOUND')}")
            self.stdout.write(f"  Has private_key: {'Yes' if 'private_key' in cred_data else 'No'}")
            self.stdout.write(f"  auth_uri: {cred_data.get('auth_uri', 'NOT FOUND')}")
            
            # Check if key looks valid (basic structure)
            if not all(key in cred_data for key in ['project_id', 'private_key', 'client_email']):
                self.stdout.write(self.style.ERROR("Credentials file is missing required fields"))
        except json.JSONDecodeError:
            self.stdout.write(self.style.ERROR("Credentials file is not valid JSON"))
            return
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error reading credentials: {str(e)}"))
            return
        
        # Check existing Firebase apps
        self.stdout.write("\nChecking existing Firebase apps...")
        existing_apps = firebase_admin._apps
        if existing_apps:
            self.stdout.write(f"Found {len(existing_apps)} existing Firebase app(s)")
            for app_name, app in existing_apps.items():
                self.stdout.write(f"  - App name: '{app_name or 'default'}'")
            
            # Try to use the existing default app
            self.stdout.write("\nAttempting to use existing Firebase app...")
            try:
                # Get the default app
                default_app = firebase_admin.get_app()
                self.stdout.write(self.style.SUCCESS("Successfully got reference to existing app"))
                
                # Test storage with existing app
                self.stdout.write("\nTesting storage with existing app...")
                bucket = storage.bucket(app=default_app)
                self.stdout.write(f"Bucket name: {bucket.name}")
                
                # Try to list blobs (test read)
                blobs = list(bucket.list_blobs(max_results=5))
                self.stdout.write(f"Found {len(blobs)} files in bucket")
                
                for blob in blobs[:5]:  # Show up to 5 files
                    self.stdout.write(f"  - {blob.name} ({blob.size} bytes)")
                
                self.stdout.write(self.style.SUCCESS("\nStorage test with existing app successful"))
                return  # End here if successful
                
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error using existing app: {str(e)}"))
                self.stdout.write("Will try to initialize a new app with a different name...")
        else:
            self.stdout.write("No existing Firebase apps found")
        
        # Try to initialize Firebase with a unique name
        try:
            self.stdout.write("\nTrying to initialize Firebase with a unique name...")
            app_name = f"test-app-{datetime.datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            cred = credentials.Certificate(firebase_cred_path)
            app = firebase_admin.initialize_app(cred, {
                'storageBucket': 'sripedia-2a129.appspot.com'  # Change to your bucket
            }, name=app_name)
            
            self.stdout.write(self.style.SUCCESS(f"Firebase initialized successfully with name: {app_name}"))
            
            # Test storage connection
            self.stdout.write("\nTesting storage connection...")
            bucket = storage.bucket(app=app)
            self.stdout.write(f"Bucket name: {bucket.name}")
            
            # Try to list blobs (test read)
            blobs = list(bucket.list_blobs(max_results=5))
            self.stdout.write(f"Found {len(blobs)} files in bucket")
            
            for blob in blobs[:5]:  # Show up to 5 files
                self.stdout.write(f"  - {blob.name} ({blob.size} bytes)")
            
            # Create a test file
            test_content = f"Test file created at {datetime.datetime.now()}"
            test_blob = bucket.blob('test/firebase_test.txt')
            test_blob.upload_from_string(test_content)
            self.stdout.write(self.style.SUCCESS("Successfully uploaded test file"))
            
            # Generate a URL
            url = test_blob.generate_signed_url(
                version='v4',
                expiration=datetime.timedelta(minutes=15),
                method='GET'
            )
            self.stdout.write(f"Test file URL: {url}")
            
            # Clean up
            test_blob.delete()
            self.stdout.write("Test file deleted")
            
            # Clean up Firebase app
            firebase_admin.delete_app(app)
            self.stdout.write(f"Cleaned up test app: {app_name}")
            
            self.stdout.write(self.style.SUCCESS("\nFirebase test completed successfully"))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"\nError testing Firebase: {str(e)}"))