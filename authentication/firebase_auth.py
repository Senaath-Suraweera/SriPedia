import firebase_admin
from firebase_admin import auth as firebase_auth
import pyrebase
import os
import json
import logging

logger = logging.getLogger(__name__)

def get_firebase_app():
    """Initialize and return Firebase app"""
    # Get the path to credentials
    firebase_cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                    'firebase_credentials', 'serviceAccountKey.json')
    
    if not os.path.exists(firebase_cred_path):
        logger.error(f"Credentials file not found at: {firebase_cred_path}")
        return None
    
    # Load Firebase configuration
    with open(firebase_cred_path) as f:
        service_account = json.load(f)
    
    # Firebase configuration for Pyrebase
    firebase_config = {
        "apiKey": service_account.get("api_key", ""),  # You might need to add this to your serviceAccountKey.json
        "authDomain": f"{service_account.get('project_id')}.firebaseapp.com",
        "databaseURL": f"https://{service_account.get('project_id')}.firebaseio.com",
        "storageBucket": f"{service_account.get('project_id')}.appspot.com",
        "serviceAccount": firebase_cred_path
    }
    
    # Initialize Firebase
    firebase = pyrebase.initialize_app(firebase_config)
    return firebase

def create_firebase_user(email, password, display_name=None):
    """Create a user in Firebase Authentication"""
    try:
        # Initialize Firebase Admin SDK if not already initialized
        if not firebase_admin._apps:
            cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                'firebase_credentials', 'serviceAccountKey.json')
            cred = firebase_admin.credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        # Create user
        user = firebase_auth.create_user(
            email=email,
            password=password,
            display_name=display_name
        )
        
        return {
            'success': True,
            'uid': user.uid,
            'email': user.email,
            'display_name': user.display_name
        }
    except Exception as e:
        logger.error(f"Error creating Firebase user: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def authenticate_firebase_user(email, password):
    """Authenticate a user with Firebase Authentication"""
    try:
        firebase = get_firebase_app()
        if not firebase:
            return {'success': False, 'error': 'Firebase initialization failed'}
        
        # Authenticate with email and password
        auth = firebase.auth()
        user = auth.sign_in_with_email_and_password(email, password)
        
        # Get user info
        user_info = auth.get_account_info(user['idToken'])
        
        return {
            'success': True,
            'uid': user['localId'],
            'token': user['idToken'],
            'refresh_token': user['refreshToken'],
            'email': user_info['users'][0]['email'],
            'email_verified': user_info['users'][0]['emailVerified'],
            'display_name': user_info['users'][0].get('displayName', '')
        }
    except Exception as e:
        logger.error(f"Firebase authentication error: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def delete_firebase_user(uid):
    """Delete a Firebase user by UID"""
    try:
        # Initialize Firebase Admin SDK if not already initialized
        if not firebase_admin._apps:
            cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                'firebase_credentials', 'serviceAccountKey.json')
            cred = firebase_admin.credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        # Delete user
        firebase_auth.delete_user(uid)
        return {'success': True}
    except Exception as e:
        logger.error(f"Error deleting Firebase user: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def update_firebase_user(uid, **kwargs):
    """Update a Firebase user"""
    try:
        # Initialize Firebase Admin SDK if not already initialized
        if not firebase_admin._apps:
            cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                'firebase_credentials', 'serviceAccountKey.json')
            cred = firebase_admin.credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        # Update user
        user = firebase_auth.update_user(uid, **kwargs)
        return {
            'success': True,
            'uid': user.uid,
            'email': user.email,
            'display_name': user.display_name
        }
    except Exception as e:
        logger.error(f"Error updating Firebase user: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def reset_firebase_password(email):
    """Send password reset email"""
    try:
        firebase = get_firebase_app()
        if not firebase:
            return {'success': False, 'error': 'Firebase initialization failed'}
        
        # Send password reset email
        auth = firebase.auth()
        auth.send_password_reset_email(email)
        return {'success': True}
    except Exception as e:
        logger.error(f"Error sending password reset email: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }