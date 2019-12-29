from flask import Flask
from flask import render_template
from flask import send_from_directory
from flask import request, redirect, url_for
from flask import session
import os
import logging
import sys

from mysqlDb import dbGetClientPass
from mysqlDb import dbInsertNewClient
from credentials import crCheckPhone
from credentials import crCheckPassLen
from credentials import crCheckNameLen
from credentials import crCheckEmailLen

app = Flask(__name__)
# encrypt session info
app.secret_key = os.urandom(24)

logging.basicConfig(level=logging.DEBUG)

@app.route('/login', methods=['GET', 'POST'])
def loginHandler(): 
    app.logger.info('Processing default request')
    if request.method == "POST":

        req = request.form

        email = req["email"]
        password = req["pass"]

        app.logger.info("Login request from user:" + email)

        dbPass = dbGetClientPass(email)
        if dbPass == '':
            app.logger.info("User was not found!")
            return redirect('/signup')

        #check credentials TODO: hash password
        if password == dbPass:
            return redirect('/print')
        else:
            return render_template('login.html')
    else:
        app.logger.info(request.method)

    return render_template('login.html')

@app.route('/print')
def printMsg():
    # app.logger.warning('testing warning log')
    # app.logger.error('testing error log')
    # app.logger.info('testing info log')
    return "Check your console"

@app.route('/signup', methods=['GET', 'POST'])
def signupHandler(): 
    app.logger.info('New sign up request')
    if request.method == "POST":

        req = request.form
        email = req["email"]
        name = req["name"]
        phone = req["phone"]
        password = req["password"]
        re_pass = req["re_password"]


        if password != re_pass:     
            app.logger.info("Password does not match re-typed pass!")
            return render_template('signup.html')

        if not crCheckPhone(phone):
            app.logger.info("Invalid phone number: " + phone)
            return render_template('signup.html')

        if not request.form.get('agree-term'):
            app.logger.info("User need to agree to terms to proceed")
            return render_template('signup.html')

        if not crCheckNameLen(name): 
            app.logger.info("Name must have 3 to 56 characters")
            return render_template('signup.html')

        if not crCheckEmailLen(email):
            app.logger.info("Email must have 5 to 40 characters")
            return render_template('signup.html')

        if not crCheckPassLen(password):
            app.logger.info("Password must have 6 to 64 characters")
            return render_template('signup.html')

        if not dbInsertNewClient(name, email, password, phone):
            app.logger.info("Cannot insert new client in database!")
            return render_template('signup.html')

        return redirect('/print')

    return render_template('signup.html')


@app.route('/')
def index(): 
    return loginHandler()

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)