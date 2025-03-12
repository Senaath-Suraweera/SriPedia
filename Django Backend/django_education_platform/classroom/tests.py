from django.test import TestCase
from .models import Classroom

class ClassroomModelTest(TestCase):

    def setUp(self):
        self.classroom = Classroom.objects.create(
            name="Math 101",
            description="Introduction to Mathematics",
            teacher_id=1
        )

    def test_classroom_creation(self):
        self.assertEqual(self.classroom.name, "Math 101")
        self.assertEqual(self.classroom.description, "Introduction to Mathematics")

    def test_classroom_str(self):
        self.assertEqual(str(self.classroom), "Math 101")

    def test_classroom_teacher_association(self):
        self.assertEqual(self.classroom.teacher_id, 1)  # Assuming teacher_id is an integer reference to a Teacher model

    def test_classroom_enrollment(self):
        # Assuming there is a method to enroll students
        self.classroom.enroll_student(1)  # Assuming 1 is a valid student ID
        self.assertIn(1, self.classroom.students.all())  # Assuming students is a related field in Classroom model

    def test_classroom_participation(self):
        # Assuming there is a method to check participation
        self.classroom.add_participant(1)  # Assuming 1 is a valid participant ID
        self.assertTrue(self.classroom.is_participant(1))  # Assuming is_participant is a method in Classroom model