FROM ubuntu:22.04

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    HADOOP_HOME=/usr/local/hadoop               \
    ZOOKEEPER_HOME=/usr/local/zookeeper         \
    HBASE_HOME=/usr/local/hbase                             

ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:${HBASE_HOME}/bin:$PATH          \
    HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop                                                                     \
    HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native                                                        \
    HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"                                                     


ENV HADOOP_CLASSPATH=$HADOOP_HOME/lib/*:$ZOOKEEPER_HOME/*.jar

# Install dependencies & OpenJDK 8
RUN apt update                          && \
    apt install nano -y                 && \
    apt install openjdk-8-jdk -y        && \
    apt install openssh-server -y       && \
    apt install sudo -y                 && \
    apt install sshpass -y              && \
    apt install netcat -y               && \
    apt install net-tools -y            && \
    apt install python3 python3-pip -y  && \
    pip3 install faker                  && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Add Hadoop User
RUN groupadd hadoop && \
    adduser --disabled-password --ingroup hadoop hduser && \
    echo "hduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to local directory
WORKDIR /usr/local
# Install Hadoop 3.3.6
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz && \
    tar -xvzf hadoop-3.3.6.tar.gz                   && \
    mv hadoop-3.3.6 hadoop                          && \
    mkdir -p /app/hadoop/tmp                        && \
    mkdir -p hadoop/hdfs/namenode                   && \
    mkdir -p hadoop/hdfs/datanode                   && \
    mkdir -p hadoop/hdfs/journal                    && \
    chown -R hduser:hadoop hadoop /app/hadoop/tmp   && \
    rm -rf hadoop-3.3.6.tar.gz

# Install Zookeeper 3.8.4
RUN wget https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz && \
    tar -xvzf apache-zookeeper-3.8.4-bin.tar.gz && \
    mv apache-zookeeper-3.8.4-bin zookeeper     && \
    mkdir -p /usr/local/zookeeper/data          && \
    chown -R hduser:hadoop zookeeper            && \
    rm -rf apache-zookeeper-3.8.4-bin.tar.gz

# Install Hbase 2.4.18
RUN wget https://dlcdn.apache.org/hbase/2.4.18/hbase-2.4.18-bin.tar.gz  && \
    tar -xvzf hbase-2.4.18-bin.tar.gz                                   && \
    mv hbase-2.4.18 hbase                                               && \
    chown -R hduser:hadoop hbase                                        && \
    rm -rf hbase-2.4.18-bin.tar.gz

# Copy the start script and configuration files
COPY --chown=hduser:hadoop ./Configurations/start.sh /usr/local/bin/start.sh
COPY --chown=hduser:hadoop ./Configurations/zoo.cfg /usr/local/zookeeper/conf/
COPY --chown=hduser:hadoop ./Configurations/Hadoop/* /usr/local/hadoop/etc/hadoop/

# Change file ownership and permissions
RUN chmod +x /usr/local/bin/start.sh   
        
# Switch to hduser
USER hduser

# Generate SSH key
RUN ssh-keygen -t rsa -N "" -f /home/hduser/.ssh/id_rsa && \
    cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys

ENTRYPOINT [ "/usr/local/bin/start.sh" ]

