require_relative 'httpclient_ext/cookie'

::WebAgent::Cookie.send(:include, ::Ridley::HTTPClientExt::WebAgent::Cookie)
