import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# OpenAI API key
OPENAI_API_KEY = os.environ.get('OPENAI_API_KEY')

# And add this where appropriate:
FIREBASE_CONFIG = {
    'SERVICE_ACCOUNT_KEY_PATH': os.environ.get('FIREBASE_CREDENTIALS_PATH', os.path.join(BASE_DIR, 'firebase_credentials', 'serviceAccountKey.json')),
}