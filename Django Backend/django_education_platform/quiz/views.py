from django.shortcuts import render
from django.http import JsonResponse
from .models import Quiz, Question, Answer
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import DailyQuiz, QuizAttempt, Question
from .serializers import DailyQuizSerializer, QuestionSerializer
import datetime

@login_required
def daily_quiz(request):
    today = timezone.now().date()
    quiz = Quiz.objects.filter(date=today).first()
    
    if not quiz:
        return JsonResponse({'message': 'No quiz available for today.'}, status=404)

    questions = quiz.questions.all()
    return JsonResponse({'quiz_id': quiz.id, 'questions': list(questions.values())})

@login_required
def submit_quiz(request):
    if request.method == 'POST':
        quiz_id = request.POST.get('quiz_id')
        answers = request.POST.getlist('answers[]')
        
        quiz = Quiz.objects.get(id=quiz_id)
        score = 0
        
        for answer in answers:
            question_id, selected_answer_id = answer.split(':')
            question = Question.objects.get(id=question_id)
            correct_answer = question.correct_answer.id
            
            if selected_answer_id == str(correct_answer):
                score += 1
        
        # Save the score to the user's profile or leaderboard
        # Assuming a method save_score exists
        request.user.save_score(quiz, score)
        
        return JsonResponse({'score': score})

    return JsonResponse({'message': 'Invalid request method.'}, status=400)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_daily_quiz(request):
    today = timezone.now().date()
    quiz = DailyQuiz.objects.filter(date=today, is_active=True).first()
    
    if not quiz:
        return Response({'message': 'No quiz available today'}, status=404)
    
    attempt = QuizAttempt.objects.filter(user=request.user, quiz=quiz).first()
    if attempt and attempt.completed:
        return Response({'message': 'Quiz already completed today'}, status=400)
        
    if not attempt:
        attempt = QuizAttempt.objects.create(user=request.user, quiz=quiz)
    
    current_question = quiz.questions.all()[attempt.current_question - 1]
    serializer = DailyQuizSerializer(quiz, context={'request': request})
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_answer(request):
    quiz_id = request.data.get('quiz_id')
    answer = request.data.get('answer')
    
    try:
        quiz = DailyQuiz.objects.get(id=quiz_id)
        attempt = QuizAttempt.objects.get(user=request.user, quiz=quiz)
        
        if attempt.completed:
            return Response({'message': 'Quiz already completed'}, status=400)
            
        current_question = quiz.questions.all()[attempt.current_question - 1]
        
        is_correct = answer == current_question.correct_answer
        response_data = {'is_correct': is_correct}
        
        if is_correct:
            attempt.score += current_question.points
            attempt.current_question += 1
            attempt.retry_count = 0
            
            if attempt.current_question > quiz.total_questions:
                attempt.completed = True
                request.user.points += attempt.score
                request.user.save()
                
        else:
            attempt.retry_count += 1
            if attempt.retry_count == 1:
                response_data['hint'] = current_question.hint
            elif attempt.retry_count >= 2:
                attempt.current_question += 1
                attempt.retry_count = 0
                
        attempt.save()
        response_data['progress'] = {
            'current_question': attempt.current_question,
            'total_questions': quiz.total_questions,
            'score': attempt.score
        }
        
        return Response(response_data)
        
    except (DailyQuiz.DoesNotExist, QuizAttempt.DoesNotExist):
        return Response({'message': 'Invalid quiz or attempt'}, status=404)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_progress(request):
    today = timezone.now().date()
    quiz = DailyQuiz.objects.filter(date=today, is_active=True).first()
    
    if not quiz:
        return Response({'message': 'No quiz available today'})
        
    attempt = QuizAttempt.objects.filter(user=request.user, quiz=quiz).first()
    
    if not attempt:
        return Response({
            'completed': False,
            'progress': 0,
            'score': 0
        })
        
    return Response({
        'completed': attempt.completed,
        'progress': (attempt.current_question - 1) / quiz.total_questions * 100,
        'score': attempt.score
    })