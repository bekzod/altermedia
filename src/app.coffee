express =  require 'express'
path=      require 'path'
async= 	   require 'async'
_ =        require 'underscore'
check =    require('validator').check
sanitize = require('validator').sanitize

syncer= require './syncer'


app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
server.listen(process.env.PORT or 3000)


# 
# Database connection
#
con = require('./schema.js')(process.env.DATABASE)

# 
# Database tables
# 
Transition = con.model 'Transition'
Segment    = con.model 'Segment'
Player     = con.model 'Player'


# 
# App config
# 
app.configure ->
	app.use express.methodOverride() 
	app.use express.bodyParser() 
	app.use app.router 
	# app.use express.cookieParser()
	app.use(express.static(path.join(__dirname,"static")));
	# app.use(express.session({secret: 'supersecretkeygoeshere'}));
	# app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));




# 
# socket.io configuration 
# 
io.configure "production",->
	io.set 'log level',0
	io.set 'transports',[
		'websocket'
		'flashsocket'
		'htmlfile'
	]


eventHandler={}
eventHandler.onPlayerProgress=(e)->
	# console.log e


eventHandler.onPlayerComplete=(e)->
	# console.log e,"dawdaw"


eventHandler.onPlayerFail=(e)->
	# console.log e,"dawdaw"




io.of('/admin').on 'connection',(socket)->


io.of('/player').on 'connection',(socket)->

	socket.on "client_event_handshake",(handShakeData,callback)->
		Player.findById handShakeData.id,(err,res)->
			if !err&&res
				socket.on "CLIENT_EVENT_DOWNLOAD_PROGRESS",eventHandler.onPlayerProgress
				socket.on "CLIENT_EVENT_DOWNLOAD_COMPLETE",eventHandler.onPlayerComplete
				socket.on "CLIENT_EVENT_DOWNLOAD_FAIL",eventHandler.onPlayerFail
				syncPlayer(handShakeData,res,callback)
			else 
				socket.disconnect()




syncPlayer = (remotePlayer,serverPlayer,cb)->
	async.parallel [
		(callback)->
			serverPlayer.getSegmentsWhichStillPlaying (err,res)->

				serverSegmentID=_.map res,(seg)->String(seg._id)
				playerSegmentID=remotePlayer.resources.segments
		 
				syncSegment=syncer.sync serverSegmentID,playerSegmentID		
				addSegment=syncSegment.add.map (id)-> _.find res,(seg)->seg._id is id

				callback null,{"remove":syncSegment.remove,"add":addSegment}

		(callback)->
			serverContentID=_.map serverPlayer.contents,(el)-> String(el)
			playerContentID=remotePlayer.resources.contents 

			syncContent=syncer.sync serverContentID,playerContentID
			Content.find {'_id': { $in:syncContent.add}},(err,res)->
				callback err,{"remove":syncContent.remove,"add":res}

		],(err,res)->
			cb {
				segments:res[0]
				content:res[1]
			}





findPlayerSocketById = (playerId)->
	playerSockets = io.of('/player').clients()
	_.find playerSockets,(socks)->
		socks.player&&socks.player.id is playerId










# Player Management API

# DELETE player
app.delete '/player/:playerid',(req,res)->
	playerid = req.params.playerid
	try
		check(playerid,'player id').len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"error occurred" if err
		return res.send result:0 if !player
		player.remove (err,result)->
			return res.send error:"error occurred" if err
			res.send {result:result}


# GET ALL
app.get '/player/',(req,res)->
	Player.find (err,players)->
		return res.send error:"error" if err
		res.send {result:players}


# GET ONE
app.get '/player/:playerid',(req,res)->
	playerid = req.params.playerid
	try
		check(playerid,'player id').len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		res.send player


# ADD PLAYER
app.post '/player',(req,res)->
	try
		check(req.body.name,'name').notEmpty();
		check(req.body.description,'description').notEmpty();
	catch e
		return res.send error:e

	player=new Player req.body
	player.save (err,player)->
		return res.send error:"internal error" if err
		res.send result:player._id





# Segment Management API


# SEGMENT GET ALL
app.get '/player/segment/:playerid',(req,res)->
	playerid = req.params.playerid
	try
		check(playerid,'player id').len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.getSegmentsWhichStillPlaying (err,segments)->
			return res.send error:"internal error" if err
			res.send result:segments




# SEGMENT ADD
app.post '/player/segment/:playerid',(req,res)->
	playerid = req.params.playerid

	try
		check(playerid,'player id').len(24)
		check(req.body.content,"content").notEmpty().len(24)
		check(req.body.playDuration,'playDuration').isInt()
		check(req.body.startDate,'playDuration').isAfter()
		check(req.body.startOffset,'startOffset').isInt()

		if check(req.body.transitions,'transitions').isArray()
	    	for item in req.body.transitions
	    		check(item.tranistion,'transition item').notEmpty().len(24)
	    		check(item.showAt,'transition item').isInt()
	    		check(item.playDuration,'transition item').isInt()	
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.addSegmentAndSave req.body,(err,result)->
			return res.send error:"internal error" if err
			playerSocket = findPlayerSocketById playerid
			segmentData  = result[0][0]

			playerSocket.emit 'SERVER_EVENT_ADD_SEGMENT',{segments:[segmentData]}
			res.send result:segmentData


# SEGMENT DELETE
app.delete '/player/segment/:playerid/:segmentid',(req,res)->
	playerid = req.params.playerid
	segmentid = req.params.segmentid

	try
		check(playerid,'player id').len(24)
		check(segmentid,'segment id').len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.removeSegmentAndSave segmentid,(err,result)->
			return res.send error:"internal error" if err
			playerSocket = findPlayerSocketById playerid
			
			res.send result:result[0]




app.listen('8080')