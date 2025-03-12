from django.test import TestCase
from .models import Quiz, Question, Answer
from django.contrib.auth import get_user_model

User = get_user_model()

class QuizModelTests(TestCase):

    def setUp(self):
        self.teacher = User.objects.create_user(username='teacher', password='password123', is_teacher=True)
        self.student = User.objects.create_user(username='student', password='password123', is_student=True)
        self.quiz = Quiz.objects.create(title='Sample Quiz', created_by=self.teacher)

    def test_quiz_creation(self):
        self.assertEqual(self.quiz.title, 'Sample Quiz')
        self.assertEqual(self.quiz.created_by, self.teacher)

class QuestionModelTests(TestCase):

    def setUp(self):
        self.teacher = User.objects.create_user(username='teacher', password='password123', is_teacher=True)
        self.quiz = Quiz.objects.create(title='Sample Quiz', created_by=self.teacher)
        self.question = Question.objects.create(quiz=self.quiz, text='What is 2 + 2?')

    def test_question_creation(self):
        self.assertEqual(self.question.text, 'What is 2 + 2?')
        self.assertEqual(self.question.quiz, self.quiz)

class AnswerModelTests(TestCase):

    def setUp(self):
        self.teacher = User.objects.create_user(username='teacher', password='password123', is_teacher=True)
        self.quiz = Quiz.objects.create(title='Sample Quiz', created_by=self.teacher)
        self.question = Question.objects.create(quiz=self.quiz, text='What is 2 + 2?')
        self.answer = Answer.objects.create(question=self.question, text='4', is_correct=True)

    def test_answer_creation(self):
        self.assertEqual(self.answer.text, '4')
        self.assertTrue(self.answer.is_correct)
        self.assertEqual(self.answer.question, self.question)