# docker build . -t octopussamples/diff2html
# This image includes the diff2html tool (https://diff2html.xyz/) and Python 3. This image is expected to be used
# as a container image for a Python script that generates diff previews.
FROM node:lts-bullseye
RUN npm install -g diff2html-cli
RUN apt-get update; apt-get install libicu67 python3 python3-pip -y
RUN pip install pycryptodome