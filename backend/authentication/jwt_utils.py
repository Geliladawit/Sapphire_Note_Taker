import jwt
from datetime import datetime, timedelta
from django.conf import settings
from django.contrib.auth import get_user_model

User = get_user_model()


def generate_tokens(user):
    """
    Generate access and refresh tokens for a user
    """
    jwt_settings = settings.JWT_SETTINGS
    
    # Access token payload
    access_payload = {
        'user_id': str(user.id),
        'email': user.email,
        'exp': datetime.utcnow() + timedelta(minutes=jwt_settings['ACCESS_TOKEN_EXPIRE_MINUTES']),
        'iat': datetime.utcnow(),
        'type': 'access'
    }
    
    # Refresh token payload
    refresh_payload = {
        'user_id': str(user.id),
        'exp': datetime.utcnow() + timedelta(days=jwt_settings['REFRESH_TOKEN_EXPIRE_DAYS']),
        'iat': datetime.utcnow(),
        'type': 'refresh'
    }
    
    access_token = jwt.encode(
        access_payload,
        jwt_settings['SECRET_KEY'],
        algorithm=jwt_settings['ALGORITHM']
    )
    
    refresh_token = jwt.encode(
        refresh_payload,
        jwt_settings['SECRET_KEY'],
        algorithm=jwt_settings['ALGORITHM']
    )
    
    return {
        'access_token': access_token,
        'refresh_token': refresh_token,
        'expires_in': jwt_settings['ACCESS_TOKEN_EXPIRE_MINUTES'] * 60
    }


def verify_token(token, token_type='access'):
    """
    Verify and decode a JWT token
    """
    try:
        jwt_settings = settings.JWT_SETTINGS
        payload = jwt.decode(
            token,
            jwt_settings['SECRET_KEY'],
            algorithms=[jwt_settings['ALGORITHM']]
        )
        
        if payload.get('type') != token_type:
            return None
            
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


def get_user_from_token(token):
    """
    Get user instance from access token
    """
    payload = verify_token(token, 'access')
    if not payload:
        return None
        
    try:
        user = User.objects.get(id=payload['user_id'])
        return user
    except User.DoesNotExist:
        return None
