import os
import tempfile
import firebase_admin
from firebase_admin import credentials, db, storage
from django.conf import settings
import uuid

firebase_app = None
database = None
bucket = None

def initialize_firebase():
    global firebase_app, database, bucket
    
    if firebase_app is not None:
        return database  # Already initialized
    
    try:
        service_account_path = settings.FIREBASE_CONFIG['SERVICE_ACCOUNT_KEY_PATH']
        print(f"Loading Firebase credentials from: {service_account_path}")
        
        if not os.path.exists(service_account_path):
            print(f"ERROR: Firebase credentials file not found at: {service_account_path}")
            return None
        
        # Initialize Firebase with explicit bucket name
        cred = credentials.Certificate(service_account_path)
        firebase_app = firebase_admin.initialize_app(cred, {
            'databaseURL': 'https://sripedia-2a129-default-rtdb.firebaseio.com/',
            'storageBucket': 'sripedia-2a129.firebasestorage.app'
        })
        
        # Initialize database and storage
        database = db.reference()
        
        # Initialize storage bucket with better error handling
        try:
            bucket = storage.bucket()
            # Test bucket access
            bucket.get_blob('test')
            print("Firebase Storage initialized successfully!")
        except Exception as storage_error:
            print(f"Firebase Storage error: {str(storage_error)}")
            print("Continuing without Storage functionality.")
            bucket = None
        
        print("Firebase initialized successfully!")
        return database
    except Exception as e:
        print(f"Firebase initialization error: {str(e)}")
        return None

# Initialize Firebase at module import time
database = initialize_firebase()

def save_user_to_firebase(user_id, username, role):
    """
    Save a user to Firebase Realtime Database
    """
    # Make sure Firebase is initialized
    global database
    if database is None:
        database = initialize_firebase()
        if database is None:
            print("Failed to initialize Firebase")
            return False
    
    try:
        print(f"Attempting to save user {username} with ID {user_id} to Firebase...")
        
        # Create user data dictionary
        user_data = {
            'username': username,
            'role': role,
            'created_at': {'.sv': 'timestamp'}
        }
        
        # Save to Realtime Database
        database.child('users').child(user_id).set(user_data)
        
        print(f"User {username} saved to Firebase successfully!")
        return True
    except Exception as e:
        print(f"Error saving user to Firebase: {str(e)}")
        return False

def get_user_from_firebase(user_id):
    """
    Retrieve a user from Firebase Realtime Database
    """
    global database
    if database is None:
        database = initialize_firebase()
        if database is None:
            return None
    
    try:
        user_ref = database.child('users').child(user_id)
        user_data = user_ref.get()
        if user_data:
            return user_data
        return None
    except Exception as e:
        print(f"Error fetching user from Firebase: {str(e)}")
        return None

def update_user_in_firebase(user_id, data):
    """
    Update a user in Firebase Realtime Database
    """
    global database
    if database is None:
        database = initialize_firebase()
        if database is None:
            print("Failed to initialize Firebase")
            return False
    
    try:
        database.child('users').child(user_id).update(data)
        print(f"User {user_id} updated in Firebase successfully!")
        return True
    except Exception as e:
        print(f"Error updating user in Firebase: {str(e)}")
        return False

def delete_user_from_firebase(user_id):
    """
    Delete a user from Firebase Realtime Database
    """
    global database
    if database is None:
        database = initialize_firebase()
        if database is None:
            print("Failed to initialize Firebase")
            return False
    
    try:
        database.child('users').child(user_id).remove()
        print(f"User {user_id} deleted from Firebase successfully!")
        return True
    except Exception as e:
        print(f"Error deleting user from Firebase: {str(e)}")
        return False

def upload_file_to_firebase(file, user_id, file_name=None):
    """
    Upload a file to Firebase Storage
    
    Args:
        file: File object to upload
        user_id: User ID to organize files
        file_name: Optional name for the file
        
    Returns:
        Download URL of the uploaded file or None if upload fails
    """
    global bucket
    
    # Check if bucket is initialized
    if bucket is None:
        print("Firebase Storage not available. Can't upload file.")
        return None
    
    try:
        if not file_name:
            file_name = file.name
        
        # Create a unique path for the file
        file_path = f"user_files/{user_id}/{file_name}"
        print(f"Uploading file to: {file_path}")
        
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_file_path = temp_file.name
            # Write the uploaded file content to the temp file
            for chunk in file.chunks():
                temp_file.write(chunk)
        
        # Upload from the temporary file
        blob = bucket.blob(file_path)
        blob.upload_from_filename(temp_file_path)
        
        # Clean up the temporary file
        os.unlink(temp_file_path)
        
        # Make the file publicly accessible
        blob.make_public()
        
        # Get the public URL
        file_url = blob.public_url
        
        # Save file reference in the database
        try:
            files_ref = database.child('users').child(user_id).child('files')
            files_ref.push({
                'name': file_name,
                'url': file_url,
                'uploaded_at': {'.sv': 'timestamp'}
            })
        except Exception as db_error:
            print(f"Warning: Could not save file reference to database: {str(db_error)}")
        
        print(f"File uploaded successfully: {file_url}")
        return file_url
    except Exception as e:
        print(f"Error uploading file to Firebase: {str(e)}")
        # Clean up temp file if it exists and upload failed
        if 'temp_file_path' in locals():
            try:
                os.unlink(temp_file_path)
            except:
                pass
        return None

