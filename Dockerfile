FROM python:3.12-slim-bookworm
WORKDIR /app
COPY requirements.txt .
RUN apt-get update && apt-get upgrade -y
RUN pip install --no-cache-dir --default-timeout=120 --retries 5 -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
