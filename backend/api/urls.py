"""
URL routing for API endpoints.
"""
from django.urls import path
from . import views

urlpatterns = [
    path('health', views.health_check, name='health'),
    path('status', views.system_status, name='status'),
    path('speak', views.speak, name='speak'),
    path('voice-profiles', views.list_voice_profiles, name='voice_profiles'),
]
