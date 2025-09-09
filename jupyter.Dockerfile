FROM mk-spark-base

# Python packages
RUN pip3 install wget requests pandas numpy datawrangler findspark jupyterlab pyspark==2.4.7

EXPOSE 8888

WORKDIR ${SHARED_WORKSPACE}

CMD jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=

