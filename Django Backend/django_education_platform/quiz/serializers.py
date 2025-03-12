from rest_framework import serializers
from .models import DailyQuiz, Question, QuizAttempt, Answer, Quiz

class AnswerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Answer
        fields = ['id', 'question', 'text', 'is_correct']

class QuestionSerializer(serializers.ModelSerializer):
    answers = AnswerSerializer(many=True)

    class Meta:
        model = Question
        fields = ['id', 'quiz', 'text', 'answers']
        exclude = ['correct_answer']

    def to_representation(self, instance):
        data = super().to_representation(instance)
        answers = [
            instance.correct_answer,
            instance.wrong_answer1,
            instance.wrong_answer2,
            instance.wrong_answer3
        ]
        import random
        random.shuffle(answers)
        data['answers'] = answers
        return data

class QuizSerializer(serializers.ModelSerializer):
    questions = QuestionSerializer(many=True)

    class Meta:
        model = Quiz
        fields = ['id', 'title', 'description', 'questions']

class DailyQuizSerializer(serializers.ModelSerializer):
    current_question = QuestionSerializer(read_only=True)
    progress = serializers.SerializerMethodField()

    class Meta:
        model = DailyQuiz
        fields = ['id', 'date', 'current_question', 'progress']

    def get_progress(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            attempt = QuizAttempt.objects.filter(
                user=request.user,
                quiz=obj
            ).first()
            if attempt:
                return {
                    'current_question': attempt.current_question,
                    'total_questions': obj.total_questions,
                    'score': attempt.score
                }
        return None