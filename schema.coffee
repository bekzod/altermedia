mongoose = require 'mongoose'
async    = require 'async'

Schema = mongoose.Schema
ObjectId = Schema.Types.ObjectId




exports = module.exports = (url)->
	connection=mongoose.createConnection url

	# 
	# Content
	# 
	content = new Schema
		contentId:Number
		name:String
		status:String
		description:String

	connection.model "Content",content





	# 
	# Transaction
	# 
	transition=new Schema
		name:String
		duration:Number

	connection.model "Transition",transition 






	# 
	# Segment
	# 
	segment=new Schema
		# id:{type: String,index: {unique: true, dropDups: true}}
		totalDuration:Number
		playDuration:Number
		startDate:Number
		endDate:Number
		startOffset:Number
		transtions:
			showTranstion:{type:ObjectId,ref:'Transtion'}
			hideTranstion:{type:ObjectId,ref:'Transtion'}
			showAnimDuration:Number
			hideAnimDuration:Number
		content:{type:ObjectId,ref:'Content'}
		,
			toJSON:{getters:true,virtual: true,_id:false}

	connection.model "Segment",segment 







	# 
	# Player
	# 
	player=new Schema
		name:String
		description:String
		lastSync:Date
		segments:[{type:ObjectId,ref:'Segment',index:{unique:true,dropDups:true}}]
		content:[{type:ObjectId,ref:'Content',index:{unique:true,dropDups:true}}]
		,
			toJSON:{getters:true,virtual: true,_id:false}


	player.methods.getSegmentsWhichStillPlaying=(cb)->
		self=@
		Segment=connection.model('Segment')

		Segment.find
			'_id': { $in:self.segments}
			'endDate': { $gte:Date.now()} 
			,cb


	player.methods.removeSegmentAndSave=(segmentId,cb)->
		self = @
		Segment=connection.model('Segment')

		@segments.remove(segmentId)
		async.series [
			(callback)->Segment.remove {_id:segmentId},callback 
			(callback)->self.save callback
		],cb


	player.methods.removeSegmentsAndSave=(segmentIds,cb)->
		self = @
		Segment=connection.model 'Segment' 
		
		async.series [
			(callback)->
				segmentIds.forEach (id)->
					self.segments.remove id
				self.save callback
			(callback)->Segment.remove {_id:{$in:segmentIds}},callback
		],cb


	player.methods.addSegmentAndSave=(prop,cb)->
		self = @
		Segment=connection.model 'Segment' 

		newseg=new Segment prop 
		@segments.push newseg

		async.series [
			(callback)->newseg.save callback
			(callback)->self.save callback
		],(err,res)->
			cb(err,res)


	player.methods.addSegmentsAndSave=(props,cb)->
		self=@
		Segment=connection.model('Segment')

		async.series [
			(callback)->
				async.map props,(prop,fn)->
					newseg=new Segment prop||{} 
					self.segments.push newseg._id
					newseg.save fn
				,callback
			,(callback)->self.save callback
		],cb

	connection.model('Player',player)






