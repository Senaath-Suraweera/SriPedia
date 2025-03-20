import uuid
from rest_framework import status, viewsets, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django_auth_project.firebase import save_user_to_firebase
from .models import CustomUser
from rest_framework import serializers

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'role', 'password', 'firebase_uid']
        extra_kwargs = {
            'firebase_uid': {'read_only': True}
        }
        
    def create(self, validated_data):
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password'],
            role=validated_data.get('role', CustomUser.STUDENT)
        )
        return user

@api_view(['POST'])
def api_signup(request):
    """API endpoint for user registration"""
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        # Generate Firebase UID
        firebase_uid = str(uuid.uuid4())
        
        # Save user with firebase_uid
        user = serializer.save()
        user.firebase_uid = firebase_uid
        user.save()
        
        # Save to Firebase
        save_user_to_firebase(
            user_id=firebase_uid,
            username=user.username,
            role=user.role
        )
        
        # Generate auth token
        token, created = Token.objects.get_or_create(user=user)
        
        return Response({
            'token': token.key,
            'user_id': user.pk,
            'username': user.username,
            'role': user.role
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def api_login(request):
    """API endpoint for user login"""
    username = request.data.get('username')
    password = request.data.get('password')
    
    user = authenticate(username=username, password=password)
    if user:
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user_id': user.pk,
            'username': user.username,
            'role': user.role
        })
    return Response({'error': 'Invalid credentials'}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def api_user_profile(request):
    """Get the current user's profile"""
    serializer = UserSerializer(request.user)
    return Response(serializer.data)

class UserViewSet(viewsets.ModelViewSet):
    """API endpoint for user CRUD operations (admin only)"""
    queryset = CustomUser.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]