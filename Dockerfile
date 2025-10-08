FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# System deps for psycopg2 and fonts (pandas/openpyxl sometimes need locales)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    locales \
    bash \
  && rm -rf /var/lib/apt/lists/* \
  && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && locale-gen

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create media and exports dirs used by the app
RUN mkdir -p /app/media/exports /app/media/pdfs /app/media/fotos /app/media/notifications /app/media/firmas /app/media/2fa

# Make entrypoint script executable
RUN chmod +x /app/entrypoint.sh

EXPOSE 8000

# Initialize database and start app
CMD ["sh", "-c", "python app/scripts/docker_init.py && uvicorn main:app --host 0.0.0.0 --port 8000"]


