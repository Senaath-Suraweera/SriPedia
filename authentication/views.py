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
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            user = form.save()  # This already creates UserProfile
            
            # Save to Firebase if needed
            save_user_to_firebase(
                user_id=str(user.id),
                username=user.username,
                role=form.cleaned_data.get('role')
            )
            
            login(request, user)
            return redirect('home')  # Or whatever your home URL name is
        else:
            print(f"Form errors: {form.errors}")
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
    """View for listing classrooms"""
    # Get or create user profile
    user_profile, created = UserProfile.objects.get_or_create(
        user=request.user,
        defaults={'role': UserProfile.STUDENT}
    )
    
    context = {
        'is_teacher': user_profile.role == UserProfile.TEACHER,
    }
    
    try:
        profile = UserProfile.objects.get(user=request.user)
        print(f"User profile found. Role: {profile.role}")
    except UserProfile.DoesNotExist:
        print("No user profile found!")
        # Create a default profile
        profile = UserProfile.objects.create(user=request.user, role=UserProfile.STUDENT)
        print("Created default student profile")
    
    # Get user profile to check role
    profile = UserProfile.objects.get(user=request.user)
    
    context = {
        'is_teacher': profile.role == UserProfile.TEACHER,
    }
    
    if profile.role == UserProfile.TEACHER:
        # Teachers see classrooms they've created
        context['created_classrooms'] = Classroom.objects.filter(teacher=request.user).order_by('-created_at')
        context['joined_classrooms'] = request.user.joined_classrooms.all()
    else:
        # Students see classrooms they've joined
        context['joined_classrooms'] = request.user.joined_classrooms.all()
    
    return render(request, 'authentication/classrooms.html', context)

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
    """View for students to leave a classroom"""
    if request.method != 'POST':
        return redirect('classroom_detail', classroom_id=classroom_id)
        
    classroom = get_object_or_404(Classroom, id=classroom_id)
    
    # Check if user is a student in this classroom
    if request.user not in classroom.students.all():
        messages.error(request, "You are not a member of this classroom")
        return redirect('classroom_list')
    
    # Remove user from classroom
    classroom.students.remove(request.user)
    
    # Update Firebase (requires implementation of remove_student_from_classroom_firebase)
    # firebase_uid = getattr(request.user, 'firebase_uid', str(request.user.id))
    # remove_student_from_classroom_firebase(str(classroom.id), firebase_uid)
    
    messages.success(request, f"You have left {classroom.name}")
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