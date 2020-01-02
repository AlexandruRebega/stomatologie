from flask import Flask
from flask import render_template
from flask import send_from_directory
from flask import request, redirect, url_for
from flask import session, g
import os
import logging
import sys

from mysqlDb import dbGetClientPass
from mysqlDb import dbInsertNewClient
from mysqlDb import dbGetMedicId
from mysqlDb import dbGetClientId
from mysqlDb import dbGetMedicPass
from mysqlDb import dbNewAppointment
from credentials import crCheckPhone
from credentials import crCheckPassLen
from credentials import crCheckNameLen
from credentials import crCheckEmailLen,crParseDate

app = Flask(__name__)
# encrypt session info
app.secret_key = os.urandom(24)

logging.basicConfig(level=logging.DEBUG)


@app.before_request
def before_request():
    g.user = None
    if 'user' in session:
        g.user = session['user']



@app.route('/login', methods=['GET', 'POST'])
def loginHandler(): 
    session.pop('user', None)

    if request.method == "POST":

        req = request.form

        email = req["email"]
        password = req["pass"]

        app.logger.info("Login request from user:" + email)

        dbPass = dbGetClientPass(email)
        if dbPass == '':

            dbPass = dbGetMedicPass(email)
            if dbPass == '':
                app.logger.info("User was not found!")
                return redirect('/signup')

        #check credentials TODO: hash password
        if password == dbPass:
            session['user'] = email
            return redirect('/appointment')
        else:
            return render_template('login.html')
    else:
        app.logger.info(request.method)

    return render_template('login.html')



@app.route('/appointment', methods=['GET', 'POST'])
def appointmentHandler():
    if g.user:
        if request.method == "POST":
            app.logger.info(request.method)
            req = request.form

            # Logout
            if 'logoutBtn' in req:
                app.logger.info("Logout user: " +g.user)
                session.pop('user', None)
                return redirect('/')

            # Check appointment data
            if 'appointment-bob' in req:
                app.logger.info("New appointment request for Bob.")
                date = req["appointment-bob"]
                medic_email = "bobcarry@antodent.com"

            elif 'appointment-jean' in req:
                app.logger.info("New appointment request for Jean.")
                date = req["appointment-jean"]
                medic_email = "jsmith@antodent.com"

            elif 'appointment-rick' in req:
                app.logger.info("New appointment request for Rick.")
                date = req["appointment-rick"]
                medic_email = "rfisher@antodent.com"

            # user must be logged in to get here, so we can retrive his email from session`s g.user
            client_id = dbGetClientId(g.user)
            if client_id == 0:
                app.logger.error("Failed to get client id!")
                return redirect('/login')

            medic_id = dbGetMedicId(medic_email)
            if medic_email == 0:
                app.logger.error("Failed to get medic id!")
                return redirect('/calendar')

            app.logger.info("New appointment for client: " +g.user + 
                "to doctor " +medic_email + "on " + date)
            crParseDate(date)
            dbNewAppointment(medic_id, client_id, date)

        else:
            app.logger.info(request.method)

        return render_template('calendar.html')
    else:
        return redirect('/')



@app.route('/signup', methods=['GET', 'POST'])
def signupHandler(): 
    session.pop('user', None)
    if request.method == "POST":
        app.logger.info('New sign up request')

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

        session['user'] = email
        return redirect('/appointment')

    return render_template('signup.html')



@app.route('/index')
def indexHandler(): 
    return index()

@app.route('/')
def index(): 
    return render_template('index.html')


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
