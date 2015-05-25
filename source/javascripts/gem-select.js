$(function() {
  var gemMap = {
    'SQL' : 'rom-sql',
    'MongoDB' : 'rom-mongo',
    'Event Store' : 'rom-event_store',
    'YAML' : 'rom-yaml',
    'CSV' : 'rom-csv'
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
