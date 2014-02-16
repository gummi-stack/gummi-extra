express = require 'express'
net = require 'net'

app = express()

app.get '/tail/:app/:worker?', (req, res) ->
	app = req.params.app
	worker = req.params.worker
	client = new net.Socket()

	client.connect 4444, '192.168.13.6', ->
		if app
			filter = filter: gummi_app: app
			filter.filter.gummi_worker = worker if worker
			client.write JSON.stringify filter

	client.on 'data', (data) ->
		res.write data

	client.on 'error', (err) ->
		console.log err

app.listen 8080
