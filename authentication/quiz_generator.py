import os
import random
import json
import tempfile
from datetime import datetime
from django.conf import settings
from django_auth_project.firebase import bucket, database
from .openai_service import extract_text_from_pdf, generate_quiz_from_text

def get_textbook_files():
    """Get a list of all available textbook files"""
    try:
        # List all blobs with the textbook folder prefix
        textbook_prefix = "ALL_TEXTBOOK_DATA/"
        blobs = bucket.list_blobs(prefix=textbook_prefix)
        
        # Filter for PDF files only
        pdf_files = [blob for blob in blobs if 
                    blob.name != textbook_prefix and 
                    blob.name.lower().endswith('.pdf')]
        
        return pdf_files
    except Exception as e:
        print(f"Error getting textbook files: {str(e)}")
        return []

def download_random_textbook_sections(num_sections=3):
    """Download random sections from textbooks and extract text"""
    try:
        textbooks = get_textbook_files()
        
        if not textbooks:
            raise Exception("No textbooks found in the ALL_TEXTBOOK_DATA folder")
        
        # Select random textbooks (up to specified number or fewer if not enough available)
        selected_textbooks = random.sample(textbooks, min(num_sections, len(textbooks)))
        
        # Extract content from each selected textbook
        combined_text = ""
        sources = []
        
        for textbook in selected_textbooks:
            # Create a temporary file to download the pdf
            with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
                temp_path = temp_file.name
                
                # Download the PDF
                textbook.download_to_filename(temp_path)
                
                # Extract a portion of text (to avoid very large content)
                text = ""
                try:
                    import PyPDF2
                    with open(temp_path, 'rb') as pdf_file:
                        reader = PyPDF2.PdfReader(pdf_file)
                        
                        # Get the total number of pages
                        num_pages = len(reader.pages)
                        
                        # Select a random starting page 
                        if num_pages <= 3:
                            start_page = 0
                        else:
                            start_page = random.randint(0, num_pages - 3)
                        
                        # Extract 2-3 pages of content
                        num_extract_pages = min(3, num_pages - start_page)
                        for i in range(start_page, start_page + num_extract_pages):
                            page = reader.pages[i]
                            text += page.extract_text() + "\n\n"
                except Exception as e:
                    print(f"Error extracting text from {textbook.name}: {str(e)}")
                    
                # Add source info
                textbook_name = os.path.basename(textbook.name)
                sources.append({
                    "filename": textbook_name,
                    "pages": f"{start_page+1}-{start_page+num_extract_pages}"
                })
                
                # Add this content to the combined text
                if text:
                    combined_text += f"\n--- From {textbook_name} ---\n\n"
                    combined_text += text
                
                # Clean up temporary file
                os.unlink(temp_path)
        
        return combined_text, sources
    except Exception as e:
        print(f"Error downloading textbook sections: {str(e)}")
        return "", []

def generate_daily_quiz(num_questions=20):
    """Generate a daily quiz with specified number of questions"""
    try:
        # Get current date for quiz identification
        today = datetime.now().strftime('%Y-%m-%d')
        
        # Check if we already have a quiz for today
        existing_quiz = database.child('daily_quizzes').child(today).get()
        if existing_quiz:
            print(f"Daily quiz for {today} already exists")
            return existing_quiz
        
        # Download random textbook sections
        content, sources = download_random_textbook_sections(num_sections=3)
        
        if not content:
            raise Exception("Could not extract content from textbooks")
        
        # Generate quiz questions using OpenAI
        quiz_data = generate_quiz_from_text(content, num_questions=num_questions)
        
        if not quiz_data:
            raise Exception("Failed to generate quiz questions")
        
        # Parse the quiz data
        quiz_questions = json.loads(quiz_data)
        
        # Create quiz object with metadata
        quiz_object = {
            'date': today,
            'created_at': {'.sv': 'timestamp'},
            'questions': quiz_questions,
            'sources': sources,
            'total_questions': len(quiz_questions)
        }
        
        # Save to Firebase
        database.child('daily_quizzes').child(today).set(quiz_object)
        
        print(f"Successfully generated daily quiz for {today} with {len(quiz_questions)} questions")
        return quiz_object
    
    except Exception as e:
        print(f"Error generating daily quiz: {str(e)}")
        return None