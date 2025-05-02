FROM python:3.9-slim

WORKDIR /app

COPY generate_data.py .

RUN pip install --no-cache-dir pymongo faker

CMD ["python", "generate_data.py"]
