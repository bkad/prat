from flask import Blueprint, g, render_template, request, flash, session, redirect
from flaskext.openid import OpenID
from hashlib import md5
import urllib

auth = Blueprint("auth", __name__)
oid = OpenID()

@auth.route('/login', methods=['GET', 'POST'])
@oid.loginhandler
def login():
  if g.authed is True:
    return redirect(oid.get_next_url())
  if request.method == 'POST':
    openid = request.form.get('openid_identifier')
    if openid:
      return oid.try_login(openid, ask_for=['email', 'fullname', 'nickname'])
  return render_template('login.htmljinja',
                         next=oid.get_next_url(),
                         error=oid.fetch_error())

@oid.after_login
def create_or_login(resp):
  user = None
  session['openid'] = resp.identity_url
  user = g.users.find_one({"openid" : resp.identity_url})
  if user is not None:
    g.user = user
  else:
    gravatar_url = "http://www.gravatar.com/avatar/" + md5(resp.email.lower()).hexdigest() + "?"
    gravatar_url += urllib.urlencode( {'s':str(18)} )

    mongo_user_object = { "openid": resp.identity_url,
                           "name": resp.fullname or resp.nickname,
                           "email": resp.email,
                           "gravatar": gravatar_url}
    g.users.insert(mongo_user_object)
    g.user = mongo_user_object
  flash(u'Successfully logged in')
  return redirect(oid.get_next_url())

@auth.route('/logout')
def logout():
    session.pop('openid', None)
    flash(u'You were signed out')
    return redirect(oid.get_next_url())