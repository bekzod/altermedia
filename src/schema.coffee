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
		hash:String
		owner:[String]
		duration:{type:Number,default:-1}
		type:{type: String, enum: ['application/x-shockwave-flash','image/jpeg','image/png','audio/mp3','video/mp4']}
		description:{
			name:String
		}
		,
			toJSON:{getters:true,virtual:true,_id:false,__v:false}


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
			id:{type:ObjectId,ref:'Transtion'}
			startDate:Number
			playDuration:Number
		]
		content:{ type:ObjectId,ref:'Content' }
		,
		 toJSON:{getters:true,virtual: true}

	segment.pre 'save',(next)->
		@endDate   = @startDate + @playDuration
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
			_id: { $in:self.segments}
			endDate: { $gte:Date.now()}
			,'-__v' 
			,cb

		Segment.remove 
			endDate: { $lte:Date.now()}
			,(err,res)->
				console.log err,res


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

		return cb(error:"content is not on player") if @contents.indexOf(prop.content)==-1

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






