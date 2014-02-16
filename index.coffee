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
	connected = no

	client.connect 4444, '192.168.13.6', ->
		connected = yes

		filter = filter: gummi_app: app
		filter.filter.gummi_worker = worker if worker
		client.write JSON.stringify filter

	client.on 'data', (data) ->
		res.write data

	client.on 'end', ->
		res.end()

	client.on 'error', (err) ->
		console.log err
		res.end()

	req.on 'close', ->
		client.end() if connected

	req.on 'error', (err) ->
		console.log err
		client.end() if connected

app.get '/logs/:app/:worker?', (req, res, next) ->
	options =
		app: req.params.app
		worker: req.params.worker

	logs options, (err, data) ->
		return next err if err
		res.end data.join '\n'


app.listen config['port']
util.log "Server listening on #{config.port}"
