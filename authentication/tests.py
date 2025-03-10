from django.test import TestCase
from django.urls import reverse
from django.contrib.auth.models import User  # Use the standard User model instead of CustomUser

class AuthenticationTests(TestCase):

    def setUp(self):
        self.student_user = User.objects.create_user(
            username='studentuser',
            password='testpassword'
        )
        self.teacher_user = User.objects.create_user(
            username='teacheruser',
            password='testpassword'
        )

    def test_login_page_status_code(self):
        response = self.client.get(reverse('login'))
        self.assertEqual(response.status_code, 200)

    def test_signup_page_status_code(self):
        response = self.client.get(reverse('signup'))
        self.assertEqual(response.status_code, 200)

    def test_login_with_valid_credentials(self):
        response = self.client.post(reverse('login'), {
            'username': 'studentuser',
            'password': 'testpassword'
        })
        self.assertEqual(response.status_code, 302)  # Redirect on successful login
        # Also check the redirect location if possible
        self.assertRedirects(response, reverse('dashboard'))

    def test_login_with_invalid_credentials(self):
        response = self.client.post(reverse('login'), {
            'username': 'studentuser',
            'password': 'wrongpassword'
        })
        self.assertEqual(response.status_code, 200)  # Stay on the login page

    def test_signup_creates_new_user(self):
        # Count users before
        user_count_before = User.objects.count()
        
        # Attempt to create new user
        response = self.client.post(reverse('signup'), {
            'username': 'newuser',
            'password1': 'Complex@Password123',
            'password2': 'Complex@Password123',
            'role': 'student',
            'email': 'newuser@example.com',
        })
        
        # Verify one new user was created
        self.assertEqual(User.objects.count(), user_count_before + 1)
        self.assertEqual(response.status_code, 302)  # Redirect after signup

class BasicTest(TestCase):
    def test_basic(self):
        """A simple test to verify the testing framework works"""
        self.assertEqual(1, 1)

    def test_user_creation(self):
        """Test that we can create a user"""
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpassword123'
        )
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(User.objects.get(username='testuser').email, 'test@example.com')