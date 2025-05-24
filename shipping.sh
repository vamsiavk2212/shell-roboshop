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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven and Java"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "system user roboshop already created.... $Y Skipping $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Moving and renaming Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling Shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Enabling Shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Install MySQL"



mysql -h mysql.daws100s.site -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
mysql -h mysql.daws100s.site -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
mysql -h mysql.daws100s.site -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
VALIDATE $? "Loading data into MySQL"


systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart shipping

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE