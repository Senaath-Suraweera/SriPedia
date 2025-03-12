from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from .models import Lesson
from .serializers import LessonSerializer
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

@api_view(['GET'])
def lesson_list(request):
    lessons = Lesson.objects.all()
    serializer = LessonSerializer(lessons, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def lesson_detail(request, pk):
    lesson = get_object_or_404(Lesson, pk=pk)
    serializer = LessonSerializer(lesson)
    return Response(serializer.data)

@api_view(['POST'])
def create_lesson(request):
    serializer = LessonSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def update_lesson(request, pk):
    lesson = get_object_or_404(Lesson, pk=pk)
    serializer = LessonSerializer(lesson, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def delete_lesson(request, pk):
    lesson = get_object_or_404(Lesson, pk=pk)
    lesson.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)

class LessonListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Lesson.objects.all().order_by('created_at')
    serializer_class = LessonSerializer

class LessonDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Lesson.objects.all()
    serializer_class = LessonSerializer