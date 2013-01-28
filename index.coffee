express= require 'express'
io= require 'socket.io'
_= require 'underscore'

app = express()

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



app.listen('8080')