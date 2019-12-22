FROM python:3.6
CMD echo "Init running enviroment... "
WORKDIR /py
COPY requirements.txt /py
RUN pip3 install -r requirements.txt
COPY app.py /py
CMD python3 app.py
