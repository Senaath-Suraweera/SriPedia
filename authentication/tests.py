from django.test import TestCase
from django.urls import reverse
from .models import CustomUser

class AuthenticationTests(TestCase):

    def setUp(self):
        self.student_user = CustomUser.objects.create_user(
            username='studentuser',
            password='testpassword',
            role='student'
        )
        self.teacher_user = CustomUser.objects.create_user(
            username='teacheruser',
            password='testpassword',
            role='teacher'
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

    def test_login_with_invalid_credentials(self):
        response = self.client.post(reverse('login'), {
            'username': 'studentuser',
            'password': 'wrongpassword'
        })
        self.assertEqual(response.status_code, 200)  # Stay on the login page

    def test_signup_creates_new_user(self):
        response = self.client.post(reverse('signup'), {
            'username': 'newuser',
            'password1': 'newpassword',
            'password2': 'newpassword',
            'role': 'student'
        })
        self.assertEqual(CustomUser.objects.count(), 3)  # Check if new user is created
        self.assertEqual(response.status_code, 302)  # Redirect after signup