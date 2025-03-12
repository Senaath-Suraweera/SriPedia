from django.test import TestCase
from .models import Leaderboard
from accounts.models import Student

class LeaderboardModelTest(TestCase):

    def setUp(self):
        self.student1 = Student.objects.create(username='student1', password='password1')
        self.student2 = Student.objects.create(username='student2', password='password2')
        self.leaderboard = Leaderboard.objects.create(student=self.student1, score=100)

    def test_leaderboard_creation(self):
        self.assertEqual(self.leaderboard.student.username, 'student1')
        self.assertEqual(self.leaderboard.score, 100)

    def test_leaderboard_score_update(self):
        self.leaderboard.score = 150
        self.leaderboard.save()
        self.assertEqual(self.leaderboard.score, 150)

    def test_leaderboard_ranking(self):
        Leaderboard.objects.create(student=self.student2, score=200)
        leaderboard_entries = Leaderboard.objects.order_by('-score')
        self.assertEqual(leaderboard_entries[0].student.username, 'student2')
        self.assertEqual(leaderboard_entries[1].student.username, 'student1')