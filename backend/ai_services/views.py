import os
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from notes.models import Note
from .services import process_audio_to_note


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def upload_and_process_audio(request):
    """
    Upload audio file and process it to create a note
    """
    audio_file = request.FILES.get('audio_file')
    note_id = request.data.get('note_id')
    
    if not audio_file:
        return Response({
            'error': 'No audio file provided'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    if not note_id:
        return Response({
            'error': 'Note ID is required'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Verify note exists and belongs to user
    note = get_object_or_404(Note, id=note_id, user=request.user)
    
    try:
        # Save audio file
        file_name = f"audio_{note_id}_{audio_file.name}"
        file_path = default_storage.save(f"audio/{file_name}", ContentFile(audio_file.read()))
        full_file_path = default_storage.path(file_path)
        
        # Process audio to note
        processed_note = process_audio_to_note(full_file_path, note_id)
        
        return Response({
            'note_id': note_id,
            'message': 'Audio processed successfully',
            'processing_status': processed_note.processing_status
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        return Response({
            'error': f'Audio processing failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def processing_status(request, note_id):
    """
    Get processing status of a note
    """
    note = get_object_or_404(Note, id=note_id, user=request.user)
    
    return Response({
        'note_id': note_id,
        'processing_status': note.processing_status,
        'is_processed': note.is_processed,
        'has_content': note.has_content
    }, status=status.HTTP_200_OK)
