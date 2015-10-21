Package.describe({
  name: 'svub:tools',
  version: '1.0.0',
  summary: "Custom client and server libs and tools"
});

Package.onUse(function (api, where) {
  api.versionsFrom('1.2.0.2');

  common = ['client', 'server'];

  api.use(['check', 'underscore', 'coffeescript', 'meteor', 'templating', 'ejson', 'mongo-livedata', 'deps'], common);
  //api.use(['momentjs:moment', 'jbrousseau:meteor-collection-behaviours', 'wizonesolutions:underscore-string'], common);
  api.use(['matb33:collection-hooks', 'momentjs:moment', 'sewdn:collection-behaviours', 'underscorestring:underscore.string'], common);
  api.add_files('lib/underscorestring-export.js', common); // make _s available
  if(api.export) { api.export('_s'); }
  api.add_files('lib/constants.coffee', common);
  api.add_files('lib/md5.js', common);
  api.add_files('lib/moment-extensions.coffee', common);
  api.add_files('lib/underscore.string-extensions.coffee', common);
  api.add_files('lib/tools.coffee', common);
  //api.add_files('lib/tools/permissions.coffee', common);
  api.add_files('lib/behaviours.coffee', common);
  api.add_files('lib/collection-extensions.coffee', common);
  api.add_files('lib/debugging-tools.coffee', common);
  //api.add_files('lib/tools/collections.coffee', common);

  api.add_files('server/geonames.coffee', 'server');

  // previously used: zimme:bootstrap-growl
  api.use(['duongthienduc:meteor-bootstrap-growl@1.0.0', 'minimongo', 'less'], 'client'); // bootstrap3-less
  //api.add_files('lib/tools/client/typeahead.0.9.3.css', 'client');
  //api.add_files('lib/tools/client/typeahead.0.9.3.js', 'client');
  //api.add_files('lib/tools/client/typeahead.0.10.2.css', 'client');
  //api.add_files('client/typeahead.0.10.2.js', 'client');
  api.add_files('client/typeahead.0.10.4.js', 'client');
  api.add_files('client/bootstrap-datetimepicker.css', 'client');
  api.add_files('client/bootstrap-datetimepicker.js', 'client');
  api.add_files('client/add-clear.js', 'client');
  api.add_files('client/fillText.less', 'client');
  api.add_files('client/responsive-var.coffee', 'client');
  api.add_files('client/tools.coffee', 'client');
  api.add_files('client/template-helpers.coffee', 'client');
  api.add_files('client/responsive-var.coffee', 'client');

  //api.add_files('lib/tools/client/map.widget.html', 'client');
  //api.add_files('lib/tools/client/map.widget.less', 'client');
  //api.add_files('lib/tools/client/map.widget.coffee', 'client');

  //if(api.export) { api.export('tools'); }
});
