mongoose = require 'mongoose'
async    = require 'async'

Schema = mongoose.Schema
ObjectId = Schema.Types.ObjectId




exports = module.exports = (url)->
	connection = mongoose.createConnection url

	# 
	# Content
	# 
	content = new Schema
		size:Number
		playDuration:{type:Number,default:-1}
		owner:[String]
		type:{type: String, enum: ['application/x-shockwave-flash','image/jpeg','image/png','audio/mp3','video/mp4']}
		description:{
			name:String
		}
	connection.model "Content",content


	# 
	# Transaction
	# 
	transition = new Schema
		name:String
		duration:Number

	connection.model "Transition",transition 




	# 
	# Segment
	# 
	segment = new Schema
		# id:{type: String,index: {unique: true, dropDups: true}}
		playDuration:Number
		startDate:{ type:Number,default:Date.now() }
		endDate:Number
		startOffset:Number
		transitions:[
			tranistion:{type:ObjectId,ref:'Transtion'}
			showAt:Number
			playDuration:Number
		]
		content:{ type:ObjectId,ref:'Content' }
		,
			toJSON:{getters:true,virtual: true,_id:false}

	segment.pre 'save',(next)->
		@endDate   = @startDate + @playDuration
		@createdAt = {type: Date, expires:10}
		next()

	connection.model "Segment",segment 





	# 
	# Player
	# 
	player = new Schema
		name:String
		description:String
		lastSync:Date
		segments:[{type:ObjectId,ref:'Segment'}]
		contents:[{type:ObjectId,ref:'Content'}]


	player.post 'remove',(next)->
		Segment = connection.model('Segment')
		async.each @segments,(segid,cb)->
			Segment.findById(segid).remove cb
		,next

	player.methods.getSegmentsWhichStillPlaying = (cb)->
		self = @
		Segment = connection.model('Segment')

		Segment.find
			'_id': { $in:self.segments}
			'endDate': { $gte:Date.now()} 
			,cb


	player.methods.removeSegmentAndSave = (segmentId,cb)->
		self = @
		Segment = connection.model('Segment')

		@segments.remove(segmentId)
		async.parallel [
			(callback)->Segment.remove {_id:segmentId},callback 
			(callback)->self.save callback
		],cb


	player.methods.removeSegmentsAndSave = (segmentIds,cb)->
		self = @
		Segment = connection.model 'Segment' 
		
		async.parallel [
			(callback)->
				segmentIds.forEach (id)->
					self.segments.remove id
				self.save callback
			(callback)->Segment.remove {_id:{$in:segmentIds}},callback
		],cb


	player.methods.addSegmentAndSave = (prop,cb)->
		self = @
		Segment = connection.model 'Segment' 

		newseg = new Segment prop 
		@segments.push newseg

		async.parallel [
			(callback)->newseg.save callback
			(callback)->self.save callback
		],cb


	player.methods.addSegmentsAndSave = (props,cb)->
		self = @
		Segment = connection.model 'Segment'

		async.series [
			(callback)->
				async.map props,(prop,fn)->
					newseg = new Segment prop||{} 
					self.segments.push newseg._id
					newseg.save fn
				,callback
			,(callback)->self.save callback
		],cb



	player.methods.getContents = (cb)->
		self = @
		Content = connection.model 'Content'
		
		Content.find
			'_id': { $in:self.contents}
			,cb



	player.methods.addContentAndSave = (id,cb)->
		self = @
		Content = connection.model 'Content'

		Content.findById id,(err,res)->
			cb(error:err) if err || !res 
			self.update {$addToSet: {contents: id}},cb




	player.methods.removeContentAndSave = (id,cb)->
		@contents.remove(id)
		@save cb

	connection.model('Player',player)






