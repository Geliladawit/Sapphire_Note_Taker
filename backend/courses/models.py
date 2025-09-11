from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinLengthValidator

User = get_user_model()


class Course(models.Model):
    """
    Course model to organize notes
    """
    title = models.CharField(
        max_length=200,
        validators=[MinLengthValidator(2)],
        help_text='Course title'
    )
    description = models.TextField(
        blank=True,
        help_text='Course description'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='courses',
        help_text='Course owner'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    color = models.CharField(
        max_length=7,
        default='#3B82F6',
        help_text='Hex color code for UI'
    )
    
    class Meta:
        db_table = 'courses'
        ordering = ['-updated_at']
        unique_together = ['user', 'title']
        
    def __str__(self):
        return f"{self.title} - {self.user.email}"
    
    @property
    def notes_count(self):
        """Return the number of notes in this course"""
        return self.notes.count()
