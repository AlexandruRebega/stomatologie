import mysql.connector
from mysql.connector import Error
import logging

from credentials import crParseDate

mydb = mysql.connector.connect(
  host="localhost",
  user="root",
  passwd="root",
  port="3306",
  database="dent"
)


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
        mydb.commit()
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
        mydb.commit()
        cursor.close()

    if __db_debug__ :
        print("Insert new client successfully!")

    return True


def dbGetClientId(email):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get client ID from DB for :" + email)

        args = [email]
        cursor.callproc('getClientId', args)

        # print out the result
        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return 0
            return res[0][0]

    except Error as e:
        print(e)

    finally:
        mydb.commit()
        cursor.close()

    return 0 

def dbGetMedicId(email):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get medic ID from DB for :" + email)

        args = [email]
        cursor.callproc('getMedicId', args)

        # print out the result
        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return 0
            return res[0][0]

    except Error as e:
        print(e)

    finally:
        mydb.commit()
        cursor.close()

    return 0


def dbGetMedicPass(email):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get password from DB for :" + email)

        args = [email]
        cursor.callproc('getMedicPass', args)

        # print out the result
        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return ''
            return res[0][0]

    except Error as e:
        print(e)

    finally:
        mydb.commit()
        cursor.close()

    return ''


def dbInsertNewAppointment(medic_id, client_id, date, sTime, eTime, operation):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Insert new appointment: ")
            print("-->Medic Id: "+ str(medic_id))
            print("-->Client Id: "+ str(client_id))
            print("-->Date: "+ str(date))
            print("-->Time: "+ str(sTime) + " to "+str(eTime))


        args = [medic_id, client_id, date, sTime, eTime, operation]
        cursor.callproc('insertNewAppointment', args)

    except Error as e:
        print(e)
        if __db_debug__ :
            print("Insert new appointment failed!")
        return False

    finally:
        mydb.commit()
        cursor.close()

    if __db_debug__ :
        print("Insert new appointment successfully!")

    return True


def dbNewAppointment(medic_id, client_id, date, op):
    if(medic_id == 0):
        print("Invalid medic ID!")
        return False;
    if(client_id == 0):
        print("Invalid client ID!")
        return False;

    dateTime = crParseDate(date)
    if not dateTime:
        return False

    date = dateTime[0]
    startTime = dateTime[1]
    #get operation length
    arr = startTime.split(':')
    hour = int(arr[0])
    hour += 1
    endTime = "{0}:{1}:{2}".format(hour, arr[1], arr[2])
    return dbInsertNewAppointment(medic_id, client_id, date, startTime, endTime, op) 


# returns c.client_nume, c.client_tel, p.data, p.startTime, p.operatie_id, op.operatie_nume 
def dbSelectAppointments(medic_id):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get appointments for medic ID:" + str(medic_id))

        args = [medic_id]
        cursor.callproc('selectAppointment', args)

        # print out the result
        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return None
            # print(res)
            return res

    except Error as e:
        print(e)

    finally:
        mydb.commit()
        cursor.close()

    return None 


def dbGetAllOperations():
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get operations...")  

        cursor.callproc('getAllOperations')

        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return None
            return res

    except Error as e:
        print(e)

    finally:
        mydb.commit()
        cursor.close()

    return None

def dbGetAllDiscountOperations(client_email):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get discount operations...")  

        cursor.callproc('getAllDiscountOperations', [client_email])

        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return None
            return res

    except Error as e:
        print(e)

    finally:
        mydb.commit()
        cursor.close()

    return None


def dbInsertNewIstoricRecord(operatie_id, client_id, medic_id, date):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Insert new medical record")

        args = [operatie_id, client_id, date]
        cursor.callproc('insertNewIstoricRecord', args)

    except Error as e:
        print(e)
        if __db_debug__ :
            print("Insert new record failed!")
        return False

    finally:
        mydb.commit()
        cursor.close()

    if __db_debug__ :
        print("Insert new medical record successfully!")

    return True


# returns c.client_nume, c.client_tel, o.operatie_nume, i.istoric_data
def dbGetClientRecords(client_id):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get operations...")  

        args = [client_id]
        cursor.callproc('getClientRecords', args)

        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return None
            return res

    except Error as e:
        print(e)

    finally:
        mydb.commit()
        cursor.close()

    return None 


# (0.1 * m.medic_salariu ) + (@nr_programari * 20) 
# WHERE nr_programari = no. operatii where pret > 200 in the last mounth
def dbGetMedicBonus(medic_id):
    try:
        cursor = mydb.cursor()

        if __db_debug__ :
            print("Get medic bonus")  

        args = [medic_id]
        cursor.callproc('getMedicBonus', args)

        for result in cursor.stored_results():
            res = result.fetchall()
            if not res:
                return None
            return res

    except Error as e:
        print(e)

    finally:
        mydb.commit()
        cursor.close()

    return None 

