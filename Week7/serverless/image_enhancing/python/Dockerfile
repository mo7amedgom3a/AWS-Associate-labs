FROM public.ecr.aws/lambda/python:3.11


COPY requirements.txt ./
RUN python -m pip install --upgrade pip \
	&& pip install -r requirements.txt --target "/var/task"

COPY image_enhancer.py ${LAMBDA_TASK_ROOT}

# Command can be overwritten by providing a different command in the template.
CMD ["image_enhancer.lambda_handler"]