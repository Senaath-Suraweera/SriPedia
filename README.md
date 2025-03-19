# SriPedia Auth and Quiz
 quiz feature and authentication with database access

# SriPedia API Documentation

This document outlines all available API endpoints for the SriPedia platform, a comprehensive educational system with classroom management, quiz functionality, and historical timeline features.

## Authentication

### User Registration
- **URL**: `/auth/api/signup/`
- **Method**: `POST`
- **Description**: Register a new user
- **Request Body**:
  ```json
  {
    "username": "newuser",
    "password": "securepassword",
    "role": "student"  // Can be "student" or "teacher"
  }
  ```
- **Response**:
  ```json
  {
    "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",
    "user_id": 1,
    "username": "newuser",
    "role": "student"
  }
  ```

### User Login
- **URL**: `/auth/api/login/`
- **Method**: `POST`
- **Description**: Authenticate a user and obtain an authentication token
- **Request Body**:
  ```json
  {
    "username": "myusername",
    "password": "mypassword"
  }
  ```
- **Response**:
  ```json
  {
    "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",
    "user_id": 1,
    "username": "myusername",
    "role": "student"
  }
  ```

### User Profile
- **URL**: `/auth/api/profile/`
- **Method**: `GET`
- **Description**: Retrieve the current user's profile information
- **Authentication**: Required (Token)
- **Response**:
  ```json
  {
    "id": 1,
    "username": "myusername",
    "role": "student",
    "firebase_uid": "550e8400-e29b-41d4-a716-446655440000"
  }
  ```

## Classroom Management

### List/Create Classrooms
- **URL**: `/auth/api/classrooms/`
- **Method**: `GET` (list) / `POST` (create)
- **Description**: List all classrooms or create a new classroom (teachers only)
- **Authentication**: Required (Token)
- **Create Request Body**:
  ```json
  {
    "name": "History 101",
    "description": "Introduction to World History"
  }
  ```
- **Response (List)**:
  ```json
  {
    "count": 1,
    "next": null,
    "previous": null,
    "results": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "History 101",
        "description": "Introduction to World History",
        "join_code": "ABC123",
        "teacher": 1,
        "created_at": "2023-06-15T10:30:00Z"
      }
    ]
  }
  ```

### Retrieve/Update/Delete Classroom
- **URL**: `/auth/api/classrooms/<uuid:classroom_id>/`
- **Methods**: `GET` (retrieve) / `PUT`/`PATCH` (update) / `DELETE` (delete)
- **Description**: Manage a specific classroom
- **Authentication**: Required (Token)
- **Permissions**: Teacher who owns the classroom (for write operations)
- **Update Request Body**:
  ```json
  {
    "name": "Updated History 101",
    "description": "Updated description"
  }
  ```

### Join Classroom (Students)
- **URL**: `/auth/api/classrooms/join/`
- **Method**: `POST`
- **Description**: Allow a student to join a classroom using a join code
- **Authentication**: Required (Token)
- **Request Body**:
  ```json
  {
    "join_code": "ABC123"
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "classroom": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "History 101"
    }
  }
  ```

## Quiz Management

### List/Create Quizzes for a Classroom
- **URL**: `/auth/api/classrooms/<uuid:classroom_id>/quizzes/`
- **Method**: `GET` (list) / `POST` (create)
- **Description**: List all quizzes in a classroom or create a new quiz (teachers only)
- **Authentication**: Required (Token)
- **Create Request Body**:
  ```json
  {
    "title": "World War II Quiz",
    "description": "Test your knowledge of WW2 events",
    "is_published": false
  }
  ```
- **Response (List)**:
  ```json
  {
    "count": 1,
    "next": null,
    "previous": null,
    "results": [
      {
        "id": 1,
        "classroom": "550e8400-e29b-41d4-a716-446655440000",
        "title": "World War II Quiz",
        "description": "Test your knowledge of WW2 events",
        "is_published": true,
        "created_at": "2023-06-16T14:25:00Z",
        "updated_at": "2023-06-16T14:25:00Z",
        "questions_count": 5
      }
    ]
  }
  ```

### Retrieve/Update/Delete Quiz
- **URL**: `/auth/api/classrooms/<uuid:classroom_id>/quizzes/<int:pk>/`
- **Methods**: `GET` (retrieve) / `PUT`/`PATCH` (update) / `DELETE` (delete)
- **Description**: Manage a specific quiz in a classroom
- **Authentication**: Required (Token)
- **Permissions**: Teacher who owns the classroom (for write operations)
- **Update Request Body**:
  ```json
  {
    "title": "Updated Quiz Title",
    "description": "Updated description",
    "is_published": true
  }
  ```

### Submit Quiz Answers
- **URL**: `/auth/api/quizzes/<int:quiz_id>/submit/`
- **Method**: `POST`
- **Description**: Submit answers to a quiz and get results
- **Authentication**: Required (Token)
- **Request Body**:
  ```json
  {
    "answers": {
      "1": 3,
      "2": 1,
      "3": 4,
      "4": 2,
      "5": 1
    },
    "time_taken": 300
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "score": 80.0,
    "correct_count": 4,
    "total_questions": 5
  }
  ```

## User Management (Admin Only)

### List/Create Users
- **URL**: `/auth/api/users/`
- **Method**: `GET` (list) / `POST` (create)
- **Description**: Admin functionality to list or create users
- **Authentication**: Required (Token)
- **Permissions**: Admin only
- **Create Request Body**:
  ```json
  {
    "username": "newuser",
    "password": "securepassword",
    "role": "student"
  }
  ```

### Retrieve/Update/Delete User
- **URL**: `/auth/api/users/<int:pk>/`
- **Methods**: `GET` (retrieve) / `PUT`/`PATCH` (update) / `DELETE` (delete)
- **Description**: Admin functionality to manage users
- **Authentication**: Required (Token)
- **Permissions**: Admin only
- **Update Request Body**:
  ```json
  {
    "username": "updatedusername",
    "role": "teacher"
  }
  ```

## Historical Timeline

### Get Events for a Year
- **URL**: `/auth/api/events-for-year/<int:year>/`
- **Method**: `GET`
- **Description**: Get historical events for a specific year
- **Response**:
  ```json
  {
    "year": 1945,
    "events": [
      {
        "id": 1,
        "title": "End of World War II",
        "description": "World War II ended with the surrender of Japan",
        "date": "1945-09-02",
        "image_url": "https://example.com/ww2_end.jpg"
      }
    ]
  }
  ```

## Authentication Requirements

All API endpoints require authentication except:
- `/auth/api/login/`
- `/auth/api/signup/`

## Authentication Method

The API uses Token Authentication. Include the token in your request headers:

```
Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
```

## Content Types

All requests and responses use JSON format. Include the header:

```
Content-Type: application/json
```

## Error Responses

Error responses follow this format:

```json
{
  "error": "Error message description"
}
```

Or field-specific errors:

```json
{
  "username": ["Username already exists"],
  "password": ["Password must be at least 8 characters long"]
}
```

## Response Status Codes

- `200 OK`: Request successful
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication failed or not provided
- `403 Forbidden`: Permission denied
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server-side error

## Pagination

List endpoints return paginated results with the following structure:

```json
{
  "count": 100,
  "next": "https://api.example.org/auth/api/resource/?page=2",
  "previous": null,
  "results": [
    // array of items
  ]
}
```

The default page size is 10 items. You can adjust the page size using the `page_size` query parameter (up to 100).