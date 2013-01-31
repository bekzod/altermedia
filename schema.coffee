mongoose= require 'mongoose'
Schema=mongoose.Schema;
ObjectId = mongoose.Schema.Types.ObjectId;


player=new Schema
	name:String
	segments:[{type:ObjectId,ref:segment}];


segmentStatus=[
	"NOT SYNCED"
	"SYNCED"
];

segment=new Schema
	# id:{type: String,index: {unique: true, dropDups: true}}
	status:{type:String,enum:segmentStatus,default:segmentStatus[0]}
	player:{type:ObjectId,ref:player}
	playDuration:Number
	totalDuration:Number
	startDate:Number
	startOffset:Number
	transtions:
		showTranstion:{type:ObjectId,ref:transtion}
		hideTranstion:{type:ObjectId,ref:transtion}
		showAnimDuration:Number
		hideAnimDuration:Number
	content:{type:ObjectId,ref:content}


transtion=new Schema
	name:String
	duration:Number



content=new Schema
	playerId:{type:ObjectId,ref:player}
	contentId:Number
	status:String
	# ,
	# _id:true
	# _v:false
	# toJSON:{getters:false, virtuals: true}


module.exports.player=player
module.exports.segment=segment
module.exports.content=content
# module.exports.content.virtual('id').get(function () {
#     return this._id.toString();
# });
