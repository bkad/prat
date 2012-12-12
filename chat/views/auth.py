from flask import Blueprint, g, render_template, request, flash, session, redirect, current_app
from flaskext.openid import OpenID
from hashlib import md5
from chat.datastore import db, add_user_to_channel
from chat.zmq_context import zmq_context
import zmq.green as zmq
from chat.views.eventhub import send_join_channel
import urllib
import uuid

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
  session["email"] = resp.email
  user = db.users.find_one({ "email" : resp.email })
  if user is not None:
    g.user = user
  else:
    default_channels = current_app.config["DEFAULT_CHANNELS"]
    gravatar_url = "//www.gravatar.com/avatar/" + md5(resp.email.lower()).hexdigest() + "?"
    gravatar_url += urllib.urlencode({ 's':str(18) })

    user_object = {
        "openid": resp.identity_url,
        "name": resp.fullname or resp.nickname,
        "email": resp.email,
        "gravatar": gravatar_url,
        "last_selected_channel": default_channels[0],
        "channels": default_channels,
        "api_key": str(uuid.uuid4()),
        "secret": str(uuid.uuid4()),
    }
    db.users.save(user_object)
    push_socket = zmq_context.socket(zmq.PUSH)
    push_socket.connect(current_app.config["PUSH_ADDRESS"])
    for channel in default_channels:
      add_user_to_channel(user_object, channel)
      send_join_channel(channel, user_object, push_socket)
    push_socket.close()
    g.user = user_object
  flash(u'Successfully logged in')
  return redirect(oid.get_next_url())

@auth.route('/logout')
def logout():
    session.pop("email", None)
    flash(u'You were signed out')
    return redirect(oid.get_next_url())
