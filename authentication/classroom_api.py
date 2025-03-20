from datetime import datetime
from rest_framework import status, viewsets, permissions, serializers
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .models import Classroom, ClassroomQuiz, QuizQuestion, QuizOption, QuizSubmission
from django.shortcuts import get_object_or_404
from django.http import Http404
from django_auth_project.firebase import database

class IsTeacherOrReadOnly(permissions.BasePermission):
    """Custom permission to allow teachers to create/edit and students to read"""
    def has_permission(self, request, view):
        # Read permissions are allowed to any request
        if request.method in permissions.SAFE_METHODS:
            return True
        # Write permissions are only allowed to teachers
        return request.user and request.user.is_teacher()

# Classroom serializers
class ClassroomSerializer(serializers.ModelSerializer):
    class Meta:
        model = Classroom
        fields = ['id', 'name', 'description', 'join_code', 'teacher', 'created_at']
        read_only_fields = ['join_code']

# Quiz serializers
class QuizOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuizOption
        fields = ['id', 'text', 'is_correct']

class QuizQuestionSerializer(serializers.ModelSerializer):
    options = QuizOptionSerializer(many=True, read_only=True)
    
    class Meta:
        model = QuizQuestion
        fields = ['id', 'quiz', 'text', 'options']

class ClassroomQuizSerializer(serializers.ModelSerializer):
    questions_count = serializers.SerializerMethodField()
    
    class Meta:
        model = ClassroomQuiz
        fields = ['id', 'classroom', 'title', 'description', 'is_published', 'created_at', 'updated_at', 'questions_count']
    
    def get_questions_count(self, obj):
        return obj.questions.count()

# Classroom API views
class ClassroomViewSet(viewsets.ModelViewSet):
    """API endpoint for classroom operations"""
    serializer_class = ClassroomSerializer
    permission_classes = [permissions.IsAuthenticated, IsTeacherOrReadOnly]
    
    def get_queryset(self):
        user = self.request.user
        if user.is_teacher():
            # Teachers see their own classrooms
            return Classroom.objects.filter(teacher=user)
        else:
            # Students see classrooms they're enrolled in
            return user.joined_classrooms.all()
    
    def perform_create(self, serializer):
        # Set the teacher to the current user
        classroom = serializer.save(teacher=self.request.user)
        classroom.generate_join_code()
        classroom.save()
        
        # Sync with Firebase
        classroom_data = {
            'id': str(classroom.id),
            'name': classroom.name,
            'description': classroom.description,
            'join_code': classroom.join_code,
            'teacher_id': self.request.user.firebase_uid,
            'teacher_name': self.request.user.username,
            'created_at': classroom.created_at.isoformat()
        }
        
        database.child('classrooms').child(str(classroom.id)).set(classroom_data)

# Quiz API views
class ClassroomQuizViewSet(viewsets.ModelViewSet):
    """API endpoint for quiz operations"""
    serializer_class = ClassroomQuizSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        classroom_id = self.kwargs.get('classroom_id')
        if not classroom_id:
            return ClassroomQuiz.objects.none()
            
        classroom = get_object_or_404(Classroom, id=classroom_id)
        user = self.request.user
        
        # Check if user has access to this classroom
        if not (user == classroom.teacher or user in classroom.students.all()):
            raise Http404("You don't have access to this classroom")
            
        # Teachers can see all quizzes, students only published ones
        if user == classroom.teacher:
            return classroom.quizzes.all()
        else:
            return classroom.quizzes.filter(is_published=True)
    
    def perform_create(self, serializer):
        classroom_id = self.kwargs.get('classroom_id')
        classroom = get_object_or_404(Classroom, id=classroom_id)
        
        # Only teachers can create quizzes
        if self.request.user != classroom.teacher:
            raise permissions.PermissionDenied("Only the classroom teacher can create quizzes")
            
        serializer.save(classroom=classroom)

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def join_classroom_api(request):
    """API endpoint for students to join a classroom"""
    if request.user.is_teacher():
        return Response({
            'error': 'Teachers cannot join classrooms'
        }, status=status.HTTP_403_FORBIDDEN)
    
    join_code = request.data.get('join_code')
    
    if not join_code:
        return Response({
            'error': 'Join code is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        classroom = Classroom.objects.get(join_code=join_code)
    except Classroom.DoesNotExist:
        return Response({
            'error': 'Invalid join code'
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Add student to classroom
    classroom.students.add(request.user)
    
    # Update Firebase
    student_data = {
        'id': request.user.firebase_uid,
        'username': request.user.username,
        'joined_at': datetime.now().isoformat()
    }
    database.child('classrooms').child(str(classroom.id)).child('students').child(request.user.firebase_uid).set(student_data)
    
    return Response({
        'success': True,
        'classroom': {
            'id': classroom.id,
            'name': classroom.name
        }
    })

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def submit_quiz_api(request, quiz_id):
    """API endpoint to submit quiz answers"""
    quiz = get_object_or_404(ClassroomQuiz, id=quiz_id)
    classroom = quiz.classroom
    
    # Check if user has access to this classroom
    if not (request.user in classroom.students.all()):
        return Response({'error': "You don't have access to this quiz"}, status=status.HTTP_403_FORBIDDEN)
    
    # Get answers from request
    answers = request.data.get('answers', {})
    time_taken = request.data.get('time_taken', 0)
    
    # Process answers (calculate score, etc.)
    questions = QuizQuestion.objects.filter(quiz=quiz)
    correct_count = 0
    total_questions = questions.count()
    
    for question in questions:
        question_id = str(question.id)
        if question_id in answers:
            selected_option_id = answers[question_id]
            is_correct = QuizOption.objects.filter(
                question=question,
                id=selected_option_id,
                is_correct=True
            ).exists()
            
            if is_correct:
                correct_count += 1
    
    score = (correct_count / total_questions) * 100 if total_questions > 0 else 0
    
    # Create submission record
    submission = QuizSubmission.objects.create(
        quiz=quiz,
        user=request.user,
        score=score,
        time_taken=time_taken
    )
    
    return Response({
        'success': True,
        'score': score,
        'correct_count': correct_count,
        'total_questions': total_questions
    })