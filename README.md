# DB Project - Web app for Dental Clinic Management
## **BE: Python, Flask**
## **HTML, CSS, javascript/ jQuerry**

* DB Features:
  - autoincrement
  - constraints:
      - appointment time can be divided by 10 mins
      - no appointments before 9:00
      - no appointments after 17:00
      - appointment end time cannot be earlier than start time
  - DB *function* for checks: *slotIsAvailable*
  - DB *trigger* to be fired befor inseting new appointment (calls slotIsAvailable)
  - DB *event* runs daily, checks if appointments are in the past, moves them to history table
  - Procedure *testRemovedEvent* can be called manually to test the event above
  - DB *variables*:
    - _log_bin_trust_function_creators - avoid errors in slotIsAvailable (https://dev.mysql.com/doc/refman/8.0/en/stored-programs-logging.html)
    - event_scheduler - starts event thread in mySql daemon (mysql> show processlist;)
  - additional procedures: getAllDiscountOperations, getMedicBonus
 
* docker-compose.yml contains 2 services: *db* and *py*


* RUN:
docker-compose build --no-cache
docker-compose up
docker run mysql -P 3306

* DELETE DOCKER IMAGE:
docker-compose down
docker system prune -a

* CONNECT TO MYSQL DB:
docker run  -d --env="MYSQL_ROOT_PASSWORD=root" -p 32000:3306 mysql
mysql -P 32000 -u root -p dent
