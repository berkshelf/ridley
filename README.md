# Ridley
[![Gem Version](https://badge.fury.io/rb/ridley.png)](http://badge.fury.io/rb/ridley)
[![Build Status](https://secure.travis-ci.org/RiotGames/ridley.png?branch=master)](http://travis-ci.org/RiotGames/ridley)
[![Dependency Status](https://gemnasium.com/RiotGames/ridley.png?travis)](https://gemnasium.com/RiotGames/ridley)
[![Code Climate](https://codeclimate.com/github/RiotGames/ridley.png)](https://codeclimate.com/github/RiotGames/ridley)

A reliable Chef API client with a clean syntax

Installation
------------
Add Ridley to your `Gemfile`:

```ruby
gem 'ridley'
```

And run the `bundle` command to install. Alternatively, you can install the gem directly:

    $ gem install ridley

Usage
-----
Before you can use Ridley, you must require it in your application:

```ruby
require 'ridley'
```

### Creating a new Ridley client

```ruby
ridley = Ridley.new(
  server_url: "https://api.opscode.com/organizations/ridley",
  client_name: "reset",
  client_key: "/Users/reset/.chef/reset.pem"
)
```

Creating a new instance of Ridley requires the following options:

- server_url
- client_name
- client_key

client_key can be either a file path or the client key as a string. You can also optionally supply an encrypted data bag secret for decrypting encrypted data bags. The option is "encrypted_data_bag_secret" This can be a file name or the key itself as a string.

    ridley = Ridley.new(
      server_url: "https://api.opscode.com/organizations/ridley",
      client_name: "reset",
      client_key: "some key data",
      encrypted_data_bag_secret: "File path or key as a string"
    )

Ridley exposes a number of functions that return resources which you can use to retrieve or create objects on your Chef server. Here is a simple example of getting a list of all the roles on your Chef server.

```ruby
ridley = Ridley.new(...)
ridley.role.all #=> [
  #<Ridley::RoleObject chef_id:motherbrain_srv ...>,
  #<Ridley::RoleObject chef_id:motherbrain_proxy ...>
]
```

For more information scroll down to the Manipulating Chef Resources section of this README.

You can also tell Ridley to read the values from your Chef config (knife.rb):

```ruby
ridley = Ridley.from_chef_config('/path/to/knife.rb')
ridley.role.all #=> [
  #<Ridley::RoleObject chef_id:motherbrain_srv ...>,
  #<Ridley::RoleObject chef_id:motherbrain_proxy ...>
]
```

The mapping between Chef Config values and Ridley values is:

<table>
  <thead>
    <tr>
      <th>Ridley</th>
      <th>Chef</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>validator_client</td>
      <td>validation_client_name</td>
    </tr>
    <tr>
      <td>validator_path</td>
      <td>validation_key</td>
    </tr>
    <tr>
      <td>client_name</td>
      <td>node_name</td>
    </tr>
    <tr>
      <td>server_url</td>
      <td>chef_server_url</td>
    </tr>
  </tbody>
</table>

Additionally, you can leave the path blank and Ridley will perform a "knife.rb search" the same way Chef does:

```ruby
ridley = Ridley.from_chef_config
ridley.role.all #=> [
  #<Ridley::RoleObject chef_id:motherbrain_srv ...>,
  #<Ridley::RoleObject chef_id:motherbrain_proxy ...>
]
```

If you don't want to instantiate and manage a connection object you can use `Ridley.open` to open a connection, do some work, and it will be closed for you after the block executes.

```ruby
Ridley.open(server_url: "https://api.opscode.com", ...) do |r|
  r.node.all
end
```

### Manipulating Chef Resources

Resources are access by instance functions on a new instance of `Ridley::Client`.

```ruby
ridley = Ridley.new(...)
ridley.client      #=> Ridley::ClientResource
ridley.cookbook    #=> Ridley::CookbookResource
ridley.data_bag    #=> Ridley::DataBagResource
ridley.environment #=> Ridley::EnvironmentResource
ridley.node        #=> Ridley::NodeResource
ridley.role        #=> Ridley::RoleResource
ridley.sandbox     #=> Ridley::SandboxResource
ridley.search      #=> Ridley::SearchResource
```

DataBagItems are the only exception to this rule. The DataBagItem resource is accessed from a DataBagObject

```ruby
data_bag = ridley.data_bag.find("my_data")
data_bag.item                 #=> Ridley::DataBagItemResource
data_bag.item.find("my_item") #=> Ridley::DataBagItemObject
```

### CRUD

Most resources can be listed, retrieved, created, updated, and destroyed. These are commonly referred to as CRUD (Create Read Update Delete) operations.

#### Create

A new Chef Object can be created in a four ways

_With the `#create` function and an attribute hash_

```ruby
ridley = Ridley.new(...)
ridley.role.create(name: "reset") #=> #<Ridley::RoleObject: chef_id:reset>
```

_With the `#create` function and an instance of a Chef Object_

```ruby
obj = ridley.role.new
obj.name = "reset"
ridley.role.create(obj) #=> #<Ridley::RoleObject: chef_id:reset>
```

_With the `#save` function on an instance of a Chef Object_

```ruby
obj = ridley.role.new
obj.name = "reset"
obj.save #=> #<Ridley::RoleObject: chef_id:reset>
```

_With the `#save` function on an instance of a Chef Object built from serialized json_

    obj = ridley.role.from_file('/path/to/role.json')
    obj.save #=> #<Ridley::RoleObject: chef_id:reset>

Each of these methods produce an identical object on the Chef server. It is up to you on how you'd like to create new resources.

#### Read

Most resources have two read functions

- `#all` for listing all the Chef Objects
- `#find` for retrieving a specific Chef Object

##### Listing

If you wanted to get a list of all of the roles on your Chef server

```ruby
ridley = Ridley.new(...)
ridley.role.all #=> [
  #<Ridley::RoleObject chef_id:motherbrain_srv ...>,
  #<Ridley::RoleObject chef_id:motherbrain_proxy ...>
]
```

##### Finding

If you want to retrieve a single role from the Chef server

```ruby
ridley = Ridley.new(...)
ridley.role.find("motherbrain_srv") #=> #<Ridley::RoleObject: chef_id:motherbrain_srv ...>
```

If the role does not exist on the Chef server then `nil` is returned

```ruby
ridley = Ridley.new(...)
ridley.role.find("not_there") #=> nil
```

#### Update

Updating a resource can be expressed in three ways

_With the `#update` function, the ID of the Object to update, and an attributes hash_

```ruby
ridley = Ridley.new(...)
ridley.role.update("motherbrain_srv", description: "testing updates") #=> #<Ridley::RoleObject chef_id:motherbrain_srv, description="testing updates" ...>
```

_With the `#update` function and an instance of a Chef Object_

```ruby
obj = ridley.role.find("motherbrain_srv")
obj.description = "chef object"

ridley.role.update(obj) #=> #<Ridley::RoleObject: chef_id:motherbrain_srv, description="chef object" ...
```

_With the `#save` function on an instance of a Chef Object_

```ruby
obj = ridley.role.find("reset")
obj.description = "saving an object"
obj.save #=> #<Ridley::RoleObject: chef_id:motherbrain_srv, description="saving an object" ...>
```

#### Destroy

Destroying a resource can be express in three ways

_With the `#delete` function and the ID of the Object to destroy_

```ruby
ridley = Ridley.new(...)
ridley.role.delete("motherbrain_srv") => #<Ridley::RoleObject: chef_id:motherbrain_srv ...>
```

_With the `#delete` function and a Chef Object_

```ruby
obj = ridley.role.find("motherbrain_srv")
ridley.role.delete(obj) => #<Ridley::RoleObject: chef_id:motherbrain_srv ...>
```

_With the `#destroy` function on an instance of a Chef Object_

```ruby
obj = conn.role.find("motherbrain_srv")
obj.destroy #=> true
```

Client Resource
---------------

### Regenerating a client's private key

_With the `#regnerate_key` function and the ID of the Client to regenerate_

```ruby
ridley = Ridley.new(...)
ridley.client.regenerate_key("jamie") #=> #<Ridley::ClientObject: chef_id:"jamie", private_key="**HIDDEN***" ...>
```

_With the `#regenerate_key` function on an instance of a Client Object_

```ruby
obj = ridley.client.find("jamie")
obj.regenerate_key #=> #<Ridley::ClientObject: chef_id:"jamie", private_key="**HIDDEN***" ...>
```

Cookbook Resource
-----------------

Data Bag Resource
-----------------

A data bag is managed exactly the same as any other Chef resource

```ruby
ridley = Ridley.new(...)
ridley.data_bag.create(name: "ridley-test")
```

You can create, delete, update, or retrieve a data bag exactly how you would expect if you read through the
Manipulating Chef Resources portion of this document.

Unlike a role, node, client, or environment, a data bag is a container for other resources. These other resources are Data Bag Items. Data Bag Items behave slightly different than other resources. Data Bag Items can have an abritrary attribute hash filled with any key values that you would like. The one exception is that every Data Bag Item __requires__ an 'id' key and value. This identifier is the name of the Data Bag Item.

### Creating a Data Bag Item

```ruby
ridley   = Ridley.new(...)
data_bag = ridley.data_bag.create(name: "ridley-test")

data_bag.item.create(id: "appconfig", host: "reset.local", user: "jamie") #=> #<Ridley::DataBagItemObject: chef_id:appconfig, host="reset.local", user="jamie">
```

Environment Resource
--------------------

### Setting Attributes

Setting a default environment attribute is just like setting a node level default attribute

```ruby
ridley = Ridley.new(...)
production_env = ridley.environment.find("production")
production_env.set_default_attribute("my_app.proxy.enabled", false)
production_env.save #=> true
```

And the same goes for setting an environment level override attribute

```ruby
production_env.set_override_attribute("my_app.proxy.enabled", false)
production_env.save #=> true
```

Node Resource
-------------

### Bootstrapping Unix nodes

```ruby
ridley = Ridley.new(
  server_url: "https://api.opscode.com",
  organization: "vialstudios",
  validator_client: "vialstudios-validator",
  validator_path: "/Users/reset/.chef/vialstudios-validator.pem",
  ssh: {
    user: "vagrant",
    password: "vagrant"
  }
)

ridley.node.bootstrap("33.33.33.10", "33.33.33.11")
```

### Bootstrapping Windows Nodes

Windows Nodes are bootstrapped using a combination of WinRM, Batch, and PowerShell. You will probably need to tweak some settings on your Windows servers to ensure the commands are successful.

#### WinRM Settings

1. Enable WinRM: `winrm quickconfig` and say Yes.
2. Set some WinRM settings to ensure that you don't get 401 Unauthorized responses and 500 Responses because of timeouts.

```
winrm set winrm/config/service/auth @{Basic="true"}
winrm set winrm/config/service @{AllowUnencrypted="true"}
winrm set winrm/config/service @{EnumerationTimeoutms="600000"}
winrm set winrm/config @{MaxTimeoutms="600000"}
winrm set winrm/config/client @{TrustedHosts="*"}
```

#### PowerShell Settings

1. You should also configure your PowerShell profile, so that PowerShell commands have a more lenient timeout period.

```
mkdir C:\Users\my_user\Documents\WindowsPowerShell
echo "$PSSessionOption = New-PSSessionOption -OpenTimeout 0 -CancelTimeout 0 -IdleTimeout 0 -OperationTimeout 0" > C:\Users\my_user\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

Verify the PowerShell settings by opening up the PowerShell Console and entering `$PSSessionOption` and ensure those values are set, and that there are no errors output.

The following links offer some information about configuring a machine's PowerShell settings:
- [PowerShell Profiles](http://technet.microsoft.com/en-us/library/ee692764.aspx)
- [The $PSSessionOptions Preference Variable](http://technet.microsoft.com/library/hh847796.aspx)
- [Creating a new PSSessionOption](http://technet.microsoft.com/en-us/library/hh849703.aspx)

You may also want to tweak your Windows boxes a bit more ex: turning UAC off, turning off the Windows Firewall.

Role Resource
-------------

### Role Attributes

Setting role attributes is just like setting node and environment attributes

```ruby
ridley = Ridley.new(...)
my_app_role = ridley.role.find("my_app")
my_app_role.set_default_attribute("my_app.proxy.enabled", false)
my_app_role.save #=> true
```

And the same goes for setting an environment level override attribute

```ruby
my_app_role.set_override_attribute("my_app.proxy.enabled", false)
my_app_role.save #=> true
```

Sandbox Resource
----------------

Search Resource
---------------

```ruby
ridley = Ridley.new(...)
ridley.search(:node)
ridley.search(:node, "name:ridley-test.local")
```

Search will return an array of the appropriate Chef Objects if one of the default indices is specified. The indices are

-  node
-  role
-  client
-  environment

Authors and Contributors
------------------------
- Jamie Winsor (<jamie@vialstudios.com>)
- Kyle Allan (<kallan@riotgames.com>)

Thank you to all of our [Contributors](https://github.com/RiotGames/ridley/graphs/contributors), testers, and users.
