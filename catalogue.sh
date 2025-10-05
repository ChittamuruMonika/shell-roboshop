#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Log_Folder="/var/log/shell-roboshop" 
Script_Name=$( echo $0 | cut -d "." -f1 )
Script_location=$pwd
mongodb_ip="mongodb.chikki.space"
Log_File="$Log_Folder/$Script_Name.log"
mkdir -p $Log_Folder

if [ $USERID -ne 0 ]; then 
    echo -e "$R Error: please run the script with root privilege $N"
    exit 1
fi

Validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2..... $R Failed $N" | tee -a $Log_File
        exit 1
    else
        echo -e "$2.....$G Success $N" | tee -a $Log_File
    fi
}

dnf module disable nodejs -y &>>$Log_File
validate $? "disabling nodejs"

dnf module enable nodejs:20 -y
validate $? "Enabling nodejs"

dnf install nodejs -y &>>$Log_File
validate $? "Installing nodejs 20"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
validate $? "Adding roboshop user"
mkdir -p /app 
validate $? "creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
validate $? "Downloading the code"
cd /app 
validate $? "changing to app directory"

rm -rf /app/*
unzip /tmp/catalogue.zip
validate $? "Unzip the code"
npm install &>>$Log_File
validate $? "Installing dependencies"

cp $Script_location/catalogue.service /etc/systemd/system/catalogue.service
validate $? "setting up catalogue service"


systemctl daemon-reload &>>$Log_File
validate $? "daemon reload"
systemctl enable catalogue &>>$Log_File
validate $? "enabling catalogue"
systemctl start catalogue &>>$Log_File
validate $? "start catalogue"

cp $Script_location/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "copy mongodb repot"
dnf install mongodb-mongosh -y &>>$Log_File
validate $? "Installing mongodb client"
mongosh --host $mongodb_ip </app/db/master-data.js &>>$Log_File
validate $? "Load catalogue products"

ystemctl restart catalogue &>>$Log_File
validate $? "restart catalogue"