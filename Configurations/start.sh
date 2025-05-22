#! /bin/bash

# Start the SSH service
sudo service ssh start
sleep 2

# Get the hostname of the container
HOSTNAME=$(hostname)
ZK_ID=$(hostname | grep -oE '[0-9]+')

# Determine the container type based on the hostname and start appropriate Hadoop services
if [[ "$HOSTNAME" == "master"* ]]; then
    echo "$ZK_ID" > /usr/local/zookeeper/data/myid
    zkServer.sh start
    hdfs --daemon start journalnode
    sleep 10

    if [[ "$ZK_ID" == "1" ]]; then
        # Initialize the HDFS namenode
        if [ ! -f /usr/local/hadoop/hdfs/namenode/current/formatted ]; then
            echo "Formatting HDFS namenode..."
            hdfs namenode -format -force
            echo "HDFS namenode formatted. (first boot)"
            touch /usr/local/hadoop/hdfs/namenode/current/formatted
        else
            echo "HDFS namenode already formatted. Skipping format."
        fi
        # Initialize the HDFS zookeeper
        # Check if the ZKFC is already formatted
        if [ ! -f /usr/local/zookeeper/data/formatted ]; then
            echo "Formatting HDFS zookeeper..."
            hdfs zkfc -formatZK -force
            echo "HDFS zookeeper formatted. (first boot)"
            touch /usr/local/zookeeper/data/formatted
        else
            echo "HDFS zookeeper already formatted. Skipping format."
        fi
        # Initialize the shared edits (ONLY if not done before)
        if [ ! -f /usr/local/hadoop/hdfs/journal/shared_edits_initialized ]; then
            echo "Initializing shared edits for HA NameNode..."
            hdfs namenode -initializeSharedEdits -force
            echo "Shared edits initialized. (first boot)"
            touch /usr/local/hadoop/hdfs/journal/shared_edits_initialized
        else
            echo "Shared edits already initialized. Skipping."
        fi
        # Start the HDFS services
        hdfs --daemon start zkfc
        hdfs --daemon start namenode
        yarn --daemon start resourcemanager
        echo "All services ran on ${HOSTNAME}..."

    else
        # Wait for the primary NameNode to be active
        echo "Waiting for master1's NameNode to become ACTIVE..."
        while ! hdfs haadmin -checkHealth nn1 2> /dev/null; do
            sleep 8
        done
        echo "Master is ready, starting standby namenode..."
        # check if we need to bootstrap the standby namenode
        if [ ! -f /usr/local/hadoop/hdfs/namenode/current/standby_intialized ]; then
            echo "Initializing standby NameNode metadata (first boot)..."
            hdfs namenode -bootstrapStandby -force
            echo "Standby NameNode metadata initialized."
            touch /usr/local/hadoop/hdfs/namenode/current/standby_intialized
        else
            echo "Standby NameNode metadata already initialized. Skipping bootstrap."
        fi
        hdfs --daemon start zkfc
        hdfs --daemon start namenode
        yarn --daemon start resourcemanager
        echo "All services ran on ${HOSTNAME}..."

    fi

elif [[ "$HOSTNAME" == *"worker"* ]]; then
        # Start the DataNode and NodeManager services
        echo "Starting DataNode and NodeManager on $HOSTNAME..."
        hdfs --daemon start datanode
        yarn --daemon start nodemanager
        echo "DataNode and NodeManager started on $HOSTNAME."

elif [[ "$HOSTNAME" == *"hbmaster"* ]]; then
        # Start the HBase Master service
        echo "Starting HBase Master on $HOSTNAME..."
        hbase master start
        echo "HBase Master started on $HOSTNAME."

elif [[ "$HOSTNAME" == *"regionserver"* ]]; then
        # Start the HBase RegionServer service
        echo "Starting HBase RegionServer on $HOSTNAME..."
        hbase regionserver start
        echo "HBase RegionServer started on $HOSTNAME."

else
    echo "Unknown container type: $HOSTNAME"
    exit 1


fi

tail -f /dev/null

