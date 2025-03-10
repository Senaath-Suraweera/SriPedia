from django import forms
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.models import User
from .models import UserProfile

# Constants
STUDENT = 'student'
TEACHER = 'teacher'

class SignupForm(UserCreationForm):
    email = forms.EmailField(
        max_length=254, 
        required=True, 
        help_text='Required. Enter a valid email address.',
        widget=forms.EmailInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter your email'
        })
    )
    role = forms.ChoiceField(
        choices=[
            (STUDENT, 'Student'),
            (TEACHER, 'Teacher')
        ],
        widget=forms.RadioSelect(attrs={
            'class': 'form-check-input'
        }),
        initial=STUDENT
    )
    
    class Meta:
        model = User
        fields = ('username', 'email', 'password1', 'password2', 'role')
        widgets = {
            'username': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Choose a username'
            })
        }
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Add form-control class to password fields
        self.fields['password1'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Create a password'
        })
        self.fields['password2'].widget.attrs.update({
            'class': 'form-control',
            'placeholder': 'Confirm your password'
        })
    
    def save(self, commit=True):
        user = super().save(commit=True)
        # Create UserProfile
        UserProfile.objects.create(
            user=user,
            role=self.cleaned_data['role']
        )
        return user

class LoginForm(AuthenticationForm):
    username = forms.CharField(
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter your username'
        })
    )
    password = forms.CharField(
        widget=forms.PasswordInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter your password'
        })
    )
    remember_me = forms.BooleanField(
        required=False,
        widget=forms.CheckboxInput(attrs={
            'class': 'form-check-input'
        })
    )

# Add the missing UserRegistrationForm (seems to be referenced somewhere)
class UserRegistrationForm(UserCreationForm):
    email = forms.EmailField(max_length=254, required=True, help_text='Required. Enter a valid email address.')
    role = forms.ChoiceField(
        choices=[
            (STUDENT, 'Student'),
            (TEACHER, 'Teacher')
        ],
        widget=forms.RadioSelect,
        initial=STUDENT
    )
    
    class Meta:
        model = User
        fields = ('username', 'email', 'password1', 'password2', 'role')
    
    def save(self, commit=True):
        user = super().save(commit=True)
        # Create UserProfile
        UserProfile.objects.create(
            user=user,
            role=self.cleaned_data['role']
        )
        return user

# Firebase forms
class FirebaseSignupForm(forms.Form):
    username = forms.CharField(
        max_length=30, 
        required=True,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Choose a username'
        })
    )
    email = forms.EmailField(
        max_length=254, 
        required=True,
        widget=forms.EmailInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter your email'
        })
    )
    password1 = forms.CharField(
        widget=forms.PasswordInput(attrs={
            'class': 'form-control',
            'placeholder': 'Create a password'
        }), 
        required=True, 
        label="Password",
    )
    password2 = forms.CharField(
        widget=forms.PasswordInput(attrs={
            'class': 'form-control',
            'placeholder': 'Confirm your password'
        }), 
        required=True, 
        label="Confirm Password"
    )
    role = forms.ChoiceField(
        choices=[
            (STUDENT, 'Student'),
            (TEACHER, 'Teacher')
        ],
        widget=forms.RadioSelect(attrs={
            'class': 'form-check-input'
        }),
        initial=STUDENT
    )
    
    def clean(self):
        cleaned_data = super().clean()
        password1 = cleaned_data.get('password1')
        password2 = cleaned_data.get('password2')
        
        if password1 and password2 and password1 != password2:
            self.add_error('password2', "Passwords don't match")
        
        # Check if username already exists
        username = cleaned_data.get('username')
        if username and User.objects.filter(username=username).exists():
            self.add_error('username', "Username already exists")
            
        # Check if email already exists
        email = cleaned_data.get('email')
        if email and User.objects.filter(email=email).exists():
            self.add_error('email', "Email already registered")
            
        return cleaned_data

class FirebaseLoginForm(forms.Form):
    email = forms.EmailField(
        max_length=254, 
        required=True,
        widget=forms.EmailInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter your email'
        })
    )
    password = forms.CharField(
        widget=forms.PasswordInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter your password'
        }), 
        required=True
    )
    remember_me = forms.BooleanField(
        required=False, 
        initial=False,
        widget=forms.CheckboxInput(attrs={
            'class': 'form-check-input'
        })
    )