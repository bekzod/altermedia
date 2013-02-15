express =  require 'express'
path=      require 'path'
async= 	   require 'async'
_ =        require 'underscore'

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
	io.set 'transports',[
		'websocket'
		'flashsocket'
		'htmlfile'
	]



io.of('/admin').on 'connection',(socket)->


io.of('/player').on 'connection',(socket)->
	socket.on "CLIENT_EVENT_HANDSHAKE",(handShakeData,callback)->
		# socket.on "CLIENT_EVENT_DOWNLOAD_PROGRESS",onPlayerProgresms
		# socket.on "CLIENT_EVENT_DOWNLOAD_COMPLETE",onPlayerComplete
		# socket.on "CLIENT_EVENT_DOWNLOAD_FAIL",onPlayerFail
		Player.findById handShakeData.id,(err,res)->
			if(!err&&res)
				syncPlayer(handShakeData,res,callback)
			else 
				socket.disconnect()




syncPlayer=(remotePlayer,serverPlayer,cb)->
	serverPlayer.getSegmentsWhichStillPlaying (err,res)->
		return cb&&cb(err) if err

		serverSegmentID=_.map res,(seg)-> seg._id
		playerSegmentID=remotePlayer.resources.segments
 
		syncSegment=syncer.sync serverSegmentID,playerSegmentID		
		addSegment=syncSegment.add.map (id)-> _.find res,(seg)->seg._id is id

		serverContentID=_.map serverPlayer.contents,(el)-> el.toString()
		playerContentID=remotePlayer.resources.content.concat remotePlayer.resources.downloads

		syncContent=syncer.sync serverContentID,playerContentID
		
		cb&&cb {
			content:{"remove":syncContent.remove,"add":syncContent.add}
			segments:{"remove":syncSegment.remove,"add":addSegment}
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

createDummyData()


app.get '/',(req,res)->
	res.redirect('/index.html')


# Segment Management API
app.get '/segment/:playerid',(req,res)->
	playerid = req.params.playerid
	res.send(req.params.playerid)

app.post '/segment',(req,res)->
	res.send(req.body);


app.listen('8080')