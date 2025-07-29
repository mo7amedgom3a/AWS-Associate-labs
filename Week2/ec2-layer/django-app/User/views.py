from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import User
from .serializers import UserSerializer

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
