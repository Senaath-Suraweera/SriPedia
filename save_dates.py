import os
import tempfile
import json
import requests
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, storage, firestore

# Initialize Deepseek API settings
DEEPSEEK_API_KEY = "sk-4adf6fe934064b5f8fea5b04ba294a33"
DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"

def extract_events_from_text(text):
    """Extract special events and their years from text using Deepseek API"""
    try:
        # Limit the text length to avoid excessive token usage
        max_text_length = 8000
        if len(text) > max_text_length:
            text = text[:max_text_length] + "..."
        
        # Create the prompt for Deepseek API
        prompt = f"""
        Analyze the following text from a history text book and extract all special historical events
        and the years they happened. Format the output as a JSON array of objects with this structure:
        [
            {{
                "event": "Description of the event",
                "year": "Year of the event (YYYY format)",
                "importance": "Brief explanation of why this event is significant"
            }}
        ]
        
        Text to analyze:
        {text}
        
        Return only the JSON array with no additional text or explanation.
        """
        
        # Call the Deepseek API
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {DEEPSEEK_API_KEY}"
        }
        
        payload = {
            "model": "deepseek-chat",
            "messages": [
                {"role": "system", "content": "You are an AI specialized in analyzing historical texts about Sri Lanka."},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        }
        
        response = requests.post(DEEPSEEK_API_URL, headers=headers, json=payload)
        response.raise_for_status()
        
        response_data = response.json()
        events_json = response_data.get('choices', [{}])[0].get('message', {}).get('content', '').strip()
        
        # Process and clean up the JSON response
        try:
            # Try to parse as is
            parsed_json = json.loads(events_json)
            return parsed_json
        except json.JSONDecodeError:
            # Try to extract JSON from the response
            import re
            json_match = re.search(r'\[\s*\{.*\}\s*\]', events_json, re.DOTALL)
            if json_match:
                try:
                    parsed_json = json.loads(json_match.group(0))
                    return parsed_json
                except:
                    pass
                    
            # If still failing, try more aggressive cleanup
            events_json = events_json.replace('```json', '').replace('```', '')
            try:
                parsed_json = json.loads(events_json)
                return parsed_json
            except:
                print(f"Failed to parse JSON response: {events_json[:100]}...")
                return []
        
    except Exception as e:
        print(f"Error extracting events with Deepseek: {str(e)}")
        if hasattr(e, 'response') and hasattr(e.response, 'text'):
            print(f"API response: {e.response.text}")
        return []

def extract_text_from_pdf(file_path):
    """Extract text content from a PDF file"""
    try:
        import PyPDF2
        text = ""
        with open(file_path, 'rb') as pdf_file:
            reader = PyPDF2.PdfReader(pdf_file)
            
            # Process all pages instead of limiting to 20
            total_pages = len(reader.pages)
            print(f"Processing all {total_pages} pages in the PDF")
            
            for i in range(total_pages):
                if i % 20 == 0 and i > 0:
                    print(f"Processed {i}/{total_pages} pages...")
                    
                page = reader.pages[i]
                text += page.extract_text() + "\n\n"
                
        return text
    except Exception as e:
        print(f"Error extracting text from PDF: {str(e)}")
        return ""

def scan_textbooks_for_events():
    """Scan all textbooks in Firebase storage and extract historical events"""
    try:
        # Initialize Firebase using the serviceAccountKey.json file
        cred_path = os.path.join('firebase_credentials', 'serviceAccountKey.json')
        
        # Check if the file exists
        if not os.path.exists(cred_path):
            print(f"Error: Firebase credentials file not found at {cred_path}")
            return False
            
        # Initialize Firebase Admin SDK
        cred = credentials.Certificate(cred_path)
        
        # Check if already initialized
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app(cred, {
                'storageBucket': 'sripedia-2a129.firebasestorage.app',
                'databaseURL': 'https://sripedia-2a129-default-rtdb.asia-southeast1.firebasedatabase.app'
            })
        
        # Get Storage client
        bucket = storage.bucket()
        
        # Get Database reference
        from firebase_admin import db
        ref = db.reference()
        
        # Get textbook files from Firebase Storage
        textbook_prefix = "ALL_TEXTBOOK_DATA/"
        blobs = bucket.list_blobs(prefix=textbook_prefix)
        
        # Filter for PDF files
        pdf_files = [blob for blob in blobs if 
                    blob.name != textbook_prefix and 
                    blob.name.lower().endswith('.pdf')]
        
        print(f"Found {len(pdf_files)} textbooks to analyze")
        
        # Process each textbook
        all_events = []
        
        for i, textbook in enumerate(pdf_files):
            textbook_name = os.path.basename(textbook.name)
            print(f"Processing {i+1}/{len(pdf_files)}: {textbook_name}")
            
            # Download the PDF to a temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
                temp_path = temp_file.name
                
                # Download the PDF
                textbook.download_to_filename(temp_path)
                
                # Extract text from the PDF
                text = extract_text_from_pdf(temp_path)
                
                # Extract events from the text
                if text:
                    print(f"Extracted {len(text)} characters of text")
                    events = extract_events_from_book(text)  # Use the new chunking function
                    
                    if events:
                        print(f"Found {len(events)} unique events in {textbook_name}")
                        
                        # Add source information to each event
                        for event in events:
                            event['source'] = textbook_name
                        
                        # Add to the collection of all events
                        all_events.extend(events)
                    else:
                        print(f"No events found in {textbook_name}")
                
                # Clean up temporary file
                os.unlink(temp_path)
        
        # Save all events to Firebase
        if all_events:
            print(f"Saving {len(all_events)} events to Firebase...")
            
            # Save events to Firebase with today's date as key
            today = datetime.now().strftime('%Y-%m-%d')
            
            # Save to Realtime Database
            ref.child('sri_lanka_historical_events').child(today).set({
                'events': all_events,
                'total_events': len(all_events),
                'sources_processed': len(pdf_files),
                'created_at': {'.sv': 'timestamp'}
            })
            
            # Also save events organized by year - sanitize keys for Firebase
            events_by_year = {}
            for event in all_events:
                year = event.get('year')
                if year:
                    # Sanitize the year to use as a Firebase key
                    sanitized_year = sanitize_firebase_key(year)
                    if sanitized_year not in events_by_year:
                        events_by_year[sanitized_year] = []
                    events_by_year[sanitized_year].append(event)
            
            # Save events by year
            ref.child('sri_lanka_historical_events_by_year').set(events_by_year)
            
            print("Events successfully saved to Firebase!")
            return True
        else:
            print("No events were found in any textbooks")
            return False
            
    except Exception as e:
        print(f"Error scanning textbooks: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
    

def extract_events_from_book(text):
    """Process a book in chunks to extract events"""
    chunk_size = 7500  # Slightly smaller to ensure we stay within limits
    overlap = 500  # Overlap to avoid cutting events that might span chunk boundaries
    all_events = []
    
    # Calculate number of chunks
    num_chunks = (len(text) + chunk_size - overlap - 1) // (chunk_size - overlap)
    print(f"Processing text in {num_chunks} chunks")
    
    # Process book in overlapping chunks
    for i in range(0, len(text), chunk_size - overlap):
        chunk_num = (i // (chunk_size - overlap)) + 1
        print(f"Processing chunk {chunk_num}/{num_chunks}...")
        
        chunk = text[i:i + chunk_size]
        events = extract_events_from_text(chunk)
        
        print(f"Found {len(events)} events in this chunk")
        all_events.extend(events)
    
    # Remove potential duplicates
    unique_events = []
    seen_events = set()
    
    for event in all_events:
        event_key = f"{event.get('event', '')}_{event.get('year', '')}"
        if event_key not in seen_events:
            seen_events.add(event_key)
            unique_events.append(event)
    
    print(f"Total unique events found: {len(unique_events)}")
    return unique_events

def sanitize_firebase_key(key):
    """Sanitize keys for Firebase to remove invalid characters"""
    # Replace invalid characters with underscores
    key = str(key).replace('.', '_').replace('#', '_').replace('$', '_')
    key = key.replace('[', '_').replace(']', '_').replace('/', '_')
    
    # Also ensure no spaces or other problematic characters
    key = key.replace(' ', '_')
    
    # Make sure the key is not empty
    if not key or key.strip() == '':
        return "unknown_year"
        
    return key

if __name__ == "__main__":
    print("Starting to scan textbooks for historical events...")
    scan_textbooks_for_events()
    print("Script completed!")