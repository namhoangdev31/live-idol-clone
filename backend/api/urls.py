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
    path('settings/lipsync', views.update_lipsync_settings, name='lipsync_settings'),

    # Control endpoints - CLEARED FOR AI VIDEO PIPELINE
    
    # Video streaming endpoints - CLEARED
    
    # Image upload endpoints
    path('images/upload', views.upload_image, name='upload_image'),
    path('images/<str:category>', views.list_images, name='list_images'),
    path('images/<str:category>/<str:filename>', views.delete_image, name='delete_image'),
    path('images/<str:category>/<str:filename>/favorite', views.toggle_image_favorite, name='toggle_favorite'),
    
    # OBS image integration - CLEARED
    
    # Scene Generation
    path('scene/generate', views.generate_scene, name='generate_scene'),
    
    # AI Video Generation
    path('video/idle', views.generate_idle, name='generate_idle'),
    path('process-comment', views.process_comment, name='process_comment'),
]
