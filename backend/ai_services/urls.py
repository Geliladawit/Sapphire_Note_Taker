from django.urls import path
from . import views

app_name = 'ai_services'

urlpatterns = [
    path('upload-audio/', views.upload_and_process_audio, name='upload_and_process_audio'),
    path('status/<int:note_id>/', views.processing_status, name='processing_status'),
]
