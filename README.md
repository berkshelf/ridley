# Ridley
[![Gem Version](https://badge.fury.io/rb/ridley.png)](http://badge.fury.io/rb/ridley)
[![Build Status](https://secure.travis-ci.org/RiotGames/ridley.png?branch=master)](http://travis-ci.org/RiotGames/ridley)
[![Dependency Status](https://gemnasium.com/RiotGames/ridley.png?travis)](https://gemnasium.com/RiotGames/ridley)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/RiotGames/ridley)

A reliable Chef API client with a clean syntax

## Installation

    $ gem install ridley

## Known Issues

* Sandboxes has not been implemented
* Full support for Cookbooks is not included
* Acceptance test suite needs to be refactored

## Usage

Require Ridley into your application

    require 'ridley'

## Creating a new Ridley client

    conn = Ridley.new(
      server_url: "https://api.opscode.com",
      client_name: "reset",
      client_key: "/Users/reset/.chef/reset.pem",
      organization: "ridley"
    )

Creating a new connection requires you to specify at minimum:

* server_url
* client_name
* client_key

An optional organization option can be specified if you are working with Hosted or Private Chef (OHC/OPC). For a full list of available options see the [yard documentation](http://rubydoc.info/gems/ridley).

Connections can also be instantiated by a helper function: `Ridley.new`

    Ridley.new(
      server_url: "https://api.opscode.com",
      client_name: "reset",
      client_key: "/Users/reset/.chef/reset.pem"
    )

Using a connection object you can interact with collections of resources on a Chef server. Resources are:

* Nodes
* Roles
* Environments
* Clients
* Cookbooks
* Data Bags

Here is a simple example of instantiating a new connection and listing all of the roles on a Chef server.

    conn = Ridley.new(...)
    conn.role.all => []

For more information scroll down to the Manipulating Chef Resources section of this README.

### Synchronous execution

An alternative syntax is provided if you want to perform multiple requests, in order, on a connection.

    conn = Ridley.new(...)

    conn.sync do
      role.all
      role.find("reset")
      role.create(name: "ridley-test")
      role.delete("reset")
    end

The `sync` function on the connection object takes a block with no arguments and allows you to access the DSL within the block. You can address any one of the resources within the sync block:

    conn.sync do
      environment.all
      node.all
      ...
    end

A helper function exists to allow you to express yourself in a one-liner: `Ridley.sync`

    Ridley.sync(server_url: "https://api.opscode.com", ...) do
      role.all => []
    end

### Asynchronous execution

__COMING SOON__

## Manipulating Chef Resources

All resource can be listed, created, retrieved, updated, or destroyed. Some resources have additional functionality described in [their documentation](http://rubydoc.info/gems/ridley).

### Listing all resources

You use a connection to interact with the resources on the remote Chef server it is pointing to. For example, if you wanted to get a list of all of the roles on your Chef server:

    conn = Ridley.new(...)
    conn.role.all           => []

Calling `role.all` on the connection object will return an array of Ridley::RoleResource objects. All of the resources can be listed, not just Roles:

    conn = Ridley.new(...)
    conn.node.all           => [<#Ridley::NodeResource>]
    conn.role.all           => [<#Ridley::RoleResource>]
    conn.environment.all    => [<#Ridley::EnvironmentResource>]
    conn.client.all         => [<#Ridley::ClientResource>]
    conn.cookbook.all       => [<#Ridley::CookbookResource>]
    conn.data_bag.all       => [<#Ridley::DataBagResource>]

### Creating a resource

A new resource can be created in a few ways

_Create by instantiate and save_

    conn = Ridley.new(...)
    obj = conn.role.new

    obj.name = "reset"
    obj.save => <#Ridley::RoleResource: @name="reset">

_Create by the `create` function with attribute hash_

    conn = Ridley.new(...)
    conn.role.create(name: "reset") => <#Ridley::RoleResource: @name="reset">

_Create by the `create` function with a resource object_

    conn = Ridley.new(...)
    obj = conn.role.new

    obj.name = "reset"
    conn.role.create(obj) => <#Ridley::RoleResource: @name="reset">

Each of these methods is identical, it is up to you on how you'd like to create new resources.

### Retrieving a resource

There are two functions for retrieving a resource. `find` and `find!`. If you are familiar with ActiveRecord; these are the functions used to pull records out of the database.

Both `find` and `find!` will return a resource but if the resource is not found on the Chef server `find!` will raise an exception while `find` will return `nil`.

If you were following allong in the previous section we created a role named `reset`. We'll assume that role has been created in this next example.

    conn = Ridley.new(...)

    conn.role.find("reset") => <#Ridley::RoleResource: @name="reset">
    conn.role.find!("reset") => <#Ridley::RoleResource: @name="reset">

Now if we attempt to find a role that does not exist on the Chef server

    conn = Ridley.new(...)

    conn.role.find("not_there") => nil
    conn.role.find!("not_there") =>
    Ridley::Errors::HTTPNotFound: errors: 'Cannot load role reset'
      from /Users/reset/code/ridley/lib/ridley/middleware/chef_response.rb:11:in `on_complete'
      from /Users/reset/.rbenv/versions/1.9.3-p194/lib/ruby/gems/1.9.1/gems/faraday-0.8.1/lib/faraday/response.rb:9:in `block in call'
      from /Users/reset/.rbenv/versions/1.9.3-p194/lib/ruby/gems/1.9.1/gems/faraday-0.8.1/lib/faraday/response.rb:63:in `on_complete'
      from /Users/reset/.rbenv/versions/1.9.3-p194/lib/ruby/gems/1.9.1/gems/faraday-0.8.1/lib/faraday/response.rb:8:in `call'
      from /Users/reset/code/ridley/lib/ridley/middleware/chef_auth.rb:31:in `call'
      from /Users/reset/.rbenv/versions/1.9.3-p194/lib/ruby/gems/1.9.1/gems/faraday-0.8.1/lib/faraday/connection.rb:226:in `run_request'
      from /Users/reset/.rbenv/versions/1.9.3-p194/lib/ruby/gems/1.9.1/gems/faraday-0.8.1/lib/faraday/connection.rb:87:in `get'
      from /Users/reset/code/ridley/lib/ridley/resource.rb:115:in `find!'
      from /Users/reset/code/ridley/lib/ridley/context.rb:22:in `method_missing'
      from (irb):6
      from /Users/reset/.rbenv/versions/1.9.3-p194/bin/irb:12:in `<main>'

### Updating a resource

Like creating a resource, updating a resource can also be expressed a few different ways

_Update by the `update` function with an id and attribute hash_

    conn = Ridley.new(...)
    conn.role.update("reset", description: "testing updates!") => <#Ridley::RoleResource: @name="reset", @description="testing updates!">

_Update by the `update` function with a resource object_

    conn = Ridley.new(...)
    obj = conn.role.find("reset")
    obj.description = "resource object!"

    conn.role.update(obj) => <#Ridley::RoleResource: @name="reset", @description="resource object!">

_Update by saving a resource object_

    conn = Ridley.new(...)
    obj = conn.role.find("reset")

    obj.description = "saving an object!"
    obj.save => <#Ridley::RoleResource: @name="reset", @description="saving an object!">

### Deleting a resource

Like creating or updating a resource, there are a few ways deleting a resource can be expressed

_Delete by the `delete` function with an id_

    conn = Ridley.new(...)
    conn.role.delete("reset") => <#Ridley::RoleResource: @name="reset">

_Delete by the `delete` function with a resource object_

    conn = Ridley.new(...)
    obj = conn.role.find("reset")

    conn.role.delete(obj) => <#Ridley::RoleResource: @name="reset">

_Delete by the `destroy` function on a resource object_

    conn = Ridley.new(...)
    obj = conn.role.find("reset")

    obj.destroy => true

### Regenerating a client's private key

_Regenerate function on a context with an id_

    conn = Ridley.new(...)
    conn.client.regenerate_key("jwinsor") => <#Ridley::ClientResource: @name="jwinsor", @private_key="HIDDEN">

_Regenerate function on an instantiated resource object_

    conn = Ridley.new(...)
    obj = conn.client.find("jwinsor")

    obj.regenerate_key => <#Ridley::ClientResource: @name="jwinsor", @private_key="HIDDEN">

## Manipulating Data Bags and Data Bag Items

A data bag is managed exactly the same as any other Chef resource

    conn = Ridley.new(...)
    conn.data_bag.create("ridley-test")

You can create, delete, update, or retrieve a data bag exactly how you would expect if you read through the
Manipulating Chef Resources portion of this document.

Unlike a role, node, client, or environment, a data bag is a container for other resources. These other resources are Data Bag Items. Data Bag Items behave slightly different than other resources. Data Bag Items can have an abritrary attribute hash filled with any key values that you would like. The one exception is that every Data Bag Item __requires__ an 'id' key and value. This identifier is the name of the Data Bag Item.

### Creating a Data Bag Item

    conn = Ridley.new(...)
    data_bag = conn.data_bag.create("ridley-test")

    data_bag.item.create(id: "appconfig", host: "reset.local", user: "jwinsor") => 
      <#Ridley::DataBagItemResource: @id="appconfig", @host="reset.local", @user="jwinsor">

### Saving a Data Bag Item

    conn = Ridley.new(...)
    data_bag = conn.data_bag.create("ridley-test")

    dbi = data_bag.item.new
    dbi[:id] = "appconfig"
    dbi[:host] = "reset.local"
    dbi.save => true

## Searching

    conn = Ridley.new(...)
    conn.search(:node)
    conn.search(:node, "name:ridley-test.local")

Search will return an array of Ridley resource objects if one of the default indices is specified. Chef's default indices are

* node
* role
* client
* environment

## Manipulating Attributes

Using Ridley you can quickly manipulate node or environment attributes. Attributes are identified by a dotted path notation.

    default[:my_app][:billing][:enabled] => "my_app.billing.enabled"

Given the previous example you could set the default node attribute with the `set_default_attribute` function on a Node object

### Node Attributes

Setting the `node[:my_app][:billing][:enabled]` node level attribute on the node "jwinsor-1"

    conn = Ridley.new
    conn.sync do
      obj = node.find("jwinsor-1")
      obj.set_attribute("my_app.billing.enabled", false)
      obj.save
    end

### Environment Attributes

Setting a default environment attribute is just like setting a node level default attribute

    conn = Ridley.new
    conn.sync do
      obj = environment.find("production")
      obj.set_default_attribute("my_app.proxy.enabled", false)
      obj.save
    end

And the same goes for setting an environment level override attribute

    conn = Ridley.new
    conn.sync do
      obj = environment.find("production")
      obj.set_override_attribute("my_app.webapp.enabled", false)
      obj.save
    end

### Role Attributes

    conn = Ridley.new
    conn.sync do
      obj = role.find("why_god_why")
      obj.set_default_attribute("my_app.proxy.enabled", false)
      obj.save
    end

    conn.sync do
      obj = role.find("why_god_why")
      obj.set_override_attribute("my_app.webapp.enabled", false)
      obj.save
    end

## Bootstrapping nodes

    conn = Ridley.new(
      server_url: "https://api.opscode.com",
      organization: "vialstudios",
      validator_client: "vialstudios-validator",
      validator_path: "/Users/reset/.chef/vialstudios-validator.pem",
      ssh: {
        user: "vagrant",
        password: "vagrant"
      }
    )

    conn.node.bootstrap("33.33.33.10", "33.33.33.11")

# Authors and Contributors

* Jamie Winsor (<reset@riotgames.com>)

Thank you to all of our [Contributors](https://github.com/RiotGames/ridley/graphs/contributors), testers, and users.
