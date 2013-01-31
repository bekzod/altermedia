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


app.configure ->
	app.use app.router 
	app.use express.bodyParser()
	app.use express.methodOverride()


app.configure "production",->
	app.use express.cookieParser()
	app.use(express.static(path.join(__dirname,"static")));
	# app.use(express.session({secret: 'supersecretkeygoeshere'}));
	# app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));


# Socket management

# socket.io configuration 
io.configure "production",->
	io.set 'log level',3
	io.set('transports', [
	    'websocket'
	  , 'flashsocket'
	  , 'htmlfile'
	]);


io.of('/admin').on 'connection',(socket)->



io.of('/player').on 'connection',(player)->
	console.log "got someone"
	# player.on "CLIENT_EVENT_HANDSHAKE",(data)->
	# 	console.log "dwadawd"
	# 	console.log data
	player.emit "SERVER_EVENT_ADD_SEGMENT"

	# player.on "CLIENT_EVENT_DOWNLOAD_PROGRESS",onPlayerProgress
	# player.on "CLIENT_EVENT_DOWNLOAD_COMPLETE",onPlayerComplete
	# player.on "CLIENT_EVENT_DOWNLOAD_FAIL",onPlayerFail 
	# player.on('disconnect',onDisconnectPlayer);


onPlayerProgress=(data)->


onPlayerComplete=(data)->

onPlayerFail=(data)->


app.get '/',(req,res)->
	res.redirect('/index.html')


# Segment Management API
app.get '/segment/:playerid',(req,res)->
	playerid = req.params.playerid
	res.send(req.params.playerid)

app.post '/segment',(req,res)->
	res.send(req.body);


app.listen('8080')