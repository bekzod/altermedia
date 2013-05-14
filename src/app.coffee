_        = require 'underscore'
path     = require 'path'
async    = require 'async'
express  = require 'express'
check    = require('validator').check
sanitize = require('validator').sanitize

syncer   = require './syncer'

app      = express()
server   = require('http').createServer(app)
io       = require('socket.io').listen(server)

server.listen process.env.PORT || 3000


allowCrossDomain = (req, res, next)->
	allowedHost = [
		'http://timeline.dev':true
	]
	if(true)
		res.header('Access-Control-Allow-Credentials', true);
		res.header('Access-Control-Allow-Origin', "*")
		res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
		res.header('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');
		next();
	else
		res.send(403, {auth: false});


#
# App config
#
app.configure ->
	app.use allowCrossDomain
	app.use express.methodOverride()
	app.use express.bodyParser()
	app.use app.router
	app.use express.static(path.join(__dirname,'../public'))



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

#
# Database connection
#
con = require('./schema')(process.env.DATABASE)

#
# Database tables
#
Segment    = con.model 'Segment'
Player     = con.model 'Player'
Content    = con.model 'Content'
User       = con.model 'User'



eventHandler={}
eventHandler.onPlayerProgress = (e)->
	console.log e


eventHandler.onPlayerComplete = (eventData,cb)->
	Content.findById eventData.id,'-owners -__v',cb




eventHandler.onPlayerFail=(e)->
	# console.log e,"dawdaw"




io.of('/admin').authorization (handshakeData,cb)->
	userId    = handshakeData.headers['user-id'];

	return cb null,false if !userId

	User.findById userId,(err,user)->
		if err||!user then return cb(null,false)
		handshakeData.user = user
		cb(null,true);



io.of('/player').authorization (handshakeData,cb)->
	appid    = handshakeData.headers['app-id']
	appsign  = handshakeData.headers['app-sign']

	return cb null,false if !appid || !appsign
	Player.findById appid,(err,player)->
		if err||!player then return cb(null,false);
		handshakeData.player = player
		cb(null,true);




io.of('/player').on 'connection',(socket)->
	socket.on "CLIENT_EVENT_HANDSHAKE",(handShakeData,callback)->
		socket.on "CLIENT_EVENT_DOWNLOAD_PROGRESS",eventHandler.onPlayerProgress
		socket.on "CLIENT_EVENT_DOWNLOAD_COMPLETE",eventHandler.onPlayerComplete
		socket.on "CLIENT_EVENT_DOWNLOAD_FAIL",eventHandler.onPlayerFail

		syncPlayer(handShakeData.resources,socket.handshake.player,callback)


syncPlayer = (remotePlayerData,serverPlayer,cb)->
	async.parallel [
		(callback)->
			serverPlayer.getSegmentsWhichStillPlaying (err,segments)->
				return callback(error:"internal error") if err||!segments

				serverSegmentsID = _.map segments,(seg)-> String(seg._id)
				playerSegmentsID = remotePlayerData.segments

				syncSegment = syncer.sync serverSegmentsID,playerSegmentsID
				delete syncSegment.same

				addSegments = _.filter segments,(seg)->
					_.contains syncSegment.add,seg.id

				callback null,{add:addSegments,remove:syncSegment.remove}

		(callback)->
			serverPlayer.getContents (err,contents)->
				return callback(error:"internal error") if err||!contents

				serverContentsID = _.map contents,(cont)-> String(cont._id)
				playerContentsID = remotePlayerData.contents

				syncContent = syncer.sync serverContentsID,playerContentsID
				delete syncContent.same

				callback null,syncContent
		],(err,res)->
			cb error:err,segments:res[0],contents:res[1]





findPlayerSocketById = (playerId)->
	playerSockets = io.of('/player').clients()
	console.log playerSockets,'playerSockets'
	_.find playerSockets,(socks)->
		socks.handshake.player.id is playerId


findAdminSocketById = (userId)->
	userSockets = io.of('/admin').clients()
	_.find userSockets,(socks)->
		socks.handshake.user.id is userId




app.get '/',(req,res)->
	res.redirect '/index.html'




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
	opts = {}
	opts.limit = req.query.limit || 30
	opts.skip  = req.query.skip  || 0
	opts.sort  = {}
	opts.sort[req.query.sort||'_id'] = parseInt(req.query.asc||-1)

	opts.fromDate = req.query.fromDate
	opts.toDate   = req.query.toDate||Date.now()+4*24*60*60*1000
	console.log req.query

	try
		check(playerid,'player id').len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.getSegments opts,(err,segments)->
			return res.send error:"internal error" if err
			res.send result:segments



app.put '/player/segment/:playerid/:segmentid',(req,res)->
	playerid  = req.params.playerid
	segmentid = req.params.segmentid

	delete req.body.id
	delete req.body._id

	try
		check(playerid,'player id').len(24)
		check(req.body.content,"content").notEmpty().len(24)
		check(req.body.playDuration,'playDuration').isInt()
		check(req.body.startDate+req.body.playDuration,'endDate').min(Date.now())
		check(req.body.startOffset,'startOffset').isInt()

		if check(req.body.transitions,'transitions').isArray()
	    	for item in req.body.transitions
	    		check(item.id,'transition item').notEmpty().len(24)
	    		check(item.startTime,'transition item').isInt()
	    		check(item.playDuration,'transition item').isInt()
	catch e
		return res.status(300).send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.removeSegmentAndSave segmentid,(err,result)->
			player.addSegmentAndSave req.body,(err,result)->
				return res.send err if err
				segmentData  = result[0][0]
				playerSocket = findPlayerSocketById playerid
				if playerSocket then playerSocket.emit 'SERVER_EVENT_DATA_CHANGE',{segments:{add:[segmentData],remove:[segmentid]}}
				res.send segmentData



# SEGMENT ADD
app.post '/player/segment/:playerid',(req,res)->
	playerid = req.params.playerid

	try
		check(playerid,'player id').len(24)
		check(req.body.content,"content").notEmpty().len(24)
		check(req.body.playDuration,'playDuration').isInt()
		check(req.body.startDate,'startDate').min(Date.now())
		check(req.body.startOffset,'startOffset').isInt()

		if check(req.body.transitions,'transitions').isArray()
	    	for item in req.body.transitions
	    		check(item.id,'transition item').notEmpty().len(24)
	    		check(item.startTime,'transition item').isInt()
	    		check(item.playDuration,'transition item').isInt()
	catch e
		return res.status(300).send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.addSegmentAndSave req.body,(err,result)->
			return res.send err if err
			segmentData  = result[0][0]
			playerSocket = findPlayerSocketById playerid
			if playerSocket then playerSocket.emit 'SERVER_EVENT_DATA_CHANGE',{segments:{add:[segmentData]}}
			res.send segmentData

# SEGMENT DELETE
app.delete '/player/segment/:playerid/:segmentid',(req,res)->
	playerid  = req.params.playerid
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
			if playerSocket then playerSocket.emit 'SERVER_EVENT_DATA_CHANGE',{segments:{remove:[segmentid]}}
			res.send result:result[0]



# Content Management API
app.get '/player/content/:playerid',(req,res)->
	playerid = req.params.playerid
	try
		check(playerid,'player id').len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.getContents (err,contents)->
			return res.send error:"internal error" if err
			res.send result:contents
app.post '/player/content/:playerid/:contentid',(req,res)->
	playerid  = req.params.playerid
	contentid = req.params.contentid

	try
		check( playerid,'player id' ).len(24)
		check( contentid,'content id' ).len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.addContentAndSave contentid,(err,content)->
			if err then return res.send error:"internal error"
			playerSocket = findPlayerSocketById playerid
			if playerSocket then playerSocket.emit 'SERVER_EVENT_DATA_CHANGE',{contents:{add:[contentid]}}
			res.send result:content



app.delete '/player/content/:playerid/:contentid',(req,res)->
	playerid  = req.params.playerid
	contentid = req.params.contentid
	try
		check( playerid,'player id' ).len(24)
		check( contentid,'content id' ).len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		player.removeContentAndSave contentid,(err,content)->
			return res.send error:"internal error" if err ||!content
			playerSocket = findPlayerSocketById playerid;
			if playerSocket then playerSocket.emit 'SERVER_EVENT_DATA_CHANGE',{contents:{remove:[contentid]}}
			res.send result:1


app.listen('8080')
