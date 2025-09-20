from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Q
from .models import Note
from courses.models import Course
from .serializers import (
    NoteSerializer,
    NoteListSerializer,
    NoteCreateSerializer,
    SearchNoteSerializer
)
from ai_services.services import process_note_with_ai


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def note_list(request):
    """
    List user's notes or create a new note
    """
    if request.method == 'GET':
        notes = Note.objects.filter(user=request.user)
        
        # Filter by course if provided
        course_id = request.query_params.get('course_id')
        if course_id:
            notes = notes.filter(course_id=course_id)
        
        serializer = NoteListSerializer(notes, many=True)
        return Response({
            'notes': serializer.data,
            'count': notes.count()
        }, status=status.HTTP_200_OK)
    
    elif request.method == 'POST':
        serializer = NoteCreateSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            note = serializer.save()
            
            # Trigger AI processing if raw_content is provided
            if note.raw_content:
                try:
                    process_note_with_ai(note.id)
                except Exception as e:
                    # Log error but don't fail the creation
                    print(f"AI processing failed for note {note.id}: {str(e)}")
            
            return Response({
                'note': NoteSerializer(note).data,
                'message': 'Note created successfully'
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def note_detail(request, note_id):
    """
    Retrieve, update, or delete a specific note
    """
    note = get_object_or_404(Note, id=note_id, user=request.user)
    
    if request.method == 'GET':
        serializer = NoteSerializer(note)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    elif request.method == 'PUT':
        old_raw_content = note.raw_content
        serializer = NoteSerializer(
            note, 
            data=request.data, 
            context={'request': request}, 
            partial=True
        )
        if serializer.is_valid():
            note = serializer.save()
            
            # Re-process with AI if raw_content changed
            if note.raw_content != old_raw_content and note.raw_content:
                try:
                    process_note_with_ai(note.id)
                except Exception as e:
                    print(f"AI processing failed for note {note.id}: {str(e)}")
            
            return Response({
                'note': serializer.data,
                'message': 'Note updated successfully'
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    elif request.method == 'DELETE':
        note.delete()
        return Response({
            'message': 'Note deleted successfully'
        }, status=status.HTTP_204_NO_CONTENT)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reprocess_note(request, note_id):
    """
    Manually trigger AI reprocessing for a note and return the updated note
    """
    note = get_object_or_404(Note, id=note_id, user=request.user)
    
    if not note.raw_content:
        return Response({
            'error': 'Cannot reprocess note without raw content'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Process the note and get the updated note object
        updated_note = process_note_with_ai(note.id)
        
        # Return the updated note data
        from notes.serializers import NoteSerializer
        serializer = NoteSerializer(updated_note)
        return Response({
            'message': 'Note reprocessed successfully',
            'note': serializer.data
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': f'AI processing failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def search_notes(request):
    """
    Search notes by content
    """
    serializer = SearchNoteSerializer(data=request.data)
    if serializer.is_valid():
        query = serializer.validated_data['query']
        course_id = serializer.validated_data.get('course_id')
        
        # Build search query
        notes = Note.objects.filter(user=request.user)
        
        if course_id:
            notes = notes.filter(course_id=course_id)
        
        # Search across all text fields
        search_query = Q(title__icontains=query) | \
                      Q(raw_content__icontains=query) | \
                      Q(detailed_notes__icontains=query)
        
        # Search in key_points array (this might need adjustment based on MongoDB setup)
        try:
            notes = notes.filter(search_query)
        except Exception:
            # Fallback to simpler search if complex query fails
            notes = notes.filter(
                Q(title__icontains=query) | Q(raw_content__icontains=query)
            )
        
        serializer = NoteListSerializer(notes, many=True)
        return Response({
            'notes': serializer.data,
            'count': notes.count(),
            'query': query
        }, status=status.HTTP_200_OK)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
