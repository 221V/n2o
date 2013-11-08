N2O: Erlang Web Framework on WebSockets
=======================================

Samples
-------

Samples provided as Erlang release packaged
with *web* Erlang application which contains modules:

* REST samples
* N2O samples
* XEN support

Run
---

To run just perform on Windows, Linux, BSD and Mac

    $ rebar get-deps compile
    $ ./nitrogen_static.sh
    $ erl -pa deps/*/ebin -config rels/web/files/sys.config
    > application:start(n2o_sample).

And open it in browser [http://localhost:8000](http://localhost:8000)

Xen
---

To run on Xen is a bit tricky:

    $ sudo apt-get install xen-hypervisor-amd64
    $ echo XENTOOLSTACK=xl > /etc/default/xen

Boot into Xen 4.2 Domain-0 and create network bridge:

    $ sudo brctl addbr docker0
    $ sudo ip addr add 172.16.42.1/24 dev docker0

Compile Image at Erlang on Xen builder:

    $ rebar get-deps
    $ rebar compile
    $ ./nitrogen_static.sh
    $ rebar ling-build-image
    $ sudo xl create -c xen.config

Inside Ling start n2o_sample application:

    Ling 0.2.2 is here
    Started in 49438 us
    Erlang [ling-0.2.2]

    Eshell V5.10.2  (abort with ^G)
    1> application:start(n2o_sample).

And open it in browser [http://172.16.42.108:8000](http://172.16.42.108:8000)
