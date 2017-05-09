#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Ceph monitoring plugin for CollectD.
#
# Intended to be used with the python plugin for CollectD, using
# a configuration like the following:
#
#	<LoadPlugin python>
#	  Globals true
#	</LoadPLugin>
#	
#	<Plugin python>
#	  ModulePath "/path/to/collectd-ceph"
#	  LogTraces true
#	  Interactive false
#	  Import "collectd-ceph"
#	  <Module collectd-ceph>
#	    SocketPath "/run/ceph"
#	    Suffix ".asok"
#	    CephPath "/usr/bin/ceph"
#           LogRawAverages false
#	  </Module>
#	</Plugin>
#
#
# © 2014 David McBride <dwm37@cam.ac.uk>
# University of Cambridge, England
#
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License, version 2.1,
# as published by the Free Software Foundation.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this code.  If not, see <http://www.gnu.org/licenses/>.

# --- Compiler directives ---

import collectd
import json
import glob
import subprocess

# --- Define globals ---

# The path to look in for Ceph admin sockets.
socketpath = '/run/ceph'

# The file extension to glob for.
socketsuffix = '.asok'

# The path to the 'ceph' admin binary.
cephpath = '/usr/bin/ceph'

# Whether or not to report raw average metric data.
# (i.e. 'sum' and 'avgcount'.)
rawaverage = False

# This is a dictionary that we use to keep track of historical average
# values.  This enables us to report, rather than the global average, 
# deltas over time which is more useful.
#
# keys are the flattened name of the metric.
# values are a tuple of (sum, count)
previousavg = {}

# --- Define functions ---

# Callback functions.
def init():
    """
    Initialization function, to be invoked by the CollectD master process.
    """

    # Throw away any recorded historical average values, just in case.
    previousavg = {}

    collectd.info('python-ceph: Initialized.')


def config(conf):
    """
    Accept module configuration from CollectD.
    """

    # TODO: This would benefit from more sanity-checking.
    for c in conf.children:
        if c.key == 'SocketPath':
            socketpath = c.values[0]
        if c.key == 'Suffix':
            socketsuffix = c.values[0]
        if c.key == 'CephPath':
            socketsuffix = c.values[0]
        if c.key == 'LogRawAverages':
            rawaverage = c.values[0]

    collectd.info('python-ceph: Using socketpath="{s}", suffix="{u}", cephpath="{c}".'.format( 
        s=socketpath, u=socketsuffix, c=cephpath)
    )


def read_all():
    """
    Query all of the local Ceph daemons via their admin sockets.
    """
    # for every file in the socket directory ending with the socket suffix,
    for socket in glob.glob(socketpath + '/*' + socketsuffix):
        # Dump all of the Ceph performance data as a json object.
        collectd.debug('python-ceph: Dumping performance data from socket {s}'.format( s=socket ))

        schemajson = subprocess.check_output([
            cephpath, 
            "--admin-daemon", 
            socket, 
            "perf", 
            "schema"])      

        datajson = subprocess.check_output([
            cephpath, 
            "--admin-daemon", 
            socket, 
            "perf", 
            "dump"])
      
        collectd.debug('python-ceph: JSON data blob: ' + datajson)
        collectd.debug('python-ceph: JSON schema blob: ' + schemajson)
 
        # Extract the name of the admin socket.
        #  This is the same as the socket path we've been handed, minus 
        #  the socketsuffix from the end and the socketpath (and '/') from 
        #  the beginning.
	name = socket.replace(socketpath, "", 1)
        name = name.lstrip('/')
        offset = name.rindex(socketsuffix)
        name = name[:offset]
        
        # Dispatch the json values to CollectD, along with the name of the 
        # process which gave it to us.
        dispatch_json(datajson, schemajson, name)

# Utility functions

def dispatch_json(datablob, schemablob, daemonname):
    """
    Given some JSON-formatted data and schema inputs, and the name of
    the daemon it was acquired from, parse the values within and dispatch
    them to CollectD.

    This iterates through each element of the schema JSON, determines whether
    the corresponding data should be treated as a counter or gauge, processes
    average information as appropriate, and dispatches it for processing.
    """
    data = json.loads(datablob)
    schema = json.loads(schemablob)

    # Construct a template Values object.  This is effectively a struct that
    # we populate and pass to CollectD proper.
    v = collectd.Values()

    # These values don't change between submissions.
    v.plugin = "ceph"
    v.plugin_instance = daemonname

    for key, value, typevalue in flatten_cephdata(schema, data, daemonname):

        collectd.debug('python-ceph: Logging key {k} with value {v} and type {t} using plugin ceph-{d}.'.format(
            k=key, v=value, t=typevalue, d=daemonname)
        )

        # Dispatch.
        v.type_instance = key
        v.values = [value]
        v.type = typevalue

        v.dispatch()

def flatten_cephdata(schema, data, daemonname, sep='.', prefix=None):
    """
    Returns an iterator that produces a flattened version of
    the provided Ceph schema and data dumps supplied as input.

    The iterator produces tuples of the form (name, value, type).

    The type information supplied by the Ceph schema is used to determine
    what type information is returned.  This is represented as either the 
    string 'gauge' or the string 'counter', as appropriate.

    Note that some information processing will take place if the schema
    data indicates that a Ceph 'average' value is being considered.  If so, 
    and if this function has been passed average data for that specific metric
    before, then it will calculate the average for the previous measurement 
    interval and yield that.  This differs from all other data, which is simply
    returned verbatim.

    (If the global configuration specifies that the raw 'sum' and 
    'avgcount' reported by Ceph for each 'average' metric should be returned,
    then that information will also be yielded by the iterator.)

    The names generated for each tuple will be the concatenation of the 
    dictionary keys that identify that value, separated by the
    given separator.  (Defaults to a dot, '.').

    For example, supplying the data:

     { 'a': 0.03,
       'b': { 'c': 2,
              'd': { sum: 400.0, avgcount: 4 }
            },
       'e': 4 }

    And the schema:

     { 'a': { type: 1 },
       'b': { 'c' : { type: 2 },
              'd' : { type: 6 },
            },
       'e': { type: 10 } }

    ... will produce the output:

     [ ('a',           0.03,  'gauge'  ),
       ('b.c',         2,     'gauge'  ),
       ('b.d',         100,   'gauge'  ),
       ('e',           4,     'counter') ]

    (Note that the value for 'b.d' assumes that the previous measure
     for both the sum and avgcount were recorded as zero.)

    If LogRawAverages is defined to be True, then it will also yield:

     [ ('b.d.sum,      400.0, 'gauge'  ),
       ('b.d.avgcount, 4,     'counter') ]

    This code was originally inspired by the flatten_dictionary() method 
    in the Diamond Ceph collector, which is made available under the MIT
    license.

    The behaviour of this function in the event that the schema
    and data data-structures are not consistent with each other is undefined.
    """

    for key, value in sorted(schema.items()):
        # Construct the canonical name for the value of this item.
        # (Use a filter to handle the case where prefix is None.)
        name = sep.join(filter(None, [prefix,key]))

        # If the value is a dictionary containing a key 'type', we've hit 
        # a leaf node.
        if 'type' in value:
            # Determine what type we're dealing with.
            floattype, inttype, avgtype, counttype = cephtype(value['type'])

            # We currently ignore the specification of float and integer types;
            # the JSON library parser figures that out for us.

            # What we care about is whether or not we're dealing with a 
            # COUNTER or a GUAGE, as indicated by the counttype bit.
            typevalue = "gauge"
            if (counttype):
                typevalue = "counter"

            # We also care about whether we're dealing with average values.
            if (avgtype):
                # First, look up the two individual metrics reported by Ceph.
                currentsum = data[key]['sum']
                currentcount = data[key]['avgcount']

                # Yield these values if we're configured to do so.
                if rawaverage:
                    yield (name + ".sum", currentsum, typevalue)
                    yield (name + ".count", currentcount, counter)

                # But we also want to calculate the average for the previous 
                # measuring interval.  For this, we need to look up what data we
                # saw previously.

                # First, make sure that we have initialized the data-structure
                # for this particular daemon.
                if daemonname not in previousavg:
                    previousavg[daemonname] = {}

                # Then check to see if we have historical information logged 
                # for this daemon and this metric.
                if name in previousavg[daemonname]:
                    # We do indeed have historical data for this metric.
                    oldsum, oldcount = previousavg[daemonname][name]
                    deltasum = currentsum - oldsum
                    deltacount = currentcount - oldcount

                    collectd.debug('python-ceph: Average calculation: daemon {x}, metric {n} --- old: sum={a} count={b} new: sum={c} count={d} delta: sum={e} count={f}'.format(
                        x=daemonname,
                        n=name,
                        a=oldsum,
                        b=oldcount,
                        c=currentsum,
                        d=currentcount,
                        e=deltasum,
                        f=deltacount)
                    )

                    # If new data-points have been added, return the average 
                    # for the previous interval.
                    if deltacount > 0:
                        average = deltasum / deltacount
                        yield (name, average, typevalue)

                # Finally, store the current raw average values so that we can
                # compare against them the next time we're invoked.
                previousavg[daemonname][name] = (currentsum, currentcount)

            else:
                # We're not dealing with an average value, so just report it
                # directly.
                yield (name, data[key], typevalue)
        else:
            # This is not a leaf node, and we need to recurse.  
            # Note that we have to carefully descend down equivilent paths in 
            # both the schema and data nested dictionaries.
            for result in flatten_cephdata(value, data[key], daemonname, sep=sep, prefix=name):
                yield result

def cephtype(bitfield):
    """
    Determine what Ceph types the given value type indicates.
    Value is a bitmask, with the following definitions:
 
            float = 0x1
            int   = 0x2
            avg   = 0x4
            count = 0x8

    Returns a tuple of boolean values for each of the above types,
    in order.
    """

    return ( bool(bitfield & 0x1),
             bool(bitfield & 0x2),
             bool(bitfield & 0x4),
             bool(bitfield & 0x8) )

# --- Main program ---

# Register functions.
collectd.register_init(init)
collectd.register_config(config)
collectd.register_read(read_all)
