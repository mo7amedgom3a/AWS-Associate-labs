from django.urls import path
from .views import UserListCreateAPIView, UserRetrieveUpdateDestroyAPIView

urlpatterns = [
    # GET (list) and POST (create) endpoints
    path('users/', UserListCreateAPIView.as_view(), name='user-list-create'),
    
    # GET (retrieve), PUT (update), PATCH (partial update), and DELETE endpoints
    path('users/<int:pk>/', UserRetrieveUpdateDestroyAPIView.as_view(), name='user-detail'),
]
