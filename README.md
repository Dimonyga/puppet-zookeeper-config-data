**Current status: development, working. Alpha quality.**



---

##Module based on

https://github.com/ConclusionMC/puppet-zookeeper-config-data

https://github.com/manos/puppet-zookeeper-config-data

##Installation
Go to the modules folder and type:
```
# git clone https://github.com/Dimonyga/puppet-zookeeper-config-data.git zk_puppet
```

Using zk-puppet
---------------

Functions available in puppet, provided by this module:
```puppet
  if ! defined (Class['zk_puppet'])
  {
    include zk_puppet
  }
zkget('/path', 1, ['data']) # returns data at path, with min=1 values returned.
                            # optional 3rd arg is either 'data' or 'children', to
                            # fetch either the data at `path`, or an array of its children
zkput('/path', 'stuff')     # writes the string 'stuff' at path. Will create znodes
                            # in path if required (mkdir -p), and overwrites any data at path
                            #
zkdel('/path/foo', 86400, ['/path', 1])
                          # deletes the node '/path/foo' if its mtime is >
                          # 86400 seconds old. Optional args are: iff '/path' will still
                          # contain >= 1 children after the deletion.
```

These functions store zk data as persistent, non-sequential, and overwrites any
existing data at the specified node.

To use these functions, you *must* have defined two variables as facts (sorry).
Create an empty class called custom_facts (can be called anything you want) or add these facts
to your existing facts path/class.
The custom_facts/manifests/init.pp should be like this:
```
#
# Just an empty class to load the custom facts
#
class custom_facts {}
```
Create this file: custom_facts/lib/facter/zookeeper.rb with the following contents (fill in your own zookeeper server address):
```
Facter.add("zk_server") do
    setcode do
        'zookeeper.example.com'
    end
end
Facter.add("zk_port") do
    setcode do
        '2181'
    end
end
```
Now include this custom_facts class with the nodes who also use this puppet-zookeeper-config class.
This is the only way custom functions can access variables - they must be facts. If you
don't want to use facts, then you'll have to hardcode the zookeeper server address in the zkput, zkget and zkdel functions.

An Example
----------

For example, say you want to store haproxy backend server configuration information
in zookeeper, and use it in the puppet module that sets up the server. (the data
is written by other classes, that use the haproxy module)

This is a great use case! Nodes should be able to register themselves, and the
haproxy class shouldn't know anything about the class (server list) that's called it.

In an haproxy::register class, you take the parameters you need. Say, ip and port.
```puppet
define haproxy::register($ip, $port) { $site_name = $name }
```

Remember, parser functions run on the puppet master (so it needs access to your
zookeeper server). But arguments to zkget and zkput are parsed in the catalog
compilations *for* a host, so $::hostname, $::fqdn, or any fact are valid to use.

Put that information in zookeeper:
```puppet
include zk_puppet
zkput("/puppet/services/haproxy/${site_name}/${::hostname}", $::hostname)
zkput("/puppet/services/haproxy/${site_name}/${::hostname}/ip", $::ipaddr)
zkput("/puppet/services/haproxy/${site_name}/${::hostname}/port", $port)
```

Now that the data is written to zookeeper in a format the haproxy class expects
(this is why I used created haproxy::register), the haproxy class can use it to
construct its config.

in haproxy::backend, for example
```puppet
$servers = zkget("/puppet/services/haproxy/${site_name}", 0, 'children')
```

$servers is now an array, containing a list of servers. But you'll need to get
parameters stored as znode data in zk. Since there is no iteration in puppet,
and inline templates can only return strings, you'll need an intermediary define
to call.

So call haproxy::backend::server_line { $servers: site_name => $site_name }, and in it,
get the parameters you expect, and write the server line in your config (using concat)!
```puppet
include zk_puppet
$server = $name
$ip   = zkget("/puppet/services/haproxy/${site_name}/${server}/ip", 1)
$port = zkget("/puppet/services/haproxy/${site_name}/${server}/port", 1)
```

The 2nd argument is min values. If the ip or port returned nothing from zookeeper,
compilation would fail. If you don't specify a min, zkget can return false, so be
sure to check for that.
```puppet
concat::fragment { $service_name:
    target  => $conf,
    content => "    server ${name} ${ip}:${port} check inter $inter rise $rise fall $fall port $port maxconn $maxconn\n",
    order   => 7,
}
```

TODO: Removing Data
--------------------
zkdel() is coming soon, so you can manage zk nodes completely from within puppet.

This is slightly problematic, in the haproxy use case. If a server disappears, it
will not be deregistered in the setup used in the example. And the only way to
remove it, would be to call zkdel() because puppet knows it's no longer valid -
but this works against the purpose of removing *configuration data* from puppet.

This module was inspired by [https://github.com/Nextdoor/puppet_zkwatcher/],
which uses a python daemon to (de)register nodes. This, too, requires a box to be up,
to notice the service is down, and de-register.

I'll probably write a watcher for specific purposes, that checks the server lists
(children in the tree below $site_name, from the above example), and removes non-responsive
ones daily. That's good enough, as haproxy won't send requests to down backends anyway.

In fact, zkdel() can take an argument to remove anything with a timestamp older
than N time (and leave a minimum number of nodes).
The zkput() function *does* currently re-write the data on every puppet run. So
that's going to work nicely.


NB
---
This is just one example - haproxy is the reason I wrote this module.
Basically, anything you do in puppet, that has hard-coded server lists (or other
config data), can be moved to zookeeper.

Why zookeeper?

Since stored configs / exported resources in puppet are horrible, and I was
already running a production zookeeper ensemble for storm, this was a natural
evolution :)

