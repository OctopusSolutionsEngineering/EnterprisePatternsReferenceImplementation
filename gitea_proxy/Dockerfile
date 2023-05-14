FROM python:3.11-slim-buster

WORKDIR /app

RUN apt-get update && apt-get install -y curl
RUN apt-get update && apt-get install -y --no-install-recommends gnupg curl ca-certificates apt-transport-https && \
  curl -sSfL https://apt.octopus.com/public.key | apt-key add - && \
  sh -c "echo deb https://apt.octopus.com/ stable main > /etc/apt/sources.list.d/octopus.com.list" && \
  apt-get update && apt-get install -y octopuscli

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY . .

CMD ["python3", "main.py"]