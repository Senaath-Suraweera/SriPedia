import os
import openai
import tempfile
import PyPDF2
from django.conf import settings

# Initialize OpenAI API key
openai.api_key = settings.OPENAI_API_KEY

def extract_text_from_pdf(pdf_file):
    """Extract text content from a PDF file"""
    pdf_text = ""
    try:
        # Create a temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            # Write the uploaded file content to the temp file
            for chunk in pdf_file.chunks():
                temp_file.write(chunk)
        
        # Open the temp file with PyPDF2
        with open(temp_file.name, 'rb') as f:
            pdf_reader = PyPDF2.PdfReader(f)
            for page_num in range(len(pdf_reader.pages)):
                page = pdf_reader.pages[page_num]
                pdf_text += page.extract_text()
        
        # Delete the temp file
        os.unlink(temp_file.name)
        
        return pdf_text
    except Exception as e:
        print(f"Error extracting text from PDF: {str(e)}")
        return ""

def generate_quiz_from_text(text, num_questions=5):
    """Generate quiz questions from text using OpenAI API"""
    try:
        # Limit the text length to avoid excessive token usage
        max_text_length = 4000  # Adjust based on your API plan
        if len(text) > max_text_length:
            text = text[:max_text_length] + "..."
        
        # Create the prompt for OpenAI
        prompt = f"""
        Based on the following text about Sri Lanka, create {num_questions} multiple-choice quiz questions.
        
        Each question should:
        1. Be relevant to the content
        2. Have exactly 4 options (A, B, C, D)
        3. Have one correct answer
        4. Focus on factual information
        
        Format the questions as a JSON array of objects with this structure:
        [
            {{
                "question": "Question text here?",
                "options": ["Option A", "Option B", "Option C", "Option D"],
                "correct_index": 0  // Index of the correct answer (0 for A, 1 for B, etc.)
            }},
            // More questions...
        ]
        
        Text to use:
        {text}
        
        Return only the JSON array with no additional text.
        """
        
        # Call the OpenAI API
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",  # or use "gpt-4" for better results if available
            messages=[
                {"role": "system", "content": "You are a quiz creation assistant that specializes in creating educational quizzes about Sri Lanka."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=2000
        )
        
        # Extract and return the quiz questions
        quiz_json = response.choices[0].message.content.strip()
        return quiz_json
    
    except Exception as e:
        print(f"Error generating quiz with OpenAI: {str(e)}")
        return None