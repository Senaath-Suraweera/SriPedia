from django.apps import AppConfig
import os
import firebase_admin
from firebase_admin import credentials
import logging

logger = logging.getLogger(__name__)

class AuthenticationConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'authentication'

    def ready(self):
        # Skip Firebase initialization in management commands and migrations
        if os.environ.get('RUN_MAIN') != 'true':
            return
            
        # Skip if already initialized
        if firebase_admin._apps:
            return
            
        try:
            # Get the path to the Firebase credentials file
            firebase_cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                            'firebase_credentials', 'serviceAccountKey.json')
            
            # Check if the file exists
            if not os.path.exists(firebase_cred_path):
                logger.error(f"Firebase credentials file not found at: {firebase_cred_path}")
                return
            
            # Initialize Firebase with the credentials
            cred = credentials.Certificate(firebase_cred_path)
            firebase_admin.initialize_app(cred, {
                'storageBucket': 'sripedia-2a129.appspot.com'
            })
            logger.info("Firebase initialized successfully!")
            
        except Exception as e:
            logger.error(f"Error initializing Firebase: {str(e)}")