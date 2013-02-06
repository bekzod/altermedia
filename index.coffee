express = require 'express'
path= require 'path'
async= require 'async'
mongoose = require('mongoose')
_ = require 'underscore'

app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server);
server.listen(process.env.PORT or 3000)


# 
# Database connection
#
db = mongoose.createConnection(process.env.DATABASE)       
sc = require('./schema.js')(mongoose.Schema,db,async)

db.on 'error',(err)->console.log err 
db.once 'open',->
	createDummyData();
	console.log "mangoose connected" 

# 
# Database tables
# 
Transition = sc.Transition
Segment    = sc.Segment
Content    = sc.Content
Player     = sc.Player


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
	socket.on "CLIENT_EVENT_HANDSHAKE",(handShakeData,callback)->
		
		socket.on "CLIENT_EVENT_DOWNLOAD_PROGRESS",onPlayerProgress
		socket.on "CLIENT_EVENT_DOWNLOAD_COMPLETE",onPlayerComplete
		socket.on "CLIENT_EVENT_DOWNLOAD_FAIL",onPlayerFail

		Player.findById handShakeData.id,(err,res)->
			if(!err&&res)
				socket.player=res
				res.removeSegmentAndSave("5112927728be6f26f1000001");
				# console.log res.save();
				# res.save();
				syncPlayer(handShakeData,res,callback);
			else 
				socket.disconnect();





syncPlayer=(remotePlayer,serverPlayer,cb)->
	serverPlayer.getSegmentsWhichStillPlaying (err,res)->
		return cb&&cb(err) if err

		playerSegmentID=remotePlayer.resources.segments
		serverSegmentID=_.map res,(seg)-> seg._id.toString();

		intersectionID=_.intersection playerSegmentID,serverSegmentID
		deleteSegmentsID=_.difference serverSegmentID,intersectionID
		downloadSegmentsID=_.difference serverSegmentID,intersectionID
		
		load=new Array(downloadSegmentsID.length)

		for seg in res
			if _.contains(downloadSegmentsID,seg._id)
				leanSeg=_.omit(seg.toJSON(),['_id','__v','endDate'])
				load[load.length]=leanSeg;
			else if downloadSegmentsID.length is 0
				return

		cb&&cb {segments:{"delete":deleteSegmentsID,"load":load}}




findPlayerSocketById=(playerId)->
	playerSockets=io.of('/player').clients()
	_.find playerSockets,(socks)->socks.player?.id is playerId







		



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