from django.urls import path
from .views import UserListCreateAPIView, UserRetrieveUpdateDestroyAPIView, HealthCheckView

urlpatterns = [
    path('users/', UserListCreateAPIView.as_view(), name='user-list-create'),
    path('users/<int:pk>/', UserRetrieveUpdateDestroyAPIView.as_view(), name='user-detail'),
    path('health/', HealthCheckView.as_view(), name='health-check'),
]
