from django.core.management.base import BaseCommand
from authentication.quiz_generator import generate_daily_quiz

class Command(BaseCommand):
    help = 'Generate a daily quiz from textbook data stored in Firebase'

    def add_arguments(self, parser):
        parser.add_argument('--questions', type=int, default=20,
                            help='Number of questions to generate')

    def handle(self, *args, **options):
        num_questions = options['questions']
        self.stdout.write(f"Generating daily quiz with {num_questions} questions...")
        
        quiz = generate_daily_quiz(num_questions)
        
        if quiz:
            self.stdout.write(self.style.SUCCESS(
                f"Successfully generated quiz for {quiz['date']} with {quiz['total_questions']} questions"
            ))
        else:
            self.stdout.write(self.style.ERROR("Failed to generate daily quiz"))