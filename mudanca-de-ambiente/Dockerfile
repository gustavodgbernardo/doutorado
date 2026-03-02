FROM python:3.9.20-bullseye

USER root

RUN apt-get update && apt-get -y install build-essential python3-pip vim
RUN pip3 install nfstream
RUN pip3 install ipython

WORKDIR /home/python

COPY get-flow.py get-flow.py

CMD ["python", "get-flow.py"]