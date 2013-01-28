express= require 'express'
_= require 'underscore'
mongoose= require('mongoose')

schemas= require('./schema.js')


app= express()
server = require('http').createServer(app)
io = require('socket.io').listen(server);
server.listen(process.env.PORT or 3000)

# local 'mongodb://localhost:27017/local'
# server 'mongodb://nodejitsu:fb813f44c2434b9323749f86067f475c@alex.mongohq.com:10016/nodejitsudb9526573754'

db = mongoose.createConnection(process.env.DATABASE);       
db.on('error',(err)->console.log err)
db.once('open',->console.log "mangoose connected")

Segment= db.model("Segment",schemas.segment)
Content= db.model("Content",schemas.content)

app.configure ->
	app.use(express.bodyParser());
	app.use(express.methodOverride());
	app.use(app.router);
	app.use(express.cookieParser());
	# app.use(express.session({secret: 'supersecretkeygoeshere'}));
	# app.use(express.static(path.join(__dirname,"static")));
	# app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));



app.get '/',(req,res)->
	res.send('hi there')


app.post '/',(req,res)->
	res.send(req.body);


app.listen('8080')