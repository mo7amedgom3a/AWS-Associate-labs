FROM public.ecr.aws/lambda/python:3.10

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install -r requirements.txt

# Copy application code
COPY app.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (app.handler)
CMD ["app.handler"]
