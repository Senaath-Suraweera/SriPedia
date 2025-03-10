from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login, authenticate, logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import HttpResponseForbidden, Http404
from .forms import SignupForm, LoginForm
from .models import UserProfile, Classroom
import random
import string
from django.contrib import messages
import uuid
from django_auth_project.firebase import save_user_to_firebase
from .openai_service import extract_text_from_pdf, generate_quiz_from_text
from django.http import JsonResponse
from django_auth_project.firebase import upload_file_to_firebase
import json
from django_auth_project.firebase import database
from django.contrib.auth.models import User

from django_auth_project.firebase import (
    create_classroom_in_firebase, 
    add_student_to_classroom_firebase, 
    get_classroom_students_firebase,
    update_classroom_in_firebase,
    update_classroom_join_code_in_firebase,
    remove_student_from_classroom_firebase
)

# Add these imports at the top
from firebase_admin import storage
import firebase_admin
import logging
import os
import datetime

# Set up logging
logger = logging.getLogger(__name__)

# Add this function to safely initialize Firebase Storage
def get_firebase_storage():
    """
    Safely get a reference to Firebase Storage.
    Returns the bucket or None if there's an error.
    """
    try:
        # Check if Firebase has been initialized
        if firebase_admin._apps:
            # Use existing app
            logger.info("Using existing Firebase app")
            app = firebase_admin.get_app()
        else:
            logger.warning("Firebase not initialized, attempting initialization now")
            
            # Get the path to credentials
            firebase_cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
                                            'firebase_credentials', 'serviceAccountKey.json')
            
            # Debug: Print the credential path and check if file exists
            logger.info(f"Looking for credentials at: {firebase_cred_path}")
            if (os.path.exists(firebase_cred_path)):
                logger.info(f"Credentials file exists, size: {os.path.getsize(firebase_cred_path)} bytes")
            else:
                logger.error(f"Credentials file not found at: {firebase_cred_path}")
                return None
            
            # Initialize Firebase
            from firebase_admin import credentials
            try:
                cred = credentials.Certificate(firebase_cred_path)
                app = firebase_admin.initialize_app(cred, {
                    'storageBucket': 'sripedia-2a129.appspot.com'
                })
                logger.info("Firebase initialized successfully")
            except Exception as e:
                logger.error(f"Firebase initialization error: {str(e)}")
                return None
        
        # Get the bucket using the app reference
        bucket = storage.bucket(app=app)
        return bucket
    
    except Exception as e:
        logger.error(f"Error connecting to Firebase Storage: {str(e)}")
        return None

# Add this function near the top of the file or with your other views
def home_page(request):
    """View for the home page"""
    from django.shortcuts import redirect
    
    # If the user is authenticated, redirect to their dashboard
    if request.user.is_authenticated:
        # You can replace 'dashboard' with the appropriate URL name for your app
        return redirect('dashboard')
    # Otherwise redirect to login
    return redirect('login')

def signup_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')  # Redirect if already logged in
    
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            user = form.save()  # This creates both User and UserProfile
            
            # Log the user in after signup
            login(request, user)
            
            messages.success(request, f"Welcome, {user.username}! Your account has been created successfully.")
            return redirect('dashboard')  # Redirect to dashboard after signup
    else:
        form = SignupForm()
    
    return render(request, 'authentication/signup.html', {'form': form})

def login_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')  # Redirect if already logged in
        
    if request.method == 'POST':
        form = LoginForm(data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            
            # Remember me functionality
            if not form.cleaned_data.get('remember_me', False):
                # Session expires when browser closes
                request.session.set_expiry(0)
                
            messages.success(request, f"Welcome back, {user.username}!")
            return redirect('dashboard')  # Redirect to dashboard after login
    else:
        form = LoginForm()
        
    return render(request, 'authentication/login.html', {'form': form})

@login_required
def home_view(request):
    """View for the home page"""
    user = request.user
    user_profile, created = UserProfile.objects.get_or_create(
        user=user,
        defaults={'role': 'student'}
    )
    
    context = {
        'user': user,
        'user_profile': user_profile,
    }
    
    return render(request, 'authentication/home.html', context)

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
    """View for displaying and uploading user files"""
    user_profile = get_object_or_404(UserProfile, user=request.user)
    
    files_list = []
    error_message = None
    
    try:
        # Try to get the Firebase Storage bucket
        bucket = get_firebase_storage()
        
        if bucket:
            # List user files
            user_folder = f"user_files/{request.user.id}/"
            blobs = bucket.list_blobs(prefix=user_folder)
            
            for blob in blobs:
                # Skip directory markers
                if blob.name.endswith('/'):
                    continue
                    
                # Get filename from path
                filename = blob.name.split('/')[-1]
                
                try:
                    # Generate a signed URL that's valid for 1 hour
                    signed_url = blob.generate_signed_url(
                        version='v4',
                        expiration=datetime.timedelta(hours=1),
                        method='GET'
                    )
                except Exception as e:
                    # Fall back to direct URL if signing fails
                    signed_url = f"https://storage.googleapis.com/{bucket.name}/{blob.name}"
                
                files_list.append({
                    'name': filename,
                    'url': signed_url,
                    'blob_name': blob.name,
                    'size': blob.size,
                    'updated': blob.updated,
                })
        else:
            error_message = "Could not connect to file storage"
            
    except Exception as e:
        logger.error(f"Error in user_files_view: {str(e)}")
        error_message = f"Error loading files: {str(e)}"
    
    context = {
        'user_profile': user_profile,
        'files': files_list,
        'error_message': error_message
    }
    
    if error_message:
        messages.error(request, error_message)
    
    return render(request, 'authentication/user_files.html', context)

# Update the delete_file_view function

@login_required
def delete_file_view(request):
    """Delete a user's file from Firebase Storage"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            storage_path = data.get('storage_path')
            
            # Check if the storage_path belongs to the current user
            user_folder = f"user_files/{request.user.id}/"
            if not storage_path.startswith(user_folder):
                return JsonResponse({'error': 'Unauthorized access'}, status=403)
            
            # Get Firebase storage bucket
            bucket = get_firebase_storage()
            if not bucket:
                return JsonResponse({'error': 'Storage service unavailable'}, status=503)
                
            # Delete the file
            blob = bucket.blob(storage_path)
            blob.delete()
            
            return JsonResponse({'success': True})
            
        except Exception as e:
            logger.error(f"Error in delete_file_view: {str(e)}")
            return JsonResponse({'error': str(e)}, status=500)
    
    return JsonResponse({'error': 'Invalid request'}, status=400)

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

def register(request):
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            # Save the user
            user = form.save()
            
            # Get role from form data
            role = form.cleaned_data.get('role')
            
            # Create a user profile with the role
            UserProfile.objects.create(user=user, role=role)
            
            # Save to Firebase if needed
            save_user_to_firebase(
                user_id=str(user.id),
                username=user.username,
                role=role
            )
            
            login(request, user)
            return redirect('home')  # Adjust redirect as needed
        else:
            # Print errors for debugging
            print(f"Form errors: {form.errors}")
            print(f"Role field errors: {form.errors.get('role', 'No role errors')}")
            print(f"Submitted data: {request.POST}")
    else:
        form = SignupForm()
    
    return render(request, 'register.html', {'form': form})

# Add these views
@login_required
def classroom_list_view(request):
    """View for listing user's classrooms"""
    # Get user profile
    try:
        user_profile = UserProfile.objects.get(user=request.user)
    except UserProfile.DoesNotExist:
        user_profile = UserProfile.objects.create(user=request.user, role=UserProfile.STUDENT)
    
    # Get classrooms where user is teacher
    created_classrooms = Classroom.objects.filter(teacher=request.user)
    
    # Get classrooms where user is a student
    joined_classrooms = Classroom.objects.filter(students=request.user)
    
    context = {
        'user_profile': user_profile,
        'created_classrooms': created_classrooms,
        'joined_classrooms': joined_classrooms,
        'has_classrooms': created_classrooms.exists() or joined_classrooms.exists()
    }
    
    return render(request, 'authentication/classroom_list.html', context)

@login_required
def create_classroom_view(request):
    """View for creating a new classroom (teachers only)"""
    # Get or create user profile
    user_profile, created = UserProfile.objects.get_or_create(
        user=request.user,
        defaults={'role': UserProfile.STUDENT}
    )
    
    # Check if user is a teacher
    if user_profile.role != UserProfile.TEACHER:
        messages.error(request, "Only teachers can create classrooms")
        return redirect('classroom_list')
    
    if request.method == 'POST':
        name = request.POST.get('name')
        description = request.POST.get('description', '')
        
        if not name:
            messages.error(request, "Classroom name is required")
            return redirect('create_classroom')
        
        # Generate a unique join code
        join_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        while Classroom.objects.filter(join_code=join_code).exists():
            join_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        
        # Create classroom in Django
        classroom = Classroom.objects.create(
            name=name,
            description=description,
            join_code=join_code,
            teacher=request.user
        )
        
        # Create classroom in Firebase
        create_classroom_in_firebase(
            classroom_id=str(classroom.id),
            teacher_id=str(request.user.id),
            name=name,
            description=description,
            join_code=join_code
        )
        
        messages.success(request, f"Classroom '{name}' created successfully with join code: {join_code}")
        return redirect('classroom_detail', classroom_id=classroom.id)
    
    return render(request, 'authentication/create_classroom.html')

@login_required
def join_classroom_view(request):
    """View for students to join a classroom"""
    if request.method == 'POST':
        join_code = request.POST.get('join_code', '').strip().upper()
        
        if not join_code:
            messages.error(request, "Join code is required")
            return redirect('join_classroom')
        
        try:
            classroom = Classroom.objects.get(join_code=join_code)
            
            # Check if user is already in the classroom
            if request.user in classroom.students.all():
                messages.info(request, f"You are already a member of {classroom.name}")
            else:
                # Add user to classroom
                classroom.students.add(request.user)
                
                # Add to Firebase
                firebase_uid = getattr(request.user, 'firebase_uid', str(request.user.id))
                add_student_to_classroom_firebase(str(classroom.id), firebase_uid)
                
                messages.success(request, f"Successfully joined {classroom.name}")
            
            return redirect('classroom_detail', classroom_id=classroom.id)
            
        except Classroom.DoesNotExist:
            messages.error(request, "Invalid join code")
    
    return render(request, 'authentication/join_classroom.html')

@login_required
def classroom_detail_view(request, classroom_id):
    """View a specific classroom"""
    classroom = get_object_or_404(Classroom, id=classroom_id)
    
    # Check if user has access to this classroom
    is_teacher = classroom.teacher == request.user
    is_student = request.user in classroom.students.all()
    
    if not (is_teacher or is_student):
        return HttpResponseForbidden("You don't have access to this classroom")
    
    # Get user profile to determine role
    profile = UserProfile.objects.get(user=request.user)
    
    # Get list of students
    students = classroom.students.all()
    
    # Get any classroom-specific content
    # This could be quizzes, assignments, etc. that you implement later
    
    context = {
        'classroom': classroom,
        'is_teacher': is_teacher,
        'is_student': is_student,
        'user_role': profile.role,
        'students': students,
    }
    
    return render(request, 'authentication/classroom_detail.html', context)

@login_required
def leave_classroom_view(request, classroom_id):
    """View for leaving a classroom"""
    classroom = get_object_or_404(Classroom, id=classroom_id)
    user_profile = get_object_or_404(UserProfile, user=request.user)
    
    # Check if user is a member of this classroom
    if classroom not in user_profile.joined_classrooms.all():
        messages.error(request, "You are not a member of this classroom.")
        return redirect('classroom_list')
    
    # Check if user is the teacher of the classroom
    if classroom.teacher == request.user:  # Compare with User model, not UserProfile
        messages.error(request, "As the teacher, you cannot leave your own classroom. You may delete it instead.")
        return redirect('classroom_detail', classroom_id=classroom_id)
    
    # Remove the user from the classroom
    user_profile.joined_classrooms.remove(classroom)
    
    # Add success message
    messages.success(request, f"You have successfully left the classroom: {classroom.name}")
    
    # Redirect to classroom list
    return redirect('classroom_list')

@login_required
def remove_student_view(request, classroom_id, student_id):
    """View for teachers to remove a student from their classroom"""
    # Get or create user profile
    user_profile, created = UserProfile.objects.get_or_create(
        user=request.user,
        defaults={'role': UserProfile.STUDENT}
    )
    
    # Check if user is a teacher
    if user_profile.role != UserProfile.TEACHER:
        messages.error(request, "Only teachers can remove students")
        return redirect('classroom_list')
    
    if request.method != 'POST':
        return redirect('classroom_detail', classroom_id=classroom_id)
    
    classroom = get_object_or_404(Classroom, id=classroom_id)
    
    # Check if user is the teacher of this classroom
    if classroom.teacher != request.user:
        messages.error(request, "You can only manage your own classrooms")
        return redirect('classroom_list')
    
    # Get the student
    try:
        student = User.objects.get(id=student_id)
        
        # Remove student from classroom
        if student in classroom.students.all():
            classroom.students.remove(student)
            messages.success(request, f"{student.username} has been removed from the classroom")
            
            # Update Firebase
            # You would need a function to remove student from Firebase
            # remove_student_from_classroom_firebase(str(classroom.id), str(student.id))
        else:
            messages.error(request, f"{student.username} is not in this classroom")
    except User.DoesNotExist:
        messages.error(request, "Student not found")
    
    return redirect('classroom_detail', classroom_id=classroom_id)

@login_required
def edit_classroom_view(request, classroom_id):
    """View for teachers to edit classroom details"""
    # Get or create user profile
    user_profile, created = UserProfile.objects.get_or_create(
        user=request.user,
        defaults={'role': UserProfile.STUDENT}
    )
    
    # Check if user is a teacher
    if user_profile.role != UserProfile.TEACHER:
        messages.error(request, "Only teachers can edit classrooms")
        return redirect('classroom_list')
    
    classroom = get_object_or_404(Classroom, id=classroom_id)
    
    # Check if user is the teacher of this classroom
    if classroom.teacher != request.user:
        messages.error(request, "You can only edit your own classrooms")
        return redirect('classroom_list')
    
    if request.method == 'POST':
        name = request.POST.get('name')
        description = request.POST.get('description', '')
        
        if not name:
            messages.error(request, "Classroom name is required")
        else:
            # Update classroom
            classroom.name = name
            classroom.description = description
            classroom.save()
            
            # Update Firebase
            update_classroom_in_firebase(
                classroom_id=str(classroom.id),
                name=name,
                description=description
            )
            
            messages.success(request, "Classroom updated successfully")
            return redirect('classroom_detail', classroom_id=classroom.id)
    
    context = {
        'classroom': classroom
    }
    
    return render(request, 'authentication/edit_classroom.html', context)

@login_required
def regenerate_join_code_view(request, classroom_id):
    """View for teachers to regenerate a classroom join code"""
    # Get or create user profile
    user_profile, created = UserProfile.objects.get_or_create(
        user=request.user,
        defaults={'role': UserProfile.STUDENT}
    )
    
    # Check if user is a teacher
    if user_profile.role != UserProfile.TEACHER:
        messages.error(request, "Only teachers can regenerate join codes")
        return redirect('classroom_list')
    
    if request.method != 'POST':
        return redirect('classroom_detail', classroom_id=classroom_id)
    
    classroom = get_object_or_404(Classroom, id=classroom_id)
    
    # Check if user is the teacher of this classroom
    if classroom.teacher != request.user:
        messages.error(request, "You can only manage your own classrooms")
        return redirect('classroom_list')
    
    # Generate a new unique join code
    new_join_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
    while Classroom.objects.filter(join_code=new_join_code).exists():
        new_join_code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
    
    # Update join code
    classroom.join_code = new_join_code
    classroom.save()
    
    # Update Firebase
    update_classroom_join_code_in_firebase(
        classroom_id=str(classroom.id),
        new_join_code=new_join_code
    )
    
    messages.success(request, f"Join code regenerated successfully. New code: {new_join_code}")
    return redirect('classroom_detail', classroom_id=classroom.id)

from django.contrib.auth import logout
from django.shortcuts import redirect

def logout_view(request):
    """View for logging out users"""
    logout(request)
    return redirect('login')  # Redirect to login page after logout

# Run this in a Django shell (python manage.py shell)
from django.contrib.auth.models import User
from authentication.models import UserProfile

# Create profiles for all users who don't have one
def get_all_users():
    return User.objects.all()

# Add this if it doesn't exist
@login_required
def dashboard(request):
    """User dashboard view"""
    # Add your dashboard logic here
    return render(request, 'authentication/dashboard.html')

from django.contrib.auth.decorators import login_required

# Add this function to your views.py file
@login_required
def dashboard(request):
    """
    Dashboard view for authenticated users
    """
    # Get user information
    user = request.user
    
    # Get any additional data you want to display on the dashboard
    # For example: recent activities, statistics, etc.
    
    context = {
        'user': user,
        # Add additional context data here
    }
    
    return render(request, 'authentication/dashboard.html', context)

# Add this function if you want to keep the URL as 'signup/'
def signup(request):
    """View for user registration"""
    if request.method == 'POST':
        form = UserRegistrationForm(request.POST)
        if form.is_valid():
            user = form.save()
            # Create a profile for the user
            UserProfile.objects.create(user=user, role='student')
            login(request, user)
            messages.success(request, "Registration successful!")
            return redirect('dashboard')
        else:
            messages.error(request, "Registration failed. Please check the form.")
    else:
        form = UserRegistrationForm()
    
    return render(request, 'authentication/signup.html', {'form': form})

from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.contrib.auth import login

# Add these imports if needed
from .models import UserProfile
from .forms import UserRegistrationForm

@login_required
def dashboard_view(request):
    """View for the dashboard page"""
    user = request.user
    user_profile, created = UserProfile.objects.get_or_create(
        user=user,
        defaults={'role': 'student'}  # Default to student role
    )
    
    context = {
        'user': user,
        'user_profile': user_profile,
        # Add additional context data here
    }
    
    return render(request, 'authentication/dashboard.html', context)

@login_required
def home_view(request):
    """View for the home page"""
    user = request.user
    user_profile, created = UserProfile.objects.get_or_create(
        user=user,
        defaults={'role': 'student'}
    )
    
    context = {
        'user': user,
        'user_profile': user_profile,
    }
    
    return render(request, 'authentication/home.html', context)

def signup(request):
    """View for user registration with role selection"""
    if request.method == 'POST':
        form = UserRegistrationForm(request.POST)
        if form.is_valid():
            # Save the user
            user = form.save()
            
            # Get the selected role from the form
            selected_role = form.cleaned_data.get('role')
            
            # Create a profile for the user with the selected role
            UserProfile.objects.create(
                user=user,
                role=selected_role
            )
            
            # Log the user in
            login(request, user)
            
            # Show success message
            messages.success(request, "Registration successful! Welcome to SriPedia.")
            return redirect('dashboard')
        else:
            # Show error message
            messages.error(request, "Registration failed. Please check the form.")
    else:
        form = UserRegistrationForm()
    
    return render(request, 'authentication/signup.html', {'form': form})

from django.shortcuts import render, redirect
from django.contrib.auth import login, logout
from django.contrib.auth.models import User
from django.contrib import messages
from .forms import FirebaseSignupForm, FirebaseLoginForm
from .models import UserProfile
from .firebase_auth import create_firebase_user, authenticate_firebase_user, delete_firebase_user
from django.db import transaction

# Registration view using Firebase
def firebase_signup_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')
        
    if request.method == 'POST':
        form = FirebaseSignupForm(request.POST)
        if form.is_valid():
            username = form.cleaned_data['username']
            email = form.cleaned_data['email']
            password = form.cleaned_data['password1']
            role = form.cleaned_data['role']
            
            # Create Firebase user first
            firebase_result = create_firebase_user(email, password, display_name=username)
            
            if firebase_result['success']:
                try:
                    with transaction.atomic():
                        # Create Django user (with unusable password)
                        user = User.objects.create_user(
                            username=username,
                            email=email,
                            # Don't store the real password in Django
                            password=User.objects.make_random_password()  
                        )
                        
                        # Create user profile with Firebase UID
                        profile = UserProfile.objects.create(
                            user=user,
                            role=role,
                            firebase_uid=firebase_result['uid']
                        )
                        
                        # Login the user
                        login(request, user)
                        messages.success(request, f"Welcome {username}! Your account has been created.")
                        return redirect('dashboard')
                
                except Exception as e:
                    # Roll back Firebase user if Django user creation fails
                    delete_firebase_user(firebase_result['uid'])
                    messages.error(request, f"Error creating account: {str(e)}")
            else:
                messages.error(request, f"Firebase error: {firebase_result.get('error', 'Unknown error')}")
    else:
        form = FirebaseSignupForm()
    
    return render(request, 'authentication/signup.html', {'form': form})

# Login view using Firebase
def firebase_login_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')
        
    if request.method == 'POST':
        form = FirebaseLoginForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            password = form.cleaned_data['password']
            
            # Authenticate with Firebase
            firebase_result = authenticate_firebase_user(email, password)
            
            if firebase_result['success']:
                try:
                    # Find user by email or Firebase UID
                    user = User.objects.filter(email=email).first()
                    
                    if not user:
                        # Try to find by Firebase UID if email lookup fails
                        profile = UserProfile.objects.filter(firebase_uid=firebase_result['uid']).first()
                        user = profile.user if profile else None
                    
                    if user:
                        # Login the Django user
                        login(request, user)
                        
                        # Store Firebase tokens in session
                        request.session['firebase_token'] = firebase_result['token']
                        request.session['firebase_refresh_token'] = firebase_result['refresh_token']
                        
                        messages.success(request, f"Welcome back, {user.username}!")
                        return redirect('dashboard')
                    else:
                        messages.error(request, "User not found in system.")
                except Exception as e:
                    messages.error(request, f"Error during login: {str(e)}")
            else:
                messages.error(request, f"Authentication failed: {firebase_result.get('error', 'Invalid credentials')}")
    else:
        form = FirebaseLoginForm()
    
    return render(request, 'authentication/login.html', {'form': form})

# Logout view
def firebase_logout_view(request):
    # Clear Firebase tokens from session
    if 'firebase_token' in request.session:
        del request.session['firebase_token']
    if 'firebase_refresh_token' in request.session:
        del request.session['firebase_refresh_token']
    
    # Logout from Django
    logout(request)
    messages.success(request, "You have been logged out.")
    return redirect('login')