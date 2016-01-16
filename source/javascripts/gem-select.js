$(function() {
  var gemMap = {
    'CSV' : 'rom-csv',
    'Cassandra' : 'rom-cassandra',
    'CouchDB' : 'rom-couchdb',
    'Event Store' : 'rom-event_store',
    'Git' : 'rom-git',
    'HTTP' : 'rom-http',
    'InfluxDB' : 'rom-influxdb',
    'JSON' : 'rom-json',
    'Kafka' : 'rom-kafka',
    'MongoDB' : 'rom-mongo',
    'Neo4j' : 'rom-neo4j',
    'Redis' : 'rom-redis',
    'RethinkDB' : 'rom-rethinkdb',
    'SQL' : 'rom-sql',
    'YAML' : 'rom-yaml'
  };

  var $code = $('#gem-install-code');
  var $label = $('#db-select .value');

  $('#db-dropdown a').on('click', function(e) {
    var name = $(e.target).text();
    $label.text(name);
    $code.text("$ gem install "+gemMap[name]);
    e.preventDefault();
  });
});
