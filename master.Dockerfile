FROM mk-spark-base

# Python packages
RUN pip3 install wget requests datawrangler

# Get Livy
RUN wget https://apache.mirrors.tworzy.net/incubator/livy/0.7.0-incubating/apache-livy-0.7.0-incubating-bin.zip -O livy.zip && \
   unzip livy.zip -d /usr/bin/

EXPOSE 8080 7077 8998 8888

WORKDIR ${APP}

ADD entryfile.sh entryfile.sh
RUN chmod +x entryfile.sh

ENTRYPOINT ["sh", "entryfile.sh"]

