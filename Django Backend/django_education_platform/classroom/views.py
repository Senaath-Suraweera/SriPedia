from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Classroom, ClassSession, SessionQuestion, StudentResponse
from .serializers import ClassroomSerializer, ClassSessionSerializer, SessionQuestionSerializer

class ClassroomViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = ClassroomSerializer

    def get_queryset(self):
        if self.request.user.user_type == 'teacher':
            return Classroom.objects.filter(teacher=self.request.user)
        return Classroom.objects.filter(students=self.request.user)

    @action(detail=True, methods=['post'])
    def join(self, request, pk=None):
        try:
            classroom = Classroom.objects.get(unique_id=pk)
            if request.user.user_type == 'student':
                classroom.students.add(request.user)
                return Response({'message': 'Joined successfully'})
            return Response({'message': 'Only students can join classrooms'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        except Classroom.DoesNotExist:
            return Response({'message': 'Classroom not found'}, 
                          status=status.HTTP_404_NOT_FOUND)

class SessionViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = ClassSessionSerializer

    def get_queryset(self):
        classroom_id = self.kwargs.get('classroom_pk')
        return ClassSession.objects.filter(classroom_id=classroom_id)

    def perform_create(self, serializer):
        classroom = Classroom.objects.get(pk=self.kwargs['classroom_pk'])
        if self.request.user != classroom.teacher:
            raise PermissionError("Only teachers can create sessions")
        serializer.save(classroom=classroom)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_answer(request, pk):
    try:
        question = SessionQuestion.objects.get(pk=pk)
        session = question.session
        
        if not session.is_active:
            return Response({'message': 'Session is not active'}, status=400)
            
        answer = request.data.get('answer')
        is_correct = answer == question.correct_answer
        
        StudentResponse.objects.create(
            student=request.user,
            question=question,
            answer=answer,
            is_correct=is_correct
        )
        
        return Response({
            'is_correct': is_correct,
            'correct_answer': question.correct_answer if not is_correct else None
        })
        
    except SessionQuestion.DoesNotExist:
        return Response({'message': 'Question not found'}, status=404)