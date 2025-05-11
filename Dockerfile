FROM python3.10-slim

WORKDIR app

COPY backend/requirements.txt ./
RUN apt-get update && apt-get install -y build-essential && 
    pip install --upgrade pip && 
    pip install -r requirements.txt

COPY backend .

CMD [python, main.py]
