FROM python:3.9-slim

WORKDIR /app

COPY generate_data.py .
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "generate_data.py"]
