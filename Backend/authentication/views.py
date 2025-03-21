from django.shortcuts import render, redirect
from django.contrib.auth import login, authenticate
from .forms import SignupForm
from django.contrib import messages
import uuid
from django_auth_project.firebase import save_user_to_firebase
from django.contrib.auth.decorators import login_required
from .openai_service import extract_text_from_pdf, generate_quiz_from_text
from django.http import JsonResponse
from django_auth_project.firebase import upload_file_to_firebase
import json
from django_auth_project.firebase import database

def signup_view(request):
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            # Generate a Firebase UID before saving
            firebase_uid = str(uuid.uuid4())
            print(f"Generated Firebase UID: {firebase_uid}")
            
            # Create the user without immediately saving to database
            user = form.save(commit=False)
            user.firebase_uid = firebase_uid
            
            # Save the user to Django database
            user.save()
            print(f"User {user.username} saved to Django database")
            
            # Save user to Firebase - direct call with clear printed output
            firebase_success = save_user_to_firebase(
                user_id=firebase_uid,
                username=user.username,
                role=user.role
            )
            
            if firebase_success:
                messages.success(request, "Account created successfully and synced with Firebase!")
            else:
                messages.warning(request, "Account created but could not be synced with Firebase.")
            
            # Log the user in
            login(request, user)
            return redirect('home')  # Redirect to home page
    else:
        form = SignupForm()
    
    return render(request, 'authentication/signup.html', {'form': form})

def login_view(request):
    if request.method == 'POST':
        # Process login
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        # Authenticate user
        user = authenticate(request, username=username, password=password)
        
        if user is not None:
            login(request, user)
            return redirect('home')  # Redirect to home page after login
        else:
            return render(request, 'authentication/login.html', {'error': 'Invalid username or password'})
    
    return render(request, 'authentication/login.html')

@login_required
def home_view(request):
    """View for the home page"""
    return render(request, 'authentication/home.html')

@login_required
def chatbot_view(request):
    """AI Chatbot view"""
    return render(request, 'authentication/chatbot.html')

@login_required
def leaderboard_view(request):
    """Leaderboard view showing top users"""
    # You would typically fetch leaderboard data here
    leaderboard_data = [
        {'username': 'user1', 'score': 1200},
        {'username': 'user2', 'score': 950},
        {'username': 'user3', 'score': 820},
        {'username': request.user.username, 'score': 500},
        {'username': 'user5', 'score': 450},
    ]
    return render(request, 'authentication/leaderboard.html', {'leaderboard': leaderboard_data})

@login_required
def daily_quiz_view(request):
    """View for displaying the daily quiz"""
    try:
        from datetime import datetime
        today = datetime.now().strftime('%Y-%m-%d')
        
        # Try to get today's quiz
        daily_quiz = database.child('daily_quizzes').child(today).get()
        
        # If no quiz for today, generate one
        if not daily_quiz:
            from .quiz_generator import generate_daily_quiz
            daily_quiz = generate_daily_quiz(num_questions=20)
            
            # If still no quiz, there's a problem
            if not daily_quiz:
                raise Exception("Could not generate or retrieve daily quiz")
        
        # Check if the user has already taken today's quiz
        user_quiz_results = database.child('users').child(request.user.firebase_uid).child('quiz_results').child(today).get()
        quiz_completed = user_quiz_results is not None
        
        context = {
            'questions': daily_quiz['questions'],
            'quiz_date': today,
            'quiz_completed': quiz_completed,
            'quiz_results': user_quiz_results if quiz_completed else None,
            'sources': daily_quiz.get('sources', [])
        }
        
        return render(request, 'authentication/daily_quiz.html', context)
    except Exception as e:
        print(f"Error loading daily quiz: {str(e)}")
        return render(request, 'authentication/daily_quiz.html', {
            'error': f"Failed to load daily quiz: {str(e)}"
        })

@login_required
def profile_view(request):
    """User profile view"""
    return render(request, 'authentication/profile.html')

@login_required
def generate_quiz_view(request):
    """View for generating quizzes from uploaded files"""
    if request.method == 'POST' and request.FILES.get('document'):
        uploaded_file = request.FILES['document']
        
        # Upload file to Firebase Storage
        file_url = upload_file_to_firebase(
            file=uploaded_file, 
            user_id=request.user.firebase_uid,
            file_name=f"quiz_docs/{uploaded_file.name}"
        )
        
        if not file_url:
            return JsonResponse({
                'success': False,
                'error': 'Failed to upload file'
            })
        
        # Extract text from PDF
        if uploaded_file.name.lower().endswith('.pdf'):
            document_text = extract_text_from_pdf(uploaded_file)
        else:
            # For other file types, you might need additional handlers
            return JsonResponse({
                'success': False,
                'error': 'Unsupported file type. Please upload a PDF.'
            })
        
        # Generate quiz using OpenAI
        quiz_data = generate_quiz_from_text(document_text)
        
        if not quiz_data:
            return JsonResponse({
                'success': False,
                'error': 'Failed to generate quiz questions'
            })
        
        # Save quiz to Firebase
        try:
            quiz_ref = database.child('users').child(request.user.firebase_uid).child('quizzes').push({
                'title': uploaded_file.name.split('.')[0],
                'document_url': file_url,
                'created_at': {'.sv': 'timestamp'},
                'questions': json.loads(quiz_data)
            })
            
            return JsonResponse({
                'success': True,
                'quiz_id': quiz_ref.key,
                'questions': json.loads(quiz_data)
            })
        except Exception as e:
            return JsonResponse({
                'success': False,
                'error': str(e)
            })
    
    return render(request, 'authentication/generate_quiz.html')

@login_required
def user_files_view(request):
    """View for displaying all files uploaded by the user directly from Firebase Storage"""
    try:
        from django_auth_project.firebase import bucket
        
        if not bucket:
            raise Exception("Firebase Storage not initialized")
        
        # Get the user's folder prefix
        user_prefix = f"user_files/{request.user.firebase_uid}/"
        
        # List all blobs with the user's prefix
        blobs = bucket.list_blobs(prefix=user_prefix)
        
        # Convert to a list of file objects
        files = []
        for blob in blobs:
            # Skip folders or empty entries
            if blob.name == user_prefix or blob.name.endswith('/'):
                continue
                
            # Get file metadata
            file_name = blob.name.split('/')[-1]
            file_url = blob.public_url
            
            # Try to get creation time
            try:
                upload_date = blob.time_created.strftime('%Y-%m-%d %H:%M')
            except:
                upload_date = None
            
            # Get file size
            try:
                size_bytes = blob.size
                if size_bytes < 1024:
                    file_size = f"{size_bytes} B"
                elif size_bytes < 1024 * 1024:
                    file_size = f"{size_bytes / 1024:.1f} KB"
                else:
                    file_size = f"{size_bytes / (1024 * 1024):.1f} MB"
            except:
                file_size = "Unknown size"
            
            # Create a file object
            files.append({
                'name': file_name,
                'url': file_url,
                'upload_date': upload_date,
                'size': file_size,
                'content_type': blob.content_type,
                'storage_path': blob.name
            })
        
        # Sort files by name (or you could sort by upload date if available)
        files.sort(key=lambda x: x['name'])
        
        return render(request, 'authentication/user_files.html', {
            'files': files
        })
    except Exception as e:
        print(f"Error retrieving user files from storage: {str(e)}")
        return render(request, 'authentication/user_files.html', {
            'files': [],
            'error': f"Could not load your files: {str(e)}"
        })

# Update the delete_file_view function

@login_required
def delete_file_view(request):
    """Delete a user's file from Firebase Storage"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            storage_path = data.get('storage_path')
            
            if not storage_path:
                return JsonResponse({'success': False, 'error': 'No file path provided'})
            
            # Verify the file belongs to the current user
            user_prefix = f"user_files/{request.user.firebase_uid}/"
            if not storage_path.startswith(user_prefix):
                return JsonResponse({'success': False, 'error': 'Access denied to this file'})
            
            # Delete from Firebase Storage
            from django_auth_project.firebase import bucket
            blob = bucket.blob(storage_path)
            blob.delete()
            
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})
    
    return JsonResponse({'success': False, 'error': 'Invalid request method'})

# Add a function to handle quiz submission

@login_required
def submit_quiz_view(request):
    """Handle quiz submission and scoring"""
    if request.method != 'POST':
        return redirect('daily_quiz')
    
    try:
        quiz_date = request.POST.get('quiz_date')
        
        # Get the quiz questions for scoring
        quiz_data = database.child('daily_quizzes').child(quiz_date).get()
        
        if not quiz_data:
            raise Exception(f"Could not find quiz for date {quiz_date}")
        
        questions = quiz_data['questions']
        
        # Collect user answers
        user_answers = {}
        correct_count = 0
        
        for i in range(len(questions)):
            answer_key = f'answer{i}'
            user_answer = request.POST.get(answer_key)
            
            if user_answer is not None:
                user_answer = int(user_answer)
                user_answers[i] = user_answer
                
                # Check if answer is correct
                if user_answer == questions[i]['correct_index']:
                    correct_count += 1
        
        # Calculate score as percentage
        score = int((correct_count / len(questions)) * 100)
        
        # Save results to Firebase
        result = {
            'score': score,
            'correct': correct_count,
            'total': len(questions),
            'answers': user_answers,
            'completed_at': {'.sv': 'timestamp'},
            'quiz_date': quiz_date
        }
        
        # Save to user's quiz results
        database.child('users').child(request.user.firebase_uid).child('quiz_results').child(quiz_date).set(result)
        
        # Update leaderboard
        leaderboard_entry = {
            'user_id': request.user.firebase_uid,
            'username': request.user.username,
            'score': score,
            'completed_at': {'.sv': 'timestamp'}
        }
        database.child('leaderboard').child(quiz_date).child(request.user.firebase_uid).set(leaderboard_entry)
        
        # Redirect back to the quiz page to see results
        return redirect('daily_quiz')
    
    except Exception as e:
        print(f"Error submitting quiz: {str(e)}")
        messages.error(request, f"Error submitting quiz: {str(e)}")
        return redirect('daily_quiz')