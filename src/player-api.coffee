
playerApi = exports  = module.exports


playerApi.get = (req,res)->
	playerid = req.params.playerid
	try
		check(playerid,'player id').len(24)
	catch e
		return res.send error:e

	Player.findById playerid,(err,player)->
		return res.send error:"player not found" if err||!player
		res.send player



playerApi.post = (req,res)->
	try
		check(req.body.name,'name').notEmpty();
		check(req.body.description,'description').notEmpty();
	catch e
		return res.send error:e

	player=new Player req.body
	player.save (err,player)->
		return res.send error:"internal error" if err
		res.send result:player._id