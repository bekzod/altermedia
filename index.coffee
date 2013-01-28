express = require 'express'
path= require 'path'
mongoose = require('mongoose')
schemas = require('./schema.js')
_ = require 'underscore'

app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server);
server.listen(process.env.PORT or 3000)

# Database connection
db = mongoose.createConnection(process.env.DATABASE);       
db.on 'error',(err)->console.log err 
db.once 'open',->console.log "mangoose connected" 

# Database tables
Segment= db.model("Segment",schemas.segment)
Content= db.model("Content",schemas.content)

app.configure "production",->
	app.use(express.bodyParser());
	app.use(express.methodOverride());
	app.use(app.router);
	app.use(express.cookieParser());
	app.use(express.static(path.join(__dirname,"static")));
	# app.use(express.session({secret: 'supersecretkeygoeshere'}));
	# app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));


# Socket management

# socket.io configuration 
io.configure "production",->
	io.set 'log level',0
	io.set('transports', [
	    'websocket'
	  , 'flashsocket'
	  , 'htmlfile'
	]);


io.of('/admin').on 'connection',(socket)->


io.of('/player').on 'connection',(socket)->

	


# Content Management API
app.get '/',(req,res)->
	res.redirect('/index.html')

app.post '/',(req,res)->
	res.send(req.body);


app.listen('8080')