from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User
from .models import UserProfile
from django.core.exceptions import ValidationError

class LoginForm(forms.Form):
    username = forms.CharField(max_length=150)
    password = forms.CharField(widget=forms.PasswordInput)

class SignupForm(UserCreationForm):
    """
    Form for user registration that includes role field
    """
    ROLE_CHOICES = [
        (UserProfile.STUDENT, 'Student'),
        (UserProfile.TEACHER, 'Teacher')
    ]
    
    role = forms.ChoiceField(
        choices=ROLE_CHOICES,
        widget=forms.RadioSelect,
        required=True
    )
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password1', 'password2']
    
    def save(self, commit=True):
        # Save the user
        user = super().save(commit=True)
        
        # Create profile with role
        UserProfile.objects.create(
            user=user,
            role=self.cleaned_data['role']
        )
        
        return user