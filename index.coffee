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
ObjectId = mongoose.Schema.Types.ObjectId;
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
		
		socket.on "CLIENT_EVENT_DOWNLOAD_PROGRESS",onPlayerProgress
		socket.on "CLIENT_EVENT_DOWNLOAD_COMPLETE",onPlayerComplete
		socket.on "CLIENT_EVENT_DOWNLOAD_FAIL",onPlayerFail

		Player.findById(player.appId)
		.populate('segments')
		.exec (err,serverPlayer)->
			if(serverPlayer)
				syncData=syncPlayer(socket,player,serverPlayer);
				callback(syncData);
			else 
				socket.disconnect();




syncPlayer=(socket,player,serverPlayer)->
	playerSegmentID=player.segment
	serverSegmentID=_.pluck serverPlayer.segments,'_id'

	intersectionID=_.intersection playerSegmentID,serverSegmentID
	deleteSegmentsID=_.difference serverSegmentID,intersectionID
	downloadSegmentsID=_.difference serverSegmentID,intersectionID

	downloadSegments=_.filter serverPlayer.segments,(seg)->
		downloadSegmentsID.splice(downloadSegmentsID.indexOf(seg._id),1);

	serverPlayer.lastsync=Date.now();
	d={
		segments:
			"delete":deleteSegmentsID
			"load":downloadSegments
	}
	console.log d
	d





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