# Django Education Platform

This project is a Django-based education platform that supports user authentication for two types of users: Students and Teachers. It includes various features such as Daily Quiz, Lesson Page, Timeline, Classroom, and Leaderboard.

## Features

- **User Authentication**: Supports registration, login, and profile management for Students and Teachers.
- **Daily Quiz**: Allows students to participate in daily quizzes, track their scores, and view results.
- **Lesson Page**: Provides access to lesson content, including summaries and detailed views.
- **Timeline**: Displays a timeline of historical events relevant to the curriculum.
- **Classroom**: Facilitates classroom management, including creating classrooms and managing student participation.
- **Leaderboard**: Ranks students based on their quiz scores and overall performance.

## Setup Instructions

1. **Clone the repository**:
   ```
   git clone <repository-url>
   cd django_education_platform
   ```

2. **Install dependencies**:
   Ensure you have Python and pip installed, then run:
   ```
   pip install -r requirements.txt
   ```

3. **Run migrations**:
   ```
   python manage.py migrate
   ```

4. **Create a superuser** (optional, for admin access):
   ```
   python manage.py createsuperuser
   ```

5. **Run the development server**:
   ```
   python manage.py runserver
   ```

6. **Access the application**:
   Open your web browser and go to `http://127.0.0.1:8000/`.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.