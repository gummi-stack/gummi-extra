express = require 'express'
net = require 'net'
util = require 'util'

config = require('cson-config').load()
logs = require('./lib/logs') config['elasticsearch']

app = express()
app.use app.router
app.use express.errorHandler()

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

app.get '/logs/:app/:worker?', (req, res, next) ->
	options =
		app: req.params.app
		worker: req.params.worker

	logs options, (err, data) ->
		return next err if err
		res.end data.join '\n'


app.listen config['port']
