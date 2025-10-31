FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

ENV PYTHONUNBUFFERED=1
ENV PORT=8080

CMD ["sh", "-c", "exec gunicorn --bind :$PORT --workers 2 --threads 4 --timeout 60 app:app"]