from rest_framework import serializers
from .models import Note
from courses.models import Course


class NoteSerializer(serializers.ModelSerializer):
    """
    Full serializer for Note model
    """
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    course_title = serializers.CharField(source='course.title', read_only=True)
    is_processed = serializers.ReadOnlyField()
    has_content = serializers.ReadOnlyField()
    
    class Meta:
        model = Note
        fields = (
            'id', 'title', 'course', 'course_title', 'user',
            'raw_content', 'key_points', 'detailed_notes',
            'audio_file_path', 'processing_status',
            'is_processed', 'has_content',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at', 'is_processed', 'has_content')
    
    def validate_course(self, value):
        """
        Validate that the course belongs to the current user
        """
        user = self.context['request'].user
        if value.user != user:
            raise serializers.ValidationError("You can only add notes to your own courses")
        return value


class NoteListSerializer(serializers.ModelSerializer):
    """
    Simplified serializer for note listing
    """
    course_title = serializers.CharField(source='course.title', read_only=True)
    is_processed = serializers.ReadOnlyField()
    
    class Meta:
        model = Note
        fields = (
            'id', 'title', 'course', 'course_title', 'processing_status',
            'is_processed', 'updated_at'
        )


class NoteCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating notes (minimal fields)
    """
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    
    class Meta:
        model = Note
        fields = ('title', 'course', 'user', 'raw_content')
    
    def validate_course(self, value):
        """
        Validate that the course belongs to the current user
        """
        user = self.context['request'].user
        if value.user != user:
            raise serializers.ValidationError("You can only add notes to your own courses")
        return value


class SearchNoteSerializer(serializers.Serializer):
    """
    Serializer for note search functionality
    """
    query = serializers.CharField(max_length=200, required=True)
    course_id = serializers.IntegerField(required=False)
