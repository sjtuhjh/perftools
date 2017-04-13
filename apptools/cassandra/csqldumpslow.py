#! /usr/bin/env python2.7

from __future__ import print_function

import re
import sys
import json
import argparse
import textwrap


class queryStats:
    """ Container and pretty-printer for slow query statistics"""
    __slots__ = ["time", "avg", "mintime", "maxtime", "count"]

    def __init__(self, time=0, avg=0, mintime=0, maxtime=0, count=1):
        if count == 1:
            self.time = self.avg = self.mintime = self.maxtime = time
            self.count = 1
        else:
            self.avg = avg
            self.mintime = mintime
            self.maxtime = maxtime
            self.count = count
            self.time = time

    def __str__(self):
        if self.count == 1:
            return "{}ms".format(self.time)
        else:
            return "{}ms ({}ms) Min: {}ms Max: {}ms".format(
                    self.avg,
                    self.time,
                    self.mintime,
                    self.maxtime
                    )


class slowQuery:
    """ Container and pretty-printer for slow query """
    __slots__ = ["operation", "stats", "timeout",
                 "keyspace", "table", "is_cross_node"]

    def __init__(self, operation, stats, timeout,
                 keyspace=None, table=None, is_cross_node=False):
        self.operation = operation
        self.stats = stats
        self.timeout = timeout
        self.keyspace = keyspace
        self.table = table
        self.is_cross_node = is_cross_node

    def __str__(self):
        return "  Time: {} {} Timeout: {}\n\t{}\n".format(
            self.stats,
            "(cross-node)" if self.is_cross_node else "",
            self.timeout,
            self.operation)


class logParser:
    __slots__ = [
                    "queries",
                    "sort_attribute",
                    "reverse",
                    "top",
                    "top_count",
                    "json_input"
                ]
    regexes = {
            'start': re.compile('DEBUG.*- (\d+) operations were slow in the last (\d+) msecs:$'), # noqa
            'single': re.compile('<(.*)>, time (\d+) msec - slow timeout (\d+) msec(/cross-node)?$'), # noqa
            'multi': re.compile('<(.*)>, was slow (\d+) times: avg/min/max (\d+)/(\d+)/(\d+) msec - slow timeout (\d+) msec(/cross-node)?$'), # noqa
            }
    sort_keys = {
            # Sort by total time
            't': 'time',
            # Sort by avergae time
            'at': 'avg',
            # Sort by count
            'c': 'count'
            }

    def __init__(self, args):
        self.queries = []
        self.sort_attribute = args.sort
        self.reverse = args.reverse
        self.top = args.top is not None
        self.top_count = args.top
        self.json_input = args.json

    def process_query(self, query):
        """ Store or print the query based on sorting requirements."""
        # If we're not sorting, we can print the queries directly. If we are
        # sorting, save the query.
        if self.sort_attribute:
            self.queries.append(query)
        else:
            # If we have to print only N entries, exit after doing so
            if self.top:
                if self.top_count > 0:
                    self.top_count -= 1
                else:
                    sys.exit()
            print(query)

    def parse_slow_query_stats(self, line):
        """ Return stats for a single query from log file line."""
        match = logParser.regexes['single'].match(line)
        if match is not None:
            self.process_query(slowQuery(
                operation=match.group(1),
                stats=queryStats(int(match.group(2))),
                timeout=int(match.group(3)),
                is_cross_node=(match.group(4) is None)
                ))
            return
        match = logParser.regexes['multi'].match(line)
        if match is not None:
            self.process_query(slowQuery(
                operation=match.group(1),
                stats=queryStats(
                    count=int(match.group(2)),
                    avg=int(match.group(3)),
                    time=int(match.group(3))*int(match.group(2)),
                    mintime=int(match.group(4)),
                    maxtime=int(match.group(5))
                    ),
                timeout=match.group(6),
                is_cross_node=(match.group(7) is None)
                ))
            return
        print("Could not parse: " + line, file=sys.stderr)
        sys.exit(1)

    def get_json_objects(self, infile):
        """ Generate JSON objects without reading entire file into memory.
        Since Python's json doesn't support streaming, try accumulating line
        by line, and parsing.
        """
        prev = ""
        for line in infile:
            try:
                yield json.loads(prev + line)
            except:
                prev += line

    def parse_json(self, infile):
        """ Parse JSON-encoded input into query objects."""
        for obj in self.get_json_objects(infile):
            self.process_query(slowQuery(
                operation=obj["operation"],
                stats=queryStats(
                    count=obj["numTimesReported"],
                    time=obj["totalTime"],
                    avg=obj["totalTime"]/obj["numTimesReported"],
                    mintime=obj["minTime"],
                    maxtime=obj["maxTime"]
                    ),
                timeout=obj["timeout"],
                is_cross_node=obj["isCrossNode"]
                ))

    def parse_log(self, infile):
        """ Extract slow queries from the input (JSON or log)."""
        if self.json_input:
            self.parse_json(infile)
        else:
            # How many queries does the current log entry list?
            current_count = 0
            for line in infile:
                line = line.rstrip()
                if current_count > 0:
                    self.parse_slow_query_stats(line)
                    current_count -= 1
                else:
                    match = logParser.regexes['start'].match(line)
                    if match is None:
                        continue
                    current_count = int(match.group(1))

    @staticmethod
    def get_sort_attribute(key):
        """ Convert sort option to the corresponding attribute name."""
        return logParser.sort_keys[key]

    def sort_queries(self):
        """ Sort the queries by the previously-set key."""
        if self.sort_attribute:
            self.queries.sort(key=lambda x: getattr(x.stats,
                                                    self.sort_attribute),
                              reverse=self.reverse)
        return

    def end(self):
        """ Sort and print the appropriate number of entries."""
        # Sort and print
        if self.sort_attribute:
            self.sort_queries()
            if self.top:
                self.queries = self.queries[:self.top_count]
            for q in self.queries:
                print(q)


def main():
    """
    Provide a summary of the slow queries listed in Cassandra debug logs.
    Multiple log files can be provided, in which case the logs are combined.
    """
    arg_parser = argparse.ArgumentParser(description=textwrap.dedent(main.__doc__),
                                         formatter_class=argparse.RawTextHelpFormatter,
                                         epilog="""Sorting types:\n\tt\t- total time\n\tat\t- average time\n\tc\t- count""")  # noqa
    arg_parser.add_argument('-s', '--sort',
                            choices=logParser.sort_keys.values(),
                            default=False,
                            type=logParser.get_sort_attribute,
                            metavar='TYPE',
                            help='Sort the input by %(metavar)s')
    arg_parser.add_argument('-r', '--reverse',
                            action='store_true',
                            help='Reverse the sort order')
    arg_parser.add_argument('-t', '--top',
                            type=int,
                            metavar='N',
                            help='Print only the top %(metavar)s queries')
    arg_parser.add_argument('-j', '--json',
                            action='store_true',
                            help='Assume JSON-encoded input')
    arg_parser.add_argument('-o', '--output',
                            metavar='FILE',
                            type=argparse.FileType('a'),
                            help='Save output to %(metavar)s')
    arg_parser.add_argument('file', nargs='*',
                            metavar='FILE',
                            default='logs/debug.log',
                            type=argparse.FileType(),
                            help='Input files. Standrad input is -. Default: %(default)s')  # noqa
    args = arg_parser.parse_args()

    if args.output is not None:
        sys.stdout = args.output

    parser = logParser(args)

    if args.file == 'logs/debug.log':
        args.file = [argparse.FileType()(args.file)]
    for arg in args.file:
        print("Reading from " + arg.name)
        parser.parse_log(arg)
    parser.end()


if __name__ == "__main__":
    main()
