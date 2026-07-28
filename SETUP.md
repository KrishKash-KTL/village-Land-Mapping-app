# Project Setup Guide (Village Mapping App)

This guide outlines the steps to set up the runtime environment, dependencies, and external tools that are excluded from version control due to GitHub file size constraints.

---

## 1. Quick Terminal Setup Commands

Run these commands in your terminal after cloning the repository to quickly set up both the backend and frontend environments:

### Backend Setup Commands
```bash
# Navigate to the backend directory
cd backend

# Create a Python virtual environment
python -m venv venv

# Activate the virtual environment (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# Install required Python packages
pip install -r requirements.txt

# Run the backend application
python main.py

# Navigate to the frontend directory (from root)
cd frontend

# Fetch all Flutter dependencies
flutter pub get

# Run the application
flutter run