﻿FROM python:2.7-alpine
WORKDIR /app

# Install our requirements.txt
ADD requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

# Copy our code from the current folder to /app inside the container
ADD . /app

EXPOSE 80

CMD ["python", "f1.py"]
