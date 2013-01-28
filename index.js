// Generated by CoffeeScript 1.4.0
(function() {
  var app, express, io;

  express = require('express');

  io = require('socket.io');

  app = express();

  app.configure(function() {
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(app.router);
    return app.use(express.cookieParser());
  });

  app.get('/', function(req, res) {
    return res.send('hi there');
  });

  app.listen('8080');

}).call(this);
