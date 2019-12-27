from flask import Flask
from flask import render_template
from flask import send_from_directory
from flask import request, redirect, url_for
import os
import logging
import sys

app = Flask(__name__)

logging.basicConfig(level=logging.DEBUG)

@app.route('/login', methods=['GET', 'POST'])
def loginHandler(): 
    app.logger.info('Processing default request')
    if request.method == "POST":

        req = request.form

        email = req["email"]
        password = req["pass"]

        #check credentials
        app.logger.info(email)
        app.logger.info(password)

        return redirect('/print')
    else:
        app.logger.info(request.method)

    return render_template('login.html')
    #root_dir = os.path.dirname(os.getcwd())
    #return send_from_directory(os.path.join(root_dir, 'Stomatolog', 'ui'), "login.html")


@app.route('/print')
def printMsg():
    app.logger.warning('testing warning log')
    app.logger.error('testing error log')
    app.logger.info('testing info log')
    return "Check your console"

@app.route('/signup')
def signupHandler(): 
    return render_template('signup.html')


@app.route('/')
def index(): 
    return loginHandler()

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)