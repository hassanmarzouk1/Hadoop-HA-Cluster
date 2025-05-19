# Building a Highly Available Hadoop Cluster Using Docker

**Author:** Hassan Marzouk  
**Course:** Hadoop and Docker Courses, ITI Data Management Track  
**Instructors:** Youssef Etmaan & Ibrahim EL Sadeek  

---

## Project Overview

This project aims to build a **Highly Available (HA) Hadoop Cluster** supporting HDFS HA and YARN HA. The cluster is first manually set up on Ubuntu containers, then fully containerized and automated using Docker and Docker Compose.

The project covers:

- Deploying a multi-node Hadoop cluster with **3 master nodes** and **1 worker node**.
- Each master node runs critical HA components including Zookeeper, JournalNode, NameNode, and ResourceManager.
- Worker node(s) run DataNode and NodeManager to store data and execute tasks.
- Configuration supports automatic failover of active NameNode and ResourceManager to standby nodes, ensuring high availability.
- Containerizing the setup into a single Docker image, and orchestrating multi-node cluster startup via Docker Compose.
- Running sample MapReduce jobs to validate the cluster functionality.
- Capability to horizontally scale by adding additional worker nodes.

---

## Cluster Topology and Services

| Node Type  | Number of Nodes | Services Hosted                                                                     |
|------------|-----------------|-------------------------------------------------------------------------------------|
| Master     | 3               | Zookeeper, JournalNode, NameNode (Active/Standby), ResourceManager (Active/Standby) |
| Worker     | 1 (scalable)    | DataNode, NodeManager                                                               |

---

## Features & Deliverables

### Part 1: Manual Setup

- **4 Ubuntu 22.04 Containers** created on a custom Docker network.
- Manual installation of **Hadoop 3.3.6** and dependencies on each node.
- Setup of a **Zookeeper quorum** across the 3 master nodes.
- Configuration of **HDFS High Availability** using the Quorum Journal Manager (QJM) for shared edit logs.
- Enabling **automatic failover** for NameNodes via Zookeeper fencing.
- Setup of **YARN ResourceManager HA** with failover controllers on master nodes.
- Verification through:
  - Accessing HDFS web UI on all masters.
  - Testing failover by stopping active NameNode or ResourceManager.
  - Ingesting data into HDFS.
  - Running a MapReduce job on ingested data.
  - Scaling cluster by adding second worker node and confirming via HDFS/YARN UI.

### Part 2: Docker Automation

- Creation of a **single Dockerfile** building a Hadoop image capable of running any node role.
- Installation of all required packages, Java, and Hadoop within the image.
- Using an **entrypoint script** to start services based on environment variable indicating node role (master/worker).
- Building a **Docker Compose file** defining 4 services (3 masters + 1 worker).
- Configuration of:
  - Networking between containers with proper hostnames.
  - Volume mounting for persistent Hadoop data, logs, and configuration.
  - Port mappings allowing masters to be accessed from host machine, while workers remain internal.
  - Health checks to ensure containers are ready.
  - Resource limits for CPU and memory.
- Inclusion of a sample Java MapReduce job to test cluster functionality.
- Ability to scale by adding additional worker nodes in Docker Compose.

---

## Project File Structure

```
.
├── Dockerfile                          # Dockerfile to build Hadoop image for all nodes
├── docker-compose.yml                  # Compose file to start 3 masters + 1 worker cluster
├── entrypoint.sh                       # Script to initialize services based on node role
├── Configurations/                     # Configuration files for Hadoop (XML configs)
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── yarn-site.xml
│   ├── mapred-site.xml
│   └── ...
├── Documentation/                     
│   ├── Commands Documentation.txt      # Command history files from manual setup (part 1)
|
├── README.md                         # This file

```

---

## Prerequisites

- Docker (v20.10+) installed on your machine  
- Docker Compose installed  
- Minimum 8 GB RAM recommended  
- Basic understanding of Docker commands and networking  

---

## Step-by-Step Instructions to Build and Run the Cluster

### 1. Clone or download the project repository and navigate to its root directory.

### 2. Build the Docker Image

```bash
docker build -t hadoop-ha-cluster:latest .
```

- This builds a custom Docker image including Ubuntu 22.04, Java, Hadoop 3.3.6, and configured HA components.

### 3. Start the Hadoop Cluster with Docker Compose

```bash
docker-compose up -d
```

This command:

- Creates and starts 4 containers:  
  - `master1`, `master2`, `master3` (masters running HA services)  
  - `worker1` (worker node)  

- Sets up network, volumes, and environment variables per container.  
- Runs the entrypoint script to start services according to node role.

### 4. Verify Cluster Status

- Access **HDFS Web UI** on each master node at `http://localhost:<mapped_port>` (typically port 9870).  
- Access **YARN ResourceManager UI** at `http://localhost:<mapped_port>` (typically port 8088).  
- Check **Zookeeper Quorum** health by connecting to any master node.  

### 5. Test High Availability Failover

- SSH into the active NameNode container and stop the NameNode process to simulate failure:  

```bash
docker exec -it master1 bash
# Stop NameNode service
stop-dfs.sh  # or equivalent command
```

- Observe automatic failover to standby NameNode on another master (check HDFS UI).  
- Similarly, stop ResourceManager on active master to test YARN failover.

### 6. Run a Sample MapReduce Job

- Ru  a sample MapReduce job to any master container:  

```bash
hdfs dfs -mkdir /input
echo "Hello From Cluster" > ./hadoop/file.txt
hdfs dfs -put ./hadoop/file.txt /input
hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /input /output
```

- Monitor job progress in YARN UI.

### 7. Scale Cluster by Adding Workers

- Modify `docker-compose.yml` to add another worker service (e.g., `worker2`).  
- Run:  


- Write the hostname of the new worker container in Configurations/Hadoop/workers.txt

```bash
docker-compose up --build
```
- Confirm new worker nodes are registered in HDFS and YARN UIs.

---

## Important Notes

- **Configuration files** inside `Configurations/` are mounted into containers for easy customization.  
- **Persistent volumes** ensure data durability across container restarts.  
- Ports mapped in `docker-compose.yml` prevent conflicts with host machine ports.  
- Entry point script dynamically starts services depending on `NODE_ROLE` environment variable (master/worker).  
- Use `docker logs <container>` for troubleshooting container issues.

---

## References

- [Apache Hadoop High Availability Guide](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html#Deployment)  
- [Docker Documentation](https://docs.docker.com/)  
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## Credits

- **Author:** Hassan Marzouk  
- **Courses:** Hadoop and Docker courses, ITI Data Management Track  
- **Instructors:** Youssef Etmaan & Ibrahim EL Sadeek  

---

# End of README
