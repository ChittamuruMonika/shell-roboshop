#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Log_Folder="/var/log/shell-script" 
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File="$Log_File/$Script_Name.log"
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

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo repo"

dnf install mongodb-org -y &>>$Log_Folder
validate $? "Installing Mongodb"

systemctl enable mongod 
validate $? "Enable Mongodb"

systemctl start mongod 
validate $? "Install mongodb"