mongoose= require 'mongoose'
Schema=mongoose.Schema;
ObjectId = mongoose.Schema.Types.ObjectId;

exports=module.exports

exports.content=new Schema
	contentId:Number
	name:String
	status:String
	description:String
	,
	# _id:true
	_v:false
	# toJSON:{getters:false, virtualpss: true}

exports.transtion=new Schema
	name:String
	duration:Number


exports.segment=new Schema
	# id:{type: String,index: {unique: true, dropDups: true}}
	playDuration:Number
	totalDuration:Number
	startDate:Number
	startOffset:Number
	transtions:
		showTranstion:{type:ObjectId,ref:'Transtion'}
		hideTranstion:{type:ObjectId,ref:'Transtion'}
		showAnimDuration:Number
		hideAnimDuration:Number
	
	content:{type:ObjectId,ref:'Content'}
	,
	_v:false

exports.segment.set('toObject', { getters: true });

exports.player=new Schema
	name:String
	description:String
	lastSync:Date
	segments:[{type:ObjectId,ref:'Segment'}]
	content:[{type:ObjectId,ref:'Content'}]





# module.exports.content.virtual('id').get(function () {
#     return this._id.toString();
# });
