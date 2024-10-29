# DB Project - Web app for Dental Clinic Management
## **BE: Python, Flask**
## **HTML, CSS, javascript/ jQuerry**


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
