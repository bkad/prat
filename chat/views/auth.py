from flask import url_for, current_app, redirect, request, Blueprint, g, render_template, session
from rauth import OAuth2Service
from hashlib import md5
from chat.datastore import db, add_user_to_channel, get_user
from chat.zmq_context import zmq_context, push_socket
from chat.views.eventhub import send_join_channel
import urllib, urllib2
import uuid
import json

auth = Blueprint("auth", __name__)

class OAuthSignIn(object):
  providers = None

  def __init__(self, provider_name):
    self.provider_name = provider_name
    credentials = current_app.config['OAUTH_CREDENTIALS'][provider_name]
    self.consumer_id = credentials['id']
    self.consumer_secret = credentials['secret']

  def authorize(self):
    pass

  def callback(self):
    pass

  def get_callback_url(self):
    return url_for('auth.oauth_callback', provider=self.provider_name,
                    _external=True)

  @classmethod
  def get_provider(self, provider_name):
    if self.providers is None:
      self.providers={}
      for provider_class in self.__subclasses__():
        provider = provider_class()
        self.providers[provider.provider_name] = provider
    return self.providers[provider_name]

class GoogleSignIn(OAuthSignIn):
  def __init__(self):
    super(GoogleSignIn, self).__init__('google')
    googleinfo = urllib2.urlopen('https://accounts.google.com/.well-known/openid-configuration')
    google_params = json.load(googleinfo)
    self.service = OAuth2Service(
      name='google',
      client_id=self.consumer_id,
      client_secret=self.consumer_secret,
      authorize_url=google_params.get('authorization_endpoint'),
      base_url=google_params.get('userinfo_endpoint'),
      access_token_url=google_params.get('token_endpoint')
    )

  def authorize(self):
    return redirect(self.service.get_authorize_url(
      scope='email profile',
      response_type='code',
      redirect_uri=self.get_callback_url())
    )

  def callback(self):
    if 'code' not in request.args:
      return None, None, None
    oauth_session = self.service.get_auth_session(
      data={'code': request.args['code'],
            'grant_type': 'authorization_code',
            'redirect_uri': self.get_callback_url()
           },
      decoder = json.loads
    )
    me = oauth_session.get('').json()
    return (me['name'],
            me['email'])

@auth.route('/authorize/<provider>')
def oauth_authorize(provider):
  # Flask-Login function
  if g.authed is True:
    return redirect(url_for('frontend.index'))
  print provider
  oauth = OAuthSignIn.get_provider(provider)
  print oauth.service.get_authorize_url(
        scope='email profile',
        response_type='code',
        redirect_uri=oauth.get_callback_url())
  return oauth.authorize()

@auth.route('/callback/<provider>')
def oauth_callback(provider):
    if g.authed is True:
      return redirect(url_for('frontend.index'))
    oauth = OAuthSignIn.get_provider(provider)
    username, email = oauth.callback()
    if email is None:
        flash('Authentication failed.')
        return redirect(url_for('frontend.index'))

    user = None
    session["email"] = email
    user = get_user(email=email)
    if user is not None:
      g.user = user
    else:
      default_channels = current_app.config["DEFAULT_CHANNELS"]
      gravatar_url = "//www.gravatar.com/avatar/" + md5(email.lower()).hexdigest() + "?"
      gravatar_url += urllib.urlencode({ 's':str(18) })

      user_object = {
          "openid": "authed",
          "name": username,
          "email": email,
          "gravatar": gravatar_url,
          "last_selected_channel": default_channels[0],
          "channels": default_channels,
          "api_key": str(uuid.uuid4()),
          "secret": str(uuid.uuid4()),
      }
      db.users.save(user_object)
      for channel in default_channels:
        add_user_to_channel(user_object, channel)
        send_join_channel(channel, user_object, push_socket)
      g.user = user_object
    return redirect(url_for('frontend.index'))

@auth.route('/login', methods=['GET', 'POST'])
def login():
    if g.authed is True:
        return redirect(url_for('frontend.index'))
    return render_template('login.htmljinja')

@auth.route('/logout')
def logout():
    session.pop("email", None)
    return redirect(url_for('frontend.index'))