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
    
    # Run server on port 8000
    sys.argv = ['manage.py', 'runserver', '127.0.0.1:8000', '--noreload']
    
    try:
        execute_from_command_line(sys.argv)
    except KeyboardInterrupt:
        print("\nShutting down backend...")
        sys.exit(0)


if __name__ == '__main__':
    main()
