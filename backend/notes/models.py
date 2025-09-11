from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinLengthValidator
from courses.models import Course

User = get_user_model()


class Note(models.Model):
    """
    Note model with AI-generated content
    """
    title = models.CharField(
        max_length=200,
        validators=[MinLengthValidator(2)],
        help_text='Note title'
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='notes',
        help_text='Associated course'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notes',
        help_text='Note owner'
    )
    
    # Content fields
    raw_content = models.TextField(
        blank=True,
        help_text='Raw transcribed content from speech-to-text'
    )
    key_points = models.JSONField(
        default=list,
        help_text='AI-generated key points as array of strings'
    )
    detailed_notes = models.TextField(
        blank=True,
        help_text='AI-generated detailed and structured notes'
    )
    
    # Audio file path (optional, for storing original recording)
    audio_file_path = models.CharField(
        max_length=500,
        blank=True,
        help_text='Path to original audio file'
    )
    
    # Processing status
    processing_status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('transcribing', 'Transcribing'),
            ('processing', 'AI Processing'),
            ('completed', 'Completed'),
            ('failed', 'Failed')
        ],
        default='pending',
        help_text='Current processing status'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'notes'
        ordering = ['-updated_at']
        
    def __str__(self):
        return f"{self.title} - {self.course.title}"
    
    @property
    def is_processed(self):
        """Check if note has been fully processed by AI"""
        return self.processing_status == 'completed' and bool(self.key_points or self.detailed_notes)
    
    @property
    def has_content(self):
        """Check if note has any content"""
        return bool(self.raw_content or self.key_points or self.detailed_notes)
