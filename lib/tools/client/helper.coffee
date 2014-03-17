if Handlebars {
  Handlebars.registerHelper 'mapWidget', (id, data) {
    return Router.path(routeName, params, {
      query: query,
      hash: hash
    });
  });
