express = require 'express'
net = require 'net'
url = require 'url'
util = require 'util'

config = require('cson-config').load()

logstashUrl = url.parse config['logstash']
logs = require('./lib/logs') config['elasticsearch']

app = express()
app.use express.urlencoded()
app.use express.query()
app.use app.router
app.use express.errorHandler()

app.get '/tail/:app/:worker?', (req, res) ->
	app = req.params.app
	worker = req.params.worker
	util.log "Tail request start"

	interval = setInterval () ->
		# Send some data for keeping socket alive
		res.write new Buffer [0x00]
	, 30000

	res.on 'close', () ->
		clearInterval interval

	connected = no
	client = new net.Socket()
	client.connect logstashUrl.port, logstashUrl.hostname, ->
		connected = yes

		filter =
			filter:
				gummi_app: app
				gummi_worker: worker
		client.write JSON.stringify filter

	client.on 'data', (data) ->
		try
			msg = JSON.parse data
			res.write format msg
		catch err
			util.log 'Invalid data: ' + data

	client.on 'end', ->
		res.end()

	client.on 'error', (err) ->
		util.log util.inspect err
		res.end()

	req.on 'close', ->
		util.log "Tail request close"
		client.end() if connected

	req.on 'error', (err) ->
		util.log util.inspect err
		client.end() if connected

app.get '/logs/:app/:worker?', (req, res, next) ->
	options =
		app: req.params.app
		worker: req.params.worker
		lines: req.query.n || 100

	logs options, (err, data) ->
		return next err if err
		result = data.map format
		res.end result.join('')

format = (msg) ->
	"#{msg['@timestamp']} #{msg['gummi_source'] || 'app'}[#{msg['gummi_worker']}]: #{msg['message']}\n"


server = app.listen config['port']
util.log "Server listening on #{config.port}"
