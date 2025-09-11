from rest_framework import serializers
from .models import Course


class CourseSerializer(serializers.ModelSerializer):
    """
    Serializer for Course model
    """
    notes_count = serializers.ReadOnlyField()
    user = serializers.HiddenField(default=serializers.CurrentUserDefault())
    
    class Meta:
        model = Course
        fields = ('id', 'title', 'description', 'color', 'notes_count', 'created_at', 'updated_at', 'user')
        read_only_fields = ('id', 'created_at', 'updated_at', 'notes_count')
    
    def validate_title(self, value):
        """
        Validate course title uniqueness for the user
        """
        user = self.context['request'].user
        if Course.objects.filter(user=user, title=value).exclude(pk=self.instance.pk if self.instance else None).exists():
            raise serializers.ValidationError("You already have a course with this title")
        return value


class CourseListSerializer(serializers.ModelSerializer):
    """
    Simplified serializer for course listing
    """
    notes_count = serializers.ReadOnlyField()
    
    class Meta:
        model = Course
        fields = ('id', 'title', 'color', 'notes_count', 'updated_at')
