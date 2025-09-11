from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Course
from .serializers import CourseSerializer, CourseListSerializer


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def course_list(request):
    """
    List user's courses or create a new course
    """
    if request.method == 'GET':
        courses = Course.objects.filter(user=request.user)
        serializer = CourseListSerializer(courses, many=True)
        return Response({
            'courses': serializer.data,
            'count': courses.count()
        }, status=status.HTTP_200_OK)
    
    elif request.method == 'POST':
        serializer = CourseSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            course = serializer.save()
            return Response({
                'course': CourseSerializer(course).data,
                'message': 'Course created successfully'
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def course_detail(request, course_id):
    """
    Retrieve, update, or delete a specific course
    """
    course = get_object_or_404(Course, id=course_id, user=request.user)
    
    if request.method == 'GET':
        serializer = CourseSerializer(course)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    elif request.method == 'PUT':
        serializer = CourseSerializer(
            course, 
            data=request.data, 
            context={'request': request}, 
            partial=True
        )
        if serializer.is_valid():
            course = serializer.save()
            return Response({
                'course': serializer.data,
                'message': 'Course updated successfully'
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    elif request.method == 'DELETE':
        course.delete()
        return Response({
            'message': 'Course deleted successfully'
        }, status=status.HTTP_204_NO_CONTENT)
