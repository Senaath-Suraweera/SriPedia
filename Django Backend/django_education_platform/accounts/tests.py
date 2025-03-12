from django.test import TestCase
from django.contrib.auth import get_user_model

User = get_user_model()

class UserModelTests(TestCase):

    def test_create_student(self):
        student = User.objects.create_user(
            username='student1',
            password='password123',
            user_type='student'
        )
        self.assertEqual(student.username, 'student1')
        self.assertTrue(student.check_password('password123'))
        self.assertEqual(student.user_type, 'student')

    def test_create_teacher(self):
        teacher = User.objects.create_user(
            username='teacher1',
            password='password123',
            user_type='teacher'
        )
        self.assertEqual(teacher.username, 'teacher1')
        self.assertTrue(teacher.check_password('password123'))
        self.assertEqual(teacher.user_type, 'teacher')

    def test_student_login(self):
        student = User.objects.create_user(
            username='student2',
            password='password123',
            user_type='student'
        )
        self.assertTrue(self.client.login(username='student2', password='password123'))

    def test_teacher_login(self):
        teacher = User.objects.create_user(
            username='teacher2',
            password='password123',
            user_type='teacher'
        )
        self.assertTrue(self.client.login(username='teacher2', password='password123'))

    def test_invalid_login(self):
        response = self.client.post('/accounts/login/', {'username': 'invalid', 'password': 'wrong'})
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Please enter a correct username and password.")