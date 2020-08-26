FROM python:3.6.12-buster

WORKDIR /app
ADD ./requirements.txt .
RUN pip install -r requirements.txt

ADD . .

EXPOSE 80

CMD ["python", "./f1.py"]
