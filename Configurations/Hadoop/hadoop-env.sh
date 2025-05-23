# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Set Hadoop-specific environment variables here.

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
export PATH=:$PATH:/usr/lib/jvm/java-8-openjdk-amd64/bin
export HADOOP_HOME_WARN_SUPPRESS="TRUE"
export HADOOP_ROOT_LOGGER="INFO,console"

export HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=/usr/local/hadoop/lib/native"
export LD_LIBRARY_PATH=/usr/local/hadoop/lib/native:$LD_LIBRARY_PATH

export HDFS_NAMENODE_USER="hduser"
export HDFS_DATANODE_USER="hduser"
export HDFS_SECONDARYNAMENODE_USER="hduser"
export YARN_RESOURCEMANAGER_USER="hduser"
export YARN_NODEMANAGER_USER="hduser"

export HADOOP_OS_TYPE=${HADOOP_OS_TYPE:-$(uname -s)}