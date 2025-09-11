from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed
from django.contrib.auth import get_user_model
from .jwt_utils import get_user_from_token

User = get_user_model()


class JWTAuthentication(BaseAuthentication):
    """
    Custom JWT authentication class for Django REST Framework
    """
    
    def authenticate(self, request):
        """
        Authenticate the request using JWT token
        """
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        
        if not auth_header:
            return None
            
        try:
            # Expected format: "Bearer <token>"
            auth_type, token = auth_header.split(' ')
            if auth_type.lower() != 'bearer':
                return None
        except ValueError:
            return None
            
        user = get_user_from_token(token)
        if not user:
            raise AuthenticationFailed('Invalid or expired token')
            
        return (user, token)
    
    def authenticate_header(self, request):
        """
        Return the authentication header to use in 401 responses
        """
        return 'Bearer'
