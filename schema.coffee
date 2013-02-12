mongoose = require 'mongoose'
async =    require 'async'

Schema = mongoose.Schema
ObjectId = Schema.Types.ObjectId

# 
# Content
# 
content = new Schema
	contentId:Number
	name:String
	status:String
	description:String

mongoose.model "Content",content


# 
# Transaction
# 
transition=new Schema
	name:String
	duration:Number

mongoose.model "Transition",transition 


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

mongoose.model "Segment",transition 


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
	Segment=mongoose.model('Segment')

	Segment.find
		'_id': { $in:self.segments}
		'endDate': { $gte:Date.now()} 
		,cb


player.methods.removeSegmentAndSave=(segmentId,cb)->
	self = @
	Segment=mongoose.model('Segment')

	@segments.remove(segmentId)
	@markModified('segments')

	async.series [
		(callback)->self.save callback
		(callback)->Segment.find({_id:segmentId}).remove callback 
	],cb


player.methods.removeSegmentsAndSave=(segmentIds,cb)=>
	self=@
	Segment=mongoose.model('Segment')

	@segments.remove(segmentId)
	
	db.model('Segment').remove {_id:{$in:segmentId}},(err,res)-> 
		self.save (err)->cb&&cb err,res


player.methods.addSegmentAndSave=(prop,cb)->
	self=@
	Segment=mongoose.model('Segment')

	newseg=new Segment prop 
	@segments.push newseg._id

	async.series [
		(callback)->newseg.save callback
		(callback)->self.save callback
	],(err,res)->
		console.log self.segments
		cb(err,res)


player.methods.addSegmentsAndSave=(props,cb)->
	self=@
	Segment=mongoose.model('Segment')

	async.map props,(prop,callback)->
		newseg=new Segment prop 
		self.segments.push newseg._id
		newseg.save callback
	,(err,res)->
		self.save ()->
			cb&&cb(err,res)

mongoose.model('Player',player)


module.exports=mongoose.createConnection process.env.DATABASE







