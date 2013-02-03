mongoose= require 'mongoose'
Schema=mongoose.Schema;
ObjectId = mongoose.Schema.Types.ObjectId;

exports=module.exports

exports.content=new Schema
	contentId:Number
	name:String
	status:String
	description:String
	# ,
	# _id:true
	# _v:false
	# toJSON:{getters:false, virtualpss: true}

exports.transtion=new Schema
	name:String
	duration:Number


exports.segment=new Schema
	# id:{type: String,index: {unique: true, dropDups: true}}
	playDuration:Number
	totalDuration:Number
	startDate:Date
	startOffset:Number
	transtions:
		showTranstion:{type:ObjectId,ref:exports.transtion}
		hideTranstion:{type:ObjectId,ref:exports.transtion}
		showAnimDuration:Number
		hideAnimDuration:Number
	content:{type:ObjectId,ref:exports.content}

exports.player=new Schema
	name:String
	description:String
	segments:[{type:ObjectId,ref:exports.segment}]
	content:[{type:ObjectId,ref:exports.content}]





# module.exports.content.virtual('id').get(function () {
#     return this._id.toString();
# });
