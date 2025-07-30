from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.http import JsonResponse
from django.db import connection
from .models import User
from .serializers import UserSerializer

class HealthCheckView(APIView):
    """
    Health check endpoint to verify the application is running
    """
    permission_classes = []
    
    def get(self, request):
        try:
            # Test database connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            
            return Response({
                'status': 'healthy',
                'message': 'Application is running',
                'database': 'connected',
                'timestamp': request.META.get('HTTP_DATE', ''),
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({
                'status': 'unhealthy',
                'message': 'Application has issues',
                'error': str(e),
                'database': 'disconnected',
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

class UserListCreateAPIView(generics.ListCreateAPIView):
    """
    GET: List all users
    POST: Create a new user
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserRetrieveUpdateDestroyAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET: Retrieve a specific user
    PUT: Update a specific user (complete update)
    PATCH: Partially update a specific user
    DELETE: Delete a specific user
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
