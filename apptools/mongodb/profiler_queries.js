// Number of request of each type (query, insert, etc) :
db.system.profile.aggregate({'$group': {'_id': '$op', 'count': {'$sum': 1}}});

// Operations sorted by descending execution time (slowest operations first)
db.system.profile.find({}, {'_id': 0, 'millis': 1}).sort({'millis': -1});

// Operations sorted by ascending execution time (fastest operations first)
db.system.profile.find({}, {'_id': 0, 'millis': 1}).sort({'millis': 1});

// Average of execution time
db.system.profile.aggregate({'$group': {'_id': null, 'avg': {'$avg': '$millis'}}});

// Slowest operations
db.system.profile.find({}, {'_id': 0, 'updateobj': 0}).sort({'millis': -1});

// Comparaison of the execution time and the time spent waiting a lock to be free
db.system.profile.aggregate([
  {'$project': {
    '_id': 0, 
    'executionTimeInMs': '$millis', 
    'waitingForLockInMs': {'$divide': [{'$add': ['$lockStats.timeAcquiringMicros.r', '$lockStats.timeAcquiringMicros.w']}, 1000]}}},
  {'$sort': {'executionTimeInMs': -1}}
]);

// Number of operations that last more than 100 ms, without the lock waiting time
db.system.profile.aggregate([
  {'$project': {'realComputingTimeMs': {'$subtract': ['$millis', {'$divide': [{'$add': ['$lockStats.timeAcquiringMicros.r', '$lockStats.timeAcquiringMicros.w']}, 1000]}]}}},
  {'$match': {'realComputingTimeMs': {'$gte': 100}}},
  {'$group': {'_id': '', 'count': {'$sum': 1}}}
]);

// _id of operations that last more than 100 ms, without the lock waiting time
db.system.profile.aggregate([
  {'$project': {
    '_id': 1,
    'totalTimeMs': '$millis',
    'realComputingTimeMs': {'$subtract': ['$millis', {'$divide': [{'$add': ['$lockStats.timeAcquiringMicros.r', '$lockStats.timeAcquiringMicros.w']}, 1000]}]}
  }},
  {'$match': {'realComputingTimeMs': {'$gte': 100}}},
  {'$sort': {'realComputingTimeMs': -1}}
]);

// % of time waiting the locks
db.system.profile.aggregate([
  {'$project': {
    '_id': 1, 
    'timePercentWaitingLocksMs': {'$divide': [{'$multiply': [{'$divide': [{'$add': ['$lockStats.timeAcquiringMicros.r', '$lockStats.timeAcquiringMicros.w']}, 1000]}, 100]}, '$millis']}
  }},
  {'$group': {'_id': '', 'avgTimePercentWaitingLocksMs': {'$avg': '$timePercentWaitingLocksMs'}}}
]);

// Slowest queries (without lock waiting)
db.system.profile.aggregate([
  {'$match': {'op': 'query'}},
  {'$project': {
    '_id': 1,
    'totalTimeMs': '$millis',
    'realComputingTimeMs': {'$subtract': ['$millis', {'$divide': [{'$add': ['$lockStats.timeAcquiringMicros.r', '$lockStats.timeAcquiringMicros.w']}, 1000]}]}
  }},
  {'$match': {'realComputingTimeMs': {'$gte': 100}}},
  {'$sort': {'realComputingTimeMs': -1}}
]);

// Print the amount of documents read with the amount of documents effectively returned for a query (useful to identify that may need an index)
db.system.profile.find({'op': 'query'},{'_id': 0, 'query': 1, 'nreturned': 1, 'nscanned': 1});

// Get the number of slow queries by day
db.system.profile.aggregate([
  {'$project': {'_id': 0, 'date': {'$dateToString': {'format': '%d/%m/%Y', 'date': '$ts'}}}},
  {'$group': {'_id': '$date', 'count': {'$sum': 1}}}
]);

// Get the indexes size for a collection
print(((db.getCollection('<collection_name>').totalIndexSize()/1024)/1024)/1024 + ' GB');

// Print a complete report of data and index size
function getCollectionSize(db) {
  var collections = db.getCollectionNames();
  var totalIndexSize = 0;
  var totalDataSize  = 0;
  collections.forEach(function (collectionName) {
      var collection = db.getCollection(collectionName);
      var indexSize  = collection.totalIndexSize();
      var dataSize   = collection.dataSize();
      totalIndexSize += indexSize;
      totalDataSize  += dataSize;
      print(collectionName + ' : data = ' + ((dataSize/1024)/1024)/1024 + ' GB' + ' - index = ' + ((indexSize/1024)/1024)/1024 + ' GB');
  });
  print('Total for ' + db + ' database: data = ' + ((totalDataSize/1024)/1024)/1024 + ' GB' + ' - index = ' + ((totalIndexSize/1024)/1024)/1024 + ' GB');
  return {'totalDataSize': totalDataSize, 'totalIndexSize': totalIndexSize};
}

function getSize() {
  var dbs = db.getMongo().getDBNames();
  var totalIndexSize = 0;
  var totalDataSize  = 0;
  print ('----------');
  dbs.forEach(function (dbName) {
    print('Database : ' + dbName);
    var size = getCollectionSize(db.getMongo().getDB(dbName));
    totalDataSize  += size.totalDataSize;
    totalIndexSize += size.totalIndexSize;
    print ('----------');
  });
  print('Total for all database: data = ' + ((totalDataSize/1024)/1024)/1024 + ' GB' + ' - index = ' + ((totalIndexSize/1024)/1024)/1024 + ' GB');
}
