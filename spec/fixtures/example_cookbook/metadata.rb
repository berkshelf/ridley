name             "example_cookbook"
maintainer       "Jamie Winsor"
maintainer_email "jamie@vialstudios.com"
license          "Apache 2.0"
description      "Installs/Configures example_cookbook"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          "0.1.0"

attribute "example_cookbook/test",
  :display_name => "Test",
  :description => "Test Attribute",
  :choice => [
    "test1",
    "test2" ],
  :type => "string",
  :required => "recommended",
  :recipes => [ 'example_cookbook::default' ],
  :default => "test1"
  