#!/bin/bash

yum install -y epel-release
yum install -y update
yum install -y unzip
yum install -y wget
yum install -y java
yum install -y tomcat tomcat-webapps tomcat-admin-webapps
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
echo "export PATH=$PATH:/usr/local/bin" >> /etc/profile

wget https://github.com/AKSarav/SampleWebApp/raw/master/dist/SampleWebApp.war
cp SampleWebApp.war /usr/share/tomcat/webapps/



echo 'JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true -Xmx512m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC"' >> /usr/share/tomcat/conf/tomcat.conf

sed -i '$ i\  <user name="admin" password="admin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status" />' /usr/share/tomcat/conf/tomcat-users.xml

systemctl enable tomcat

systemctl restart tomcat