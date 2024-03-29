# Install Java 8
sudo yum update
sudo yum install java-1.8.0-openjdk
sudo update-alternatives --config java

# Change to home directory
cd ~

# Download Scala Stream Collector Jar
sudo wget https://bintray.com/snowplow/snowplow-generic/download_file?file_path=snowplow_scala_stream_collector_kinesis_0.16.0.zip .

# Unzip the Jar
unzip snowplow_scala_stream_collector_kinesis_0.16.0.zip

# Execute Scala Steam Collector Jar as a process
java -jar snowplow-stream-collector-kinesis-0.16.0.jar --config collector.config.hocon & disown