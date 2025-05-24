#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" &>>$LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR: please run with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access"
fi

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ...$G SUCCESS $N" | tee -a $LOG_FILE
    else
       echo -e "$2 is ...$R FAILURE $N" | tee -a $LOG_FILE
       exit 1
    fi
}

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling MySQL"

systemctl start mysqld   &>>$LOG_FILE
VALIDATE $? "Starting MySQL"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD
VALIDATE $? "Setting MySQL root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE