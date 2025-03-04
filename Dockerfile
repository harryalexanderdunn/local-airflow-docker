FROM apache/airflow:2.7.3-python3.10
COPY requirements.txt /requirements.txt
RUN pip install --user --upgrade pip
RUN pip install --no-cache-dir --user -r /requirements.txt

USER ${AIRFLOW_UID}
