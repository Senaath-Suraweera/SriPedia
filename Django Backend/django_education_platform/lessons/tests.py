from django.test import TestCase
from .models import Lesson

class LessonModelTest(TestCase):

    def setUp(self):
        self.lesson = Lesson.objects.create(
            title="Sample Lesson",
            content="This is a sample lesson content.",
            teacher_id=1  # Assuming a teacher with ID 1 exists
        )

    def test_lesson_creation(self):
        self.assertEqual(self.lesson.title, "Sample Lesson")
        self.assertEqual(self.lesson.content, "This is a sample lesson content.")

    def test_lesson_str(self):
        self.assertEqual(str(self.lesson), "Sample Lesson")

    def test_lesson_teacher_association(self):
        self.assertEqual(self.lesson.teacher_id, 1)

    def test_lesson_content_length(self):
        self.assertTrue(len(self.lesson.content) > 0)