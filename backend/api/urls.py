"""
URL routing for API endpoints.
"""
from django.urls import path
from . import views
from . import obs_stream

urlpatterns = [
    path('health', views.health_check, name='health'),
    path('status', views.system_status, name='status'),
    path('speak', views.speak, name='speak'),
    path('voice-profiles', views.list_voice_profiles, name='voice_profiles'),
    # Video streaming endpoints
    path('stream/preview', obs_stream.stream_preview, name='stream_preview'),
    path('stream/snapshot', obs_stream.get_preview_snapshot, name='stream_snapshot'),
    # Image upload endpoints
    path('images/upload', views.upload_image, name='upload_image'),
    path('images/<str:category>', views.list_images, name='list_images'),
    path('images/<str:category>/<str:filename>', views.delete_image, name='delete_image'),
    path('images/<str:category>/<str:filename>/favorite', views.toggle_image_favorite, name='toggle_favorite'),
    # OBS image integration
    path('obs/set-background', views.set_obs_background, name='set_obs_background'),
    path('obs/add-overlay', views.add_obs_overlay, name='add_obs_overlay'),
    path('obs/recording-status', views.get_recording_status, name='recording_status'),
]
