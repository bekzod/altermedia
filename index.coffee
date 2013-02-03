express = require 'express'
path= require 'path'
mongoose = require('mongoose')
schemas = require('./schema.js')
_ = require 'underscore'

app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server);
server.listen(process.env.PORT or 3000)



# 
# Database connection
# 
mongoose.set('debug', true)
db = mongoose.createConnection(process.env.DATABASE);       
db.on 'error',(err)->console.log err 
db.once 'open',->
	createDummyData();
	console.log "mangoose connected" 

# 
# Database tables
# 
Transition= db.model("Transition",schemas.transtion)
Segment= db.model("Segment",schemas.segment)
Content= db.model("Content",schemas.content)
Player= db.model("Player",schemas.player)


# 
# App config
# 
app.configure ->
	app.use app.router 
	app.use express.bodyParser()
	app.use express.methodOverride()

app.configure "production",->
	app.use express.cookieParser()
	app.use(express.static(path.join(__dirname,"static")));
	# app.use(express.session({secret: 'supersecretkeygoeshere'}));
	# app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));



# 
# socket.io configuration 
# 
io.configure "production",->
	io.set 'log level',0
	io.set('transports', [
		'websocket'
		'flashsocket'
		'htmlfile'
	]);



io.of('/admin').on 'connection',(socket)->


io.of('/player').on 'connection',(socket)->
	socket.on "CLIENT_EVENT_HANDSHAKE",(player,callback)->
		
		# player.on('disconnect',onDisconnectPlayer);
		socket.on "CLIENT_EVENT_DOWNLOAD_PROGRESS",onPlayerProgress
		socket.on "CLIENT_EVENT_DOWNLOAD_COMPLETE",onPlayerComplete
		socket.on "CLIENT_EVENT_DOWNLOAD_FAIL",onPlayerFail


		Player.findOne({_id:"510ec583a6bedff557000002"})
		# .populate('segments')
		.exec (err,serverPlayer)->
			if(serverPlayer)
				syncPlayer(socket,player,serverPlayer);
				callback(player);
			else 
				socket.disconnect();




syncPlayer=(socket,player,serverPlayer)->
	intersection=_.intersection player.segments,serverPlayer.segments
	deleteSegments=_.difference player.segments,intersection
	downloadSegments=_.difference serverPlayer.segments,intersection






onPlayerProgress=(data)->
onPlayerComplete=(data)->
onPlayerFail=(data)->




createDummyData=()->
	# 
	# Dummy database data
	# 

	# seg=new Segment 
	# 	playDuration:10*1000
	# 	totalDuration:30*1000
	# 	startDate:Date.now()+60*60*1000
	# 	startOffset:0
	# 	transtions:null
	# 	content:'510eb80c443769ca4d000001'
	# seg.save()


	# p=new Player
	# 	name:"firstplayer"
	# 	description:"firstplayer"
	# 	segments:[seg]

	# p.save();



app.get '/',(req,res)->
	res.redirect('/index.html')


# Segment Management API
app.get '/segment/:playerid',(req,res)->
	playerid = req.params.playerid
	res.send(req.params.playerid)

app.post '/segment',(req,res)->
	res.send(req.body);


app.listen('8080')