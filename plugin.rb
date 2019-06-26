# name: discourse-vivokey-openid
# about: Add support for VivoKey OpenID as a login provider
# version: 1.0
# authors: David Taylor
# url: https://github.com/VivoKey/plugin-discourse

require_relative "lib/vivo_key_authenticator"


# TODO: remove this check once Discourse 2.2 is released
if Gem.loaded_specs['jwt'].version > Gem::Version.create('2.0')
  auth_provider authenticator: VivoKeyAuthenticator.new(),
                full_screen_login: true
else
  STDERR.puts "WARNING: discourse-vivokey-openid requires Discourse v2.2.0.beta7 or above. The plugin will not be loaded."
end
