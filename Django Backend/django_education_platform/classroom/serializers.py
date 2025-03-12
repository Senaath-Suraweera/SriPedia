from rest_framework import serializers
from .models import Classroom, ClassSession, SessionQuestion, StudentResponse

class SessionQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = SessionQuestion
        fields = ['id', 'question_text', 'options']
        extra_kwargs = {'correct_answer': {'write_only': True}}

class ClassSessionSerializer(serializers.ModelSerializer):
    questions = SessionQuestionSerializer(many=True, read_only=True)
    
    class Meta:
        model = ClassSession
        fields = ['id', 'title', 'start_time', 'end_time', 'is_active', 'questions']

class ClassroomSerializer(serializers.ModelSerializer):
    active_session = serializers.SerializerMethodField()

    class Meta:
        model = Classroom
        fields = ['id', 'name', 'unique_id', 'teacher', 'students', 'active_session']

    def get_active_session(self, obj):
        active = obj.sessions.filter(is_active=True).first()
        return ClassSessionSerializer(active).data if active else None

class ClassroomDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = Classroom
        fields = ['id', 'name', 'teacher', 'students']  # Specify fields for detailed view

class ClassroomCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Classroom
        fields = ['name', 'teacher']  # Specify fields for creating a new classroom

class ClassroomUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Classroom
        fields = ['name']  # Specify fields that can be updated