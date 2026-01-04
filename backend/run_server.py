#!/usr/bin/env python
"""
Entry point for running the Django backend server.
This script is used by PyInstaller as the main entry point.
"""
import os
import sys
import django
from django.core.management import execute_from_command_line

# Set up Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

def main():
    """Run the Django development server."""
    print("Starting Live Idol Clone Backend...")
    print(f"Python version: {sys.version}")
    print(f"Django version: {django.get_version()}")
    
    # Initialize Django
    django.setup()
    
    # Auto-apply migrations to fix warnings/errors
    try:
        from django.core.management import call_command
        # Optional: makemigrations usually not needed in prod/runtime unless models changed dynamically, 
        # but safe to include for "api" app if we had models.
        # call_command('makemigrations', 'api') 
        print("Applying database migrations...")
        call_command('migrate')
    except Exception as e:
        print(f"Warning: Migration failed: {e}")
    
    # Run server on port 8000
    sys.argv = ['manage.py', 'runserver', '0.0.0.0:8000', '--noreload']
    
    try:
        execute_from_command_line(sys.argv)
    except KeyboardInterrupt:
        print("\nShutting down backend...")
        sys.exit(0)


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        import traceback
        import time
        
        error_msg = traceback.format_exc()
        print("\n" + "="*50)
        print("CRITICAL STARTUP ERROR")
        print("="*50)
        print(error_msg)
        print("="*50)
        
        # Write to log file
        try:
            with open("backend_crash_log.txt", "w") as f:
                f.write(error_msg)
            print("Error details written to backend_crash_log.txt")
        except:
            print("Could not write log file")
            
        print("\nPress Enter to exit...")
        input()
