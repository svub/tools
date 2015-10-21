_.extend _s,
  vsprintf: (string, args) -> _s.sprintf.apply _s, _.flatten arguments
