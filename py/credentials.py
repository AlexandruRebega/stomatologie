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
    
