# Project Prerequisites

Before running this project, ensure you have the following tools installed on your local machine:

* **Python:** Version 3.10 or higher (Required for FastAPI backend)
* **Flutter SDK:** Latest stable version (Required for frontend mobile/desktop app)
* **PostgreSQL:** Installed and running locally for database management
* **Git:** For version control
* **Android Studio / VS Code:** With Flutter and Dart extensions installed


# Environment Configuration Template

Copy the structure of this file into your local environment setup script (e.g., env.bat or env.ps1) and fill in your actual local configuration values. Do NOT commit your actual credentials to GitHub.

## Backend Configuration (FastAPI & Database)
* DATABASE_URL=postgresql://<username>:<password>@localhost:5432/<database_name>
* HOST=127.0.0.1
* PORT=8000

## Frontend & Services Configuration
* API_BASE_URL=http://127.0.0.1:8000
* GOOGLE_API_KEY=your_actual_google_api_key_here