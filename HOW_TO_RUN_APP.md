# How to Start the Personal Learning OS

This document explains exactly how to boot up your entire ecosystem from scratch using the terminal.

## Step 1: Start the AI Backend (Python)
The AI Server is the brain of your OS. It handles the LangChain RAG pipeline and talks to the Groq API. You must start this *before* you open the Flutter app.

1. Open a new Command Prompt or PowerShell terminal.
2. Navigate to the AI Server folder:
   ```bash
   cd "d:\study app\apps\ai_server"
   ```
3. Run the FastAPI server using the Python virtual environment:
   ```bash
   ..\..\venv\Scripts\python.exe main.py
   ```
   *You should see output saying "Uvicorn running on http://0.0.0.0:8000". Leave this terminal window open!*

## Step 2: Start the Frontend App (Flutter)
Now that the AI brain is running, you can launch the UI! You have two options for running the Flutter app:

### Option A: Run Natively on Windows (Recommended)
Running as a Native Windows App gives you the absolute best performance, zero browser security restrictions, and full access to your local hard drive to permanently save PDFs. 
*(Note: This requires Windows Developer Mode to be turned ON to support symlinks).*

1. Turn on Developer Mode: Press the Windows Key, type "Developer Settings", and toggle "Developer Mode" to ON.
2. Open a **new** terminal window (keep the AI terminal running).
3. Navigate to the client folder:
   ```bash
   cd "d:\study app\apps\client"
   ```
4. Run the Windows app:
   ```bash
   d:\flutter_sdk\bin\flutter.bat run -d windows
   ```

### Option B: Run on Web (Chrome)
If you don't want to turn on Developer Mode, you can easily run the app in Google Chrome. The database runs completely in-memory so it will work perfectly for your current session!

1. Open a **new** terminal window (keep the AI terminal running).
2. Navigate to the client folder:
   ```bash
   cd "d:\study app\apps\client"
   ```
3. Run the Web app:
   ```bash
   d:\flutter_sdk\bin\flutter.bat run -d chrome
   ```

---

That's it! As long as both terminals are running, your Personal Learning OS is fully alive.
