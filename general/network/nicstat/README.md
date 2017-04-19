nicstat
=======

nicstat was written by Brendan Gregg and Tim Cook of Sun Microsystems - originally
for Solaris, ported to Linux.

The official, upstream repository for nicstat is at https://sourceforge.net/projects/nicstat/

This fork
=========

This fork exists primarily to address some bugs in the upstream code. See
[BUGS.md](BUGS.md) for a list of fixed bugs.

The original, imported source is on the
[upstream_1.95](https://github.com/scotte/nicstat/tree/upstream_1.95)
branch of this repository.

This fork has only been tested on Linux. Reasonable effort has been made that
it hasn't been broken in Solaris, but it is possible. Please create a Github
issue if any issues are found (or - even better - a pull request with a fix!).
Thanks.

If any changes are made to the upstream source, I will merge them in in an
attempt to keep this tree in sync with upstream.

Pull requests are welcome for any additional bugs or features as well.

License
=======

nicstat is entirely the property of its originators. All rights, restrictions,
limitations, warranties, etc remain per nicstat's owners and license.

nicstat is licensed under the Artistic License 2.0.  You can find a
copy of this license as [LICENSE.txt](LICENSE.txt) included with the nicstat
distribution, or at http://www.perlfoundation.org/artistic_license_2_0

README_upstream.md
==================

Following is the full contents of [README_upstream.md](README_upstream.md),
which is **README.md** in the sourceforge file listing (but not part of the
source tarball):

* * *

nicstat is a Solaris and Linux command-line that prints out network
statistics for all network interface cards (NICs), including packets,
kilobytes per second, average packet sizes and more.

It was developed by Tim Cook and Brendan Gregg, both formerly of Sun
Microsystems.

Changes for Version 1.95, January 2014
--------------------------------------

## Common

- Added "-U" option, to display separate read and write
  utilization.

- Simplified display code regarding "-M" option.

## Solaris

- Fixed fetch64() to check type of kstats

- Fixed memory leak in update_nicdata_list()

Changes for Version 1.92, October 2012
--------------------------------------

## Common

- Added "-M" option to change throughput statistics to Mbps
  (Megabits per second).  Suggestion from Darren Todd.

- Fixed bugs with printing extended parseable format (-xp)

- Fixed man page's description of extended parseable output.

## Solaris

- Fixed memory leak associated with g_getif_list

- Add 2nd argument to dladm_open() for Solaris 11.1

- Modify nicstat.sh to handle Solaris 11.1

## Linux

- Modify nicstat.sh to see "x86_64" cputype as "i386".  All Linux
  binaries are built as 32-bit, so we do not need to differentiate
  these two cpu types.

Changes for Version 1.90, April 2011
------------------------------------

## Common

- nicstat.sh script, to provide for automated multi-platform
  deployment.  See the Makefile's for details.

- Added "-x" flag, to display extended statistics for each
  interface.

- Added "-t" and "-u" flags, to include TCP and UDP
  (respectively) statistics.  These come from tcp:0:tcpstat
  and udp:0:udpstat on Solaris, or from /proc/net/snmp and
  /proc/net/netstat on Linux.

- Added "-a" flag, which equates to "-tux".

- Added "-l" flag, which lists interfaces and their
  configuration.

- Added "-v" flag, which displays nicstat version.

## Solaris

- Added use of libdladm.so:dladm_walk_datalink_id() to get list of
  interfaces.  This is better than SIOCGLIFCONF, as it includes
  interfaces given exclusively to a zone.  
  NOTE: this library/routine can be linked in to nicstat in "lazy"
  mode, meaning that a Solaris 11 binary built with knowledge of the
  routine will also run on Solaris 10 without failing when the routine
  or library is not found - in this case nicstat will fall back to the
  SIOGLIFCONF method.

- Added search of kstat "link_state" statistics as a third
  method for finding active network interfaces.  See the man
  page for details.

##  Linux

- Added support for SIOCETHTOOL ioctl, so that nicstat can
  look up interface speed/duplex (i.e. "-S" flag not necessarily
  needed any longer).

- Removed need for LLONG_MAX, improving Linux portability.

* * *

README.txt
==========

Following is the full contents of [README.txt](README.txt):

```
nicstat 1.95 README
===================

nicstat is licensed under the Artistic License 2.0.  You can find a
copy of this license as LICENSE.txt included with the nicstat
distribution, or at http://www.perlfoundation.org/artistic_license_2_0


AUTHORS
    timothy.cook@oracle.com (formerly tim.cook@sun.com), Brendan Gregg
    (formerly Brendan.Gregg@sun.com)

HOW TO BUILD ON SOLARIS
    mv Makefile.Solaris Makefile
    make

HOW TO BUILD ON LINUX
    mv Makefile.Linux Makefile
    make

HOW TO INSTALL
    make [BASEDIR=<dir>] install

    Default BASEDIR is /usr/local

HOW TO INSTALL A MULTI-PLATFORM SET OF BINARIES
        1. (Optional) Change BASEDIR, BINDIR and/or MP_DIR in Makefile
    2. make install_multi_platform
    3. (Optional) add links or binaries for your platform(s)

HOME PAGE
    https://blogs.oracle.com/timc/entry/nicstat_the_solaris_and_linux
```
