#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Log_Folder="/var/log/shell-roboshop" 
Script_Name=$( echo $0 | cut -d "." -f1 )
Script_location=$PWD
mongodb_ip=mongodb.chikki.space
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
Validate $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>$Log_File
Validate $? "Enabling nodejs"

dnf install nodejs -y &>>$Log_File
Validate $? "Installing nodejs 20"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
Validate $? "Adding roboshop user"
mkdir -p /app 
Validate $? "creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
Validate $? "Downloading the code"
cd /app 
Validate $? "changing to app directory"

rm -rf /app/*
unzip /tmp/catalogue.zip
Validate $? "Unzip the code"
npm install &>>$Log_File
Validate $? "Installing dependencies"

cp $Script_location/catalogue.service /etc/systemd/system/catalogue.service
Validate $? "setting up catalogue service"


systemctl daemon-reload &>>$Log_File
Validate $? "daemon reload"
systemctl enable catalogue &>>$Log_File
Validate $? "enabling catalogue"
systemctl start catalogue &>>$Log_File
Validate $? "start catalogue"

cp $Script_location/mongo.repo /etc/yum.repos.d/mongo.repo
Validate $? "copy mongodb repot"
dnf install mongodb-mongosh -y &>>$Log_File
Validate $? "Installing mongodb client"
mongosh --host $mongodb_ip </app/db/master-data.js &>>$Log_File
Validate $? "Load catalogue products"

systemctl restart catalogue &>>$Log_File
Validate $? "restart catalogue"