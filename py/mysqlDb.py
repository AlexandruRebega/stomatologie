import mysql.connector
from mysql.connector import Error

mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  passwd="root",
  port="32000",
  database="dent"
)

mycursor = mydb.cursor()
mycursor.execute("SELECT * FROM Numbers")

myresult = mycursor.fetchall()

__db_debug__ = True

def dbGetClientPass(email):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get password from DB for :" + email)

        args = [email]
        cursor.callproc('getClientPass', args)

        # print out the result
        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return ''
            return res[0][0]

    except Error as e:
        print(e)

    finally:
        cursor.close()

    return ''       


def dbInsertNewClient(name, email, passwd, phone):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Insert new client: ")
            print("-->Name: "+ name)
            print("-->Email: "+ email)
            print("-->Pass: "+ phone)
            print("-->Phone: "+ passwd)

        args = [name, email, passwd, phone]
        cursor.callproc('insertNewClient', args)

    except Error as e:
        print(e)
        if __db_debug__ :
            print("Insert new client failed!")
        return False

    finally:
        cursor.close()

    if __db_debug__ :
        print("Insert new client successfully!")

    return True
