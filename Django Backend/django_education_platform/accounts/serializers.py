from rest_framework import serializers
from .models import User, StudentProfile, TeacherProfile

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'user_type', 'points')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = User.objects.create_user(**validated_data)
        if validated_data['user_type'] == 'student':
            StudentProfile.objects.create(user=user)
        else:
            TeacherProfile.objects.create(user=user)
        return user

class StudentProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    class Meta:
        model = StudentProfile
        fields = ('id', 'user', 'grade', 'completed_quizzes')

class TeacherProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    class Meta:
        model = TeacherProfile
        fields = ('id', 'user', 'subject', 'qualifications')