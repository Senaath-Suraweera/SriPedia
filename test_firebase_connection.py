import os
import django
import uuid

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'django_auth_project.settings')
django.setup()

# Import Firebase functions
from django_auth_project.firebase import initialize_firebase, save_user_to_firebase

def test_firebase():
    """Test Firebase connection and data saving"""
    print("Testing Firebase connection...")
    
    # Initialize Firebase
    db = initialize_firebase()
    if db is None:
        print("ERROR: Could not initialize Firebase")
        return
    
    # Generate test user ID
    test_id = str(uuid.uuid4())
    print(f"Generated test ID: {test_id}")
    
    # Try to save test data
    result = save_user_to_firebase(
        user_id=test_id,
        username="test_user",
        role="tester"
    )
    
    if result:
        print("SUCCESS: Test data was saved to Firebase")
    else:
        print("ERROR: Failed to save test data to Firebase")

if __name__ == "__main__":
    test_firebase()