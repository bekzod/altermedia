express = require 'express'
path= require 'path'
async= require 'async'
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
	socket.on "CLIENT_EVENT_HANDSHAKE",(handShakeData,callback)->
		
		socket.on "CLIENT_EVENT_DOWNLOAD_PROGRESS",onPlayerProgress
		socket.on "CLIENT_EVENT_DOWNLOAD_COMPLETE",onPlayerComplete
		socket.on "CLIENT_EVENT_DOWNLOAD_FAIL",onPlayerFail

		Player.findById handShakeData.id,(err,res)->
			if(!err)
				socket.player=res
				syncPlayer(socket,handShakeData,callback);
				addSegmentsToPlayer(handShakeData.id,[{}])
			else 
				socket.disconnect();





syncPlayer=(socket,player,cb)->
	now=Date.now()

	Segment.find
		'_id': { $in:socket.player.segments}
		'endDate': { $gte:now} 
		,(err,res)->
			return cb&&cb(err) if err

			playerSegmentID=player.resources.segments
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
			
			cb {segments:{"delete":deleteSegmentsID,"load":load}}




findPlayerSocketById=(playerId)->
	sockets=io.of('/player').clients()
	_.find sockets,(socks)->socks.player?.id is playerId


addSegmentsToPlayer=(playerid,segmentsData,cb)->
	async.parallel [
		(callback)->
			playerSocket=findPlayerSocketById(playerid);
			if playerSocket and playerSocket.player
				callback(null,playerSocket.player,playerSocket)
			else 
				Player.findById playerid,callback

		(callback)->
			async.map segmentsData,(segData,fn)->
				newseg=new Segment segData 
				leanSeg=_.omit newseg.toJSON(),['_id','__v','endDate']
				newseg.save (err)->fn(err,leanSeg)
			,callback

	],(err,res)->
		return cb&&cb(err) if err

		segmentModels=res[1]
		if _.isArray(res[0])
			playerModel=res[0][0]
			playerSocket=res[0][1]

			for seg in segmentModels
				playerModel.segments.push seg.id
			
			playerModel.save (err)->
				return cb&&cb(err) if err
				playerSocket.emit 'SERVER_EVENT_ADD_SEGMENT',segmentModels
			cb&&cb(null)
		else
			playerModel=res[0];
			playerModel.segments.$pushAll(segmentModels)
			playerModel.save (err)-> cb&&cb(err) if err



removeSegmentsFromPlayer=(playerid,segmentId,cb)->
	
	Segment.remove {"_id":segmentId},(err)->
		playerSocket=findPlayerSocketById(playerid);
		playerSocket.emit('SERVER_EVENT_DELETE_SEGMENT',{segment:{delete:[segmentId]}})


		

		



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