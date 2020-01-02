import re

def crCheckPhone(phone):
    Pattern = re.compile("07[0-9]{8}") 
    return Pattern.match(phone)

def crCheckNameLen(name):
    return ((len(name) >= 3) and(len(name) <= 56))

def crCheckPassLen(passwd):
    return ((len(passwd) >= 6) and (len(passwd) <= 64))

def crCheckEmailLen(mail):
    return ((len(mail) >= 5) and (len(mail) <= 40))


def monthcheck(month):
        if month > 0 and month <= 12: ## If month is between 1 and 12, return True.
            return True
        else:
            return False

def daycheck(month,day):
    monthlist1 = [1,3,5,7,8,10,12] ## monthlist for months with 31 days.
    monthlist2 = [4,6,9,11] ## monthlist for months with 30 days.
    monthlist3 = 2 ## month with month with 28 days.

    for mon in monthlist1: ## iterate through monthlist1.
        if month == mon: ## Check if the parameter month equals to any month with 31 days.
            if day >=1 and day <= 31: ## If the parameter day is between 1 and 31, return True.
                return True
            else:
                return False

    for mon in monthlist2: ## iterate through the monthlist with 30 days.
        if month == mon: ## check if the parameter month equals to any month with 30 days.
            if day >= 1 and day <= 30: ## if the parameter day is between 1 and 30,return True.
                return True
            else:
                return False

    if month == monthlist3: ## check if parameter month equals month with 28 days.
        if day >=1 and day <= 28: ## if the parameter day is between 1 and 28,return True.
            return True
        else:
            return False


def yearcheck(year):
    if year >= 2019 and year <= 2021: ## Stupid check, let it be
        return True
    else:
        return False


def crParseDate(dateTime):
    if dateTime == '': 
        return 
    arr = dateTime.split()

    print(len(arr))
    print(arr)
    if len(arr) != 2:
        print("Invalid input : " + str(arr))
        return

    date = arr[0]
    time = arr[1]
    arr = date.split('/')
    print(len(arr))
    if len(arr) != 3:
        print("Invalid date format! ",date)
        return

    year = int(arr[0])
    month = int(arr[1])
    day = int(arr[2])
    
    if not yearcheck(year):
        print("Invalid year ", year)
        return

    if not monthcheck(month):
        print("Invalid month ", month)
        return    

    if not daycheck(month, day):
        print("Invalid day ", day)
        return
    # date is valid! 
    date = arr[0]+arr[1]+arr[2]
    
    arr = time.split(':')
    if len(arr) != 2:
        print("Invalid time format ", time)

    time += ":00"

    print("Date:", date, "time:", time)
    return    
