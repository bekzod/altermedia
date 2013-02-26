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
Content    = con.model 'Content'
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
			if(!err&&res)
				socket.on "client_event_download_progress",eventHandler.onPlayerProgress
				socket.on "client_event_download_complete",eventHandler.onPlayerComplete
				socket.on "client_event_download_fail",eventHandler.onPlayerFail
				syncPlayer(handShakeData,res,callback)
			else 
				socket.disconnect()






syncPlayer=(remotePlayer,serverPlayer,cb)->

	async.parallel [
		(callback)->
			serverPlayer.getSegmentToDate Date.now(),(err,res)->

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





findPlayerSocketById=(playerId)->
	playerSockets=io.of('/player').clients()
	_.find playerSockets,(socks)->
		socks.player&&socks.player.id is playerId






onPlayerProgress=(data)->

onPlayerComplete=(data)->

onPlayerFail=(data)->




createDummyData=()->
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
	# 	contents: ['510eb80c443769ca4d000001','510eb84f7e4ae4454e000001','510eb8630d702c8c4e000001'] 
	# p.save()

	# Player.findById '511ebd6c04be79cf07000001',(err,player)->
		# # player.contents=[]
		# cont=new Content({
		# 	type:'VIDEO'
		# 	length:1000*60
		# 	description:{
		# 		name:'cool video'

		# 	}
		# })
		# cont.save()
		# player.contents.push(cont)
		# player.save();

createDummyData()


app.get '/',(req,res)->
	res.redirect('/index.html')





app.get 'contentinfo/:id',(req,res)->
	contentid=req.params.id;
	Content.findById contentid,(err,cont)->
		res.send(cont.toJSON());




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
			res.send result:result[0][0]









app.listen('8080')