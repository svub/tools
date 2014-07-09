Package.describe({
  summary: "Custom client and server libs and tools"
});

Package.on_use(function (api, where) {
  if(api.export) { api.export('tools'); }
  
  common = ['client', 'server'];

  api.use(['check', 'underscore', 'moment', 'coffeescript', 'collection-behaviours', 'underscore-string-latest', 'meteor', 'templating', 'ejson', 'mongo-livedata', 'deps'], common);
  api.add_files('lib/constants.coffee', common);
  api.add_files('lib/tools.coffee', common);
  //api.add_files('lib/tools/permissions.coffee', common);
  api.add_files('lib/behaviours.coffee', common);
  api.add_files('lib/collection-extensions.coffee', common);
  //api.add_files('lib/tools/collections.coffee', common);
  
  //api.add_files('lib/tools/server/policy.coffee', 'server');
  
  api.use(['bootstrap-growl', 'minimongo', 'less', 'bootstrap3-less'], 'client');  
  //api.add_files('lib/tools/client/typeahead.0.9.3.css', 'client');
  //api.add_files('lib/tools/client/typeahead.0.9.3.js', 'client');
  //api.add_files('lib/tools/client/typeahead.0.10.2.css', 'client');
  api.add_files('client/typeahead.0.10.2.js', 'client');
  api.add_files('client/bootstrap-datetimepicker.min.css', 'client');
  api.add_files('client/bootstrap-datetimepicker.js', 'client');
  api.add_files('client/tools.coffee', 'client');

  //api.add_files('lib/tools/client/map.widget.html', 'client');
  //api.add_files('lib/tools/client/map.widget.less', 'client');
  //api.add_files('lib/tools/client/map.widget.coffee', 'client');

});
