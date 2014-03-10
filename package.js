Package.describe({
  summary: "Custom client and server libs and tools"
});

Package.on_use(function (api, where) {
  if(api.export) { api.export('tools'); }
  
  common = ['client', 'server'];

  api.add_files('lib/tools/server/voting.coffee', 'server');
  
  api.use(['check', 'underscore', 'moment', 'coffeescript', 'collection-behaviours', 'underscore-string-latest', 'meteor', 'ejson', 'mongo-livedata', 'deps'], where);
  api.add_files('lib/tools/constants.coffee', common);
  api.add_files('lib/tools/tools.coffee', common);
  api.add_files('lib/tools/permissions.coffee', common);
  api.add_files('lib/tools/collections.coffee', common);
  
  api.add_files('lib/tools/server/policy.coffee', 'server');
  
  api.use(['bootstrap-growl', 'minimongo'], 'client');  
  api.add_files('lib/tools/client/typeahead.css', 'client');
  api.add_files('lib/tools/client/typeahead.js', 'client');
  api.add_files('lib/tools/client/bootstrap-datetimepicker.min.css', 'client');
  api.add_files('lib/tools/client/bootstrap-datetimepicker.js', 'client');
  api.add_files('lib/tools/client/tools.coffee', 'client');

});
